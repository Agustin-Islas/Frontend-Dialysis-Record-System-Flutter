import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:frontend_dialysis_record/core/design/design.dart';
import 'package:frontend_dialysis_record/core/providers/providers.dart';
import 'package:frontend_dialysis_record/core/router/app_router.dart';
import 'package:frontend_dialysis_record/core/widgets/widgets.dart';
import 'package:frontend_dialysis_record/core/network/app_exception.dart';
import 'package:frontend_dialysis_record/features/auth/providers/auth_providers.dart';
import 'package:frontend_dialysis_record/features/auth/models/me_response.dart';

class PatientProfileScreen extends ConsumerStatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  ConsumerState<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends ConsumerState<PatientProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _surnameCtrl = TextEditingController();
  final _dniCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _customConcentrationCtrl = TextEditingController();

  late DateTime _dateOfBirth;
  late List<double> _customConcentrations;
  bool _saving = false;
  bool _loaded = false;

  static const _fixedConcentrations = [1.5, 2.4, 3.8];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _surnameCtrl.dispose();
    _dniCtrl.dispose();
    _addressCtrl.dispose();
    _numberCtrl.dispose();
    _customConcentrationCtrl.dispose();
    super.dispose();
  }

  void _load(MeResponse me) {
    _nameCtrl.text = me.name ?? '';
    _surnameCtrl.text = me.surname ?? '';
    _dniCtrl.text = me.dni ?? '';
    _addressCtrl.text = me.address ?? '';
    _numberCtrl.text = me.number ?? '';
    _dateOfBirth = DateTime.tryParse(me.dateOfBirth ?? '') ?? DateTime(1990);
    _customConcentrations = [...me.customConcentrations]..sort();
    _loaded = true;
  }

  Future<void> _pickDate() async {
    final now = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth.isAfter(now)
          ? DateTime(now.year - 18)
          : _dateOfBirth,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _dateOfBirth = DateUtils.dateOnly(picked));
    }
  }

  void _addCustomConcentration() {
    final raw = _customConcentrationCtrl.text.trim().replaceAll(',', '.');
    final value = double.tryParse(raw);
    if (value == null) {
      AppSnackBar.warning(context, 'Ingresá una concentración válida.');
      return;
    }
    final rounded = double.parse(value.toStringAsFixed(1));
    if (rounded < 0.1 || rounded > 10.0 ||
        ((value * 10) - (value * 10).round()).abs() > 0.0001) {
      AppSnackBar.warning(
        context,
        'La concentración debe tener un decimal y estar entre 0.1 y 10.0.',
      );
      return;
    }
    if (_contains(_fixedConcentrations, rounded) ||
        _contains(_customConcentrations, rounded)) {
      AppSnackBar.info(context, 'Esa concentración ya existe.');
      return;
    }
    setState(() {
      _customConcentrations = [..._customConcentrations, rounded]..sort();
      _customConcentrationCtrl.clear();
    });
  }

  Future<void> _save() async {
    final me = ref.read(authStateProvider).valueOrNull;
    final id = me?.id;
    if (id == null || !_formKey.currentState!.validate()) return;

    final patientCtrl = ref.read(patientControllerProvider);

    setState(() => _saving = true);
    try {
      await patientCtrl.updatePatient(
        patientId: id,
        name: _nameCtrl.text.trim(),
        surname: _surnameCtrl.text.trim(),
        dni: int.parse(_dniCtrl.text.trim()),
        dateOfBirth: _dateOfBirth,
        address: _addressCtrl.text.trim(),
        number: int.parse(_numberCtrl.text.trim()),
        customConcentrations: _customConcentrations,
      );
      await ref.read(authStateProvider.notifier).refresh();
      if (mounted) AppSnackBar.success(context, 'Perfil actualizado');
    } catch (e) {
      final message = e is AppException
          ? e.message
          : 'No se pudo actualizar el perfil.';
      if (mounted) AppSnackBar.error(context, message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool _contains(List<double> values, double target) {
    return values.any((v) => (v - target).abs() < 0.0001);
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  String _formatConcentration(double value) {
    return value.toStringAsFixed(1).replaceAll('.', ',');
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label requerido';
    return null;
  }

  String? _requiredInt(String? value, String label) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '$label requerido';
    final parsed = int.tryParse(text);
    if (parsed == null || parsed <= 0) return '$label inválido';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final me = authState.valueOrNull;

    if (me != null && !_loaded) {
      _load(me);
    }

    if (me == null) {
      return const AppSkeletonScreen(title: 'Perfil', itemCount: 3);
    }

    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text(
                  'Perfil',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.md),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Datos personales',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _nameCtrl,
                                decoration: const InputDecoration(labelText: 'Nombre'),
                                validator: (v) => _required(v, 'Nombre'),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: TextFormField(
                                controller: _surnameCtrl,
                                decoration: const InputDecoration(labelText: 'Apellido'),
                                validator: (v) => _required(v, 'Apellido'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _dniCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'DNI'),
                          validator: (v) => _requiredInt(v, 'DNI'),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        InkWell(
                          onTap: _saving ? null : _pickDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Nacimiento'),
                            child: Row(
                              children: [
                                Expanded(child: Text(_formatDate(_dateOfBirth))),
                                const Icon(PhosphorIconsRegular.calendarBlank),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _addressCtrl,
                          decoration: const InputDecoration(labelText: 'Domicilio'),
                          validator: (v) => _required(v, 'Domicilio'),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _numberCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Celular'),
                          validator: (v) => _requiredInt(v, 'Celular'),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _ReadOnlyRow(label: 'Email', value: me.email ?? '-'),
                        _ReadOnlyRow(
                          label: 'Médico',
                          value: me.doctorName ?? 'Sin médico asociado',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Concentraciones',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            const Chip(label: Text('Amarillo 1,5%')),
                            const Chip(label: Text('Verde 2,4%')),
                            const Chip(label: Text('Rojo 3,8%')),
                            ..._customConcentrations.map(
                              (value) => InputChip(
                                label: Text('${_formatConcentration(value)}%'),
                                onDeleted: () => setState(
                                  () => _customConcentrations.remove(value),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _customConcentrationCtrl,
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Nueva concentración',
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            FilledButton.icon(
                              onPressed: _addCustomConcentration,
                              icon: const Icon(PhosphorIconsRegular.plus),
                              label: const Text('Agregar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    alignment: WrapAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          await ref.read(authStateProvider.notifier).logout();
                          if (!context.mounted) return;
                          context.go(AppRoutes.login);
                        },
                        icon: const Icon(PhosphorIconsRegular.signOut),
                        label: const Text('Cerrar sesión'),
                      ),
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(PhosphorIconsRegular.floppyDisk),
                        label: Text(_saving ? 'Guardando...' : 'Guardar perfil'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
