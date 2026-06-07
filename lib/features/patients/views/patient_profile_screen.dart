import 'package:flutter/material.dart';
import 'package:frontend_dialysis_record/core/network/app_exception.dart';
import 'package:frontend_dialysis_record/features/auth/authController/auth_controller.dart';
import 'package:frontend_dialysis_record/features/auth/models/me_response.dart';
import 'package:frontend_dialysis_record/features/auth/views/login_screen.dart';
import 'package:frontend_dialysis_record/features/patients/patientController/patient_controller.dart';

class PatientProfileScreen extends StatefulWidget {
  final MeResponse me;
  final AuthController authController;
  final PatientController patientController;
  final ValueChanged<MeResponse> onUpdated;

  const PatientProfileScreen({
    super.key,
    required this.me,
    required this.authController,
    required this.patientController,
    required this.onUpdated,
  });

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
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

  static const _fixedConcentrations = [1.5, 2.4, 3.8];

  @override
  void initState() {
    super.initState();
    _load(widget.me);
  }

  @override
  void didUpdateWidget(covariant PatientProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.me != widget.me) _load(widget.me);
  }

  void _load(MeResponse me) {
    _nameCtrl.text = me.name ?? '';
    _surnameCtrl.text = me.surname ?? '';
    _dniCtrl.text = me.dni ?? '';
    _addressCtrl.text = me.address ?? '';
    _numberCtrl.text = me.number ?? '';
    _dateOfBirth = DateTime.tryParse(me.dateOfBirth ?? '') ?? DateTime(1990);
    _customConcentrations = [...me.customConcentrations]..sort();
  }

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
      _showMessage('Ingresa una concentracion valida.');
      return;
    }
    final rounded = double.parse(value.toStringAsFixed(1));
    if (rounded < 0.1 ||
        rounded > 10.0 ||
        ((value * 10) - (value * 10).round()).abs() > 0.0001) {
      _showMessage(
        'La concentracion debe tener un decimal y estar entre 0.1 y 10.0.',
      );
      return;
    }
    if (_contains(_fixedConcentrations, rounded) ||
        _contains(_customConcentrations, rounded)) {
      _showMessage('Esa concentracion ya existe.');
      return;
    }
    setState(() {
      _customConcentrations = [..._customConcentrations, rounded]..sort();
      _customConcentrationCtrl.clear();
    });
  }

  Future<void> _save() async {
    final id = widget.me.id;
    if (id == null || !_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await widget.patientController.updatePatient(
        patientId: id,
        name: _nameCtrl.text.trim(),
        surname: _surnameCtrl.text.trim(),
        dni: int.parse(_dniCtrl.text.trim()),
        dateOfBirth: _dateOfBirth,
        address: _addressCtrl.text.trim(),
        number: int.parse(_numberCtrl.text.trim()),
        customConcentrations: _customConcentrations,
      );
      final refreshed = await widget.authController.getMe();
      if (refreshed != null) widget.onUpdated(refreshed);
      _showMessage('Perfil actualizado');
    } catch (e) {
      final message = e is AppException
          ? e.message
          : 'No se pudo actualizar el perfil.';
      _showMessage(message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool _contains(List<double> values, double target) {
    return values.any((value) => (value - target).abs() < 0.0001);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
    if (parsed == null || parsed <= 0) return '$label invalido';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Perfil',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Datos personales',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _nameCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Nombre',
                                ),
                                validator: (v) => _required(v, 'Nombre'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _surnameCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Apellido',
                                ),
                                validator: (v) => _required(v, 'Apellido'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _dniCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'DNI'),
                          validator: (v) => _requiredInt(v, 'DNI'),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: _saving ? null : _pickDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Nacimiento',
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(_formatDate(_dateOfBirth)),
                                ),
                                const Icon(Icons.calendar_today_outlined),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _addressCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Domicilio',
                          ),
                          validator: (v) => _required(v, 'Domicilio'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _numberCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Celular',
                          ),
                          validator: (v) => _requiredInt(v, 'Celular'),
                        ),
                        const SizedBox(height: 16),
                        _ReadOnlyRow(
                          label: 'Email',
                          value: widget.me.email ?? '-',
                        ),
                        _ReadOnlyRow(
                          label: 'Medico',
                          value: widget.me.doctorName ?? 'Sin medico asociado',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Concentraciones',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
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
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _customConcentrationCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: const InputDecoration(
                                  labelText: 'Nueva concentracion',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: _addCustomConcentration,
                              icon: const Icon(Icons.add),
                              label: const Text('Agregar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          await widget.authController.logout();
                          if (!context.mounted) return;
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                            (_) => false,
                          );
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('Cerrar sesion'),
                      ),
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          _saving ? 'Guardando...' : 'Guardar perfil',
                        ),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
