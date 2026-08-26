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
import 'package:frontend_dialysis_record/features/invitations/providers/invitations_providers.dart';
import 'package:frontend_dialysis_record/features/patients/views/widgets/custom_concentrations_editor.dart';

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
  bool _isEditing = false;

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
      locale: const Locale('es', 'ES'),
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

  Future<void> _manageConcentrations() async {
    final result = await CustomConcentrationsEditor.show(
        context, _customConcentrations);
    if (result != null) {
      setState(() => _customConcentrations = result);
      if (!_isEditing) {
        // Si no estamos editando el perfil entero, guardamos automáticamente
        await _save();
      }
    }
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
      if (mounted) {
        AppSnackBar.success(context, 'Perfil actualizado');
        setState(() => _isEditing = false); // Exit edit mode
      }
    } catch (e) {
      final message = e is AppException
          ? e.message
          : 'No se pudo actualizar el perfil.';
      if (mounted) AppSnackBar.error(context, message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
    final scheme = Theme.of(context).colorScheme;

    if (me != null && !_loaded) {
      _load(me);
    }

    if (me == null) {
      return const AppSkeletonScreen(title: 'Perfil', itemCount: 3);
    }

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                // 1. Header Ficha
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: scheme.primaryContainer,
                        foregroundColor: scheme.primary,
                        child: const Icon(PhosphorIconsRegular.user, size: 40),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        '${me.name} ${me.surname}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: scheme.onSurface,
                            ),
                      ),
                      if (me.dni != null)
                        Text(
                          'DNI: ${me.dni}',
                          style: TextStyle(
                            fontSize: 14,
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                const _InvitationsCard(),
                const SizedBox(height: AppSpacing.md),

                // 2. Datos Personales
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Datos Personales',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: scheme.primary,
                                  ),
                            ),
                            if (!_isEditing)
                              TextButton.icon(
                                onPressed: () => setState(() {
                                  _load(me);
                                  _isEditing = true;
                                }),
                                icon: const Icon(PhosphorIconsRegular.pencilSimple, size: 18),
                                label: const Text('Editar'),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (!_isEditing) ...[
                          _ReadOnlyRow(label: 'Nombre', value: me.name ?? '-'),
                          const Divider(height: 1),
                          _ReadOnlyRow(label: 'Apellido', value: me.surname ?? '-'),
                          const Divider(height: 1),
                          _ReadOnlyRow(label: 'DNI', value: me.dni ?? '-'),
                          const Divider(height: 1),
                          _ReadOnlyRow(label: 'Nacimiento', value: _formatDate(_dateOfBirth)),
                          const Divider(height: 1),
                          _ReadOnlyRow(label: 'Domicilio', value: me.address ?? '-'),
                          const Divider(height: 1),
                          _ReadOnlyRow(label: 'Celular', value: me.number ?? '-'),
                        ] else ...[
                          // Formulario
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _nameCtrl,
                                  decoration: const InputDecoration(labelText: 'Nombre', prefixIcon: Icon(PhosphorIconsRegular.user)),
                                  validator: (v) => _required(v, 'Nombre'),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: TextFormField(
                                  controller: _surnameCtrl,
                                  decoration: const InputDecoration(labelText: 'Apellido', prefixIcon: Icon(PhosphorIconsRegular.user)),
                                  validator: (v) => _required(v, 'Apellido'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _dniCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'DNI', prefixIcon: Icon(PhosphorIconsRegular.identificationCard)),
                            validator: (v) => _requiredInt(v, 'DNI'),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          InkWell(
                            onTap: _saving ? null : _pickDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Nacimiento', prefixIcon: Icon(PhosphorIconsRegular.calendarBlank)),
                              child: Text(_formatDate(_dateOfBirth)),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _addressCtrl,
                            decoration: const InputDecoration(labelText: 'Domicilio', prefixIcon: Icon(PhosphorIconsRegular.house)),
                            validator: (v) => _required(v, 'Domicilio'),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _numberCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(labelText: 'Celular', prefixIcon: Icon(PhosphorIconsRegular.phone)),
                            validator: (v) => _requiredInt(v, 'Celular'),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: _saving
                                    ? null
                                    : () => setState(() {
                                          _load(me);
                                          _isEditing = false;
                                        }),
                                child: const Text('Cancelar'),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              FilledButton.icon(
                                onPressed: _saving ? null : _save,
                                icon: _saving
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(PhosphorIconsRegular.floppyDisk),
                                label: Text(_saving ? 'Guardando...' : 'Guardar perfil'),
                              ),
                            ],
                          ),
                        ],
                        if (!_isEditing) ...[
                          const SizedBox(height: AppSpacing.lg),
                          _ReadOnlyRow(
                            label: 'Email',
                            value: me.email ?? '-',
                            icon: PhosphorIconsRegular.envelope,
                          ),
                          const Divider(height: 1),
                          _ReadOnlyRow(
                            label: 'Médico',
                            value: me.doctorName ?? 'Sin médico asociado',
                            icon: PhosphorIconsRegular.stethoscope,
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: AppSpacing.md),

                // 3. Concentraciones
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Concentraciones',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: scheme.primary,
                                  ),
                            ),
                            IconButton(
                              onPressed: _manageConcentrations,
                              icon: const Icon(PhosphorIconsRegular.pencilSimple),
                              tooltip: 'Gestionar concentraciones',
                            )
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            _DotChip(label: 'Amarillo 1,5%', color: Colors.yellow.shade700),
                            _DotChip(label: 'Verde 2,4%', color: Colors.green.shade600),
                            _DotChip(label: 'Rojo 3,8%', color: Colors.red.shade600),
                            ..._customConcentrations.map(
                              (value) => _DotChip(
                                label: '${_formatConcentration(value)}%',
                                color: scheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // 4. Zona de Cuenta y Sesión
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Opciones de Cuenta',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                await ref.read(authStateProvider.notifier).logout(global: false);
                                if (!context.mounted) return;
                                context.go(AppRoutes.login);
                              },
                              icon: const Icon(PhosphorIconsRegular.signOut),
                              label: const Text('Cerrar sesión'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('¿Cerrar sesión global?'),
                                    content: const Text(
                                        'Esto cerrará tu sesión en todos los dispositivos donde hayas iniciado sesión. Deberás volver a ingresar tu contraseña en cada uno de ellos.\n\n¿Deseas continuar?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(ctx).pop(false),
                                        child: const Text('Cancelar'),
                                      ),
                                      FilledButton(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Theme.of(ctx).colorScheme.error,
                                          foregroundColor: Theme.of(ctx).colorScheme.onError,
                                        ),
                                        onPressed: () => Navigator.of(ctx).pop(true),
                                        child: const Text('Cerrar en todos lados'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await ref.read(authStateProvider.notifier).logout(global: true);
                                  if (!context.mounted) return;
                                  context.go(AppRoutes.login);
                                }
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: scheme.error,
                              ),
                              icon: const Icon(PhosphorIconsRegular.power),
                              label: const Text('Cerrar global'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
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
  final IconData? icon;

  const _ReadOnlyRow({required this.label, required this.value, this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: scheme.primary, size: 20),
            const SizedBox(width: AppSpacing.md),
          ],
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value, 
              style: TextStyle(
                fontSize: 14,
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DotChip extends StatelessWidget {
  final String label;
  final Color color;

  const _DotChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _InvitationsCard extends ConsumerWidget {
  const _InvitationsCard();

  Future<void> _handleAccept(BuildContext context, WidgetRef ref, String id) async {
    try {
      final ctrl = ref.read(invitationControllerProvider);
      await ctrl.acceptInvitation(id);
      if (!context.mounted) return;
      AppSnackBar.success(context, 'Médico asociado correctamente.');
      ref.invalidate(myPatientInvitationsProvider);
      ref.invalidate(authStateProvider); // Reload profile (doctorName, etc)
    } catch (e) {
      if (!context.mounted) return;
      AppSnackBar.showException(context, e, 'No se pudo aceptar la invitación.');
    }
  }

  Future<void> _handleReject(BuildContext context, WidgetRef ref, String id) async {
    try {
      final ctrl = ref.read(invitationControllerProvider);
      await ctrl.rejectInvitation(id);
      if (!context.mounted) return;
      AppSnackBar.success(context, 'Invitación rechazada.');
      ref.invalidate(myPatientInvitationsProvider);
    } catch (e) {
      if (!context.mounted) return;
      AppSnackBar.showException(context, e, 'No se pudo rechazar la invitación.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invAsync = ref.watch(myPatientInvitationsProvider);

    return invAsync.when(
      data: (invitations) {
        final pending = invitations.where((i) => i.status == 'PENDING').toList();
        if (pending.isEmpty) return const SizedBox.shrink();

        return Card(
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(PhosphorIconsFill.bellRinging, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Invitaciones pendientes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                ...pending.map((inv) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Solicitud de vinculación de médico:'),
                                Text(
                                  inv.doctorName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => _handleReject(context, ref, inv.id),
                            child: const Text('Rechazar'),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          FilledButton(
                            onPressed: () => _handleAccept(context, ref, inv.id),
                            child: const Text('Aceptar'),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }
}
