import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:frontend_dialysis_record/core/design/design.dart';
import 'package:frontend_dialysis_record/core/providers/providers.dart';
import 'package:frontend_dialysis_record/core/router/app_router.dart';
import 'package:frontend_dialysis_record/core/widgets/widgets.dart';
import 'package:frontend_dialysis_record/core/network/app_exception.dart';

class PatientRegisterScreen extends ConsumerStatefulWidget {
  const PatientRegisterScreen({super.key});

  @override
  ConsumerState<PatientRegisterScreen> createState() => _PatientRegisterScreenState();
}

class _PatientRegisterScreenState extends ConsumerState<PatientRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _surnameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _dniCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();

  bool _obscurePassword = true;
  DateTime _dateOfBirth = DateTime(1990);
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _surnameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _dniCtrl.dispose();
    _addressCtrl.dispose();
    _numberCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth.isAfter(now) ? DateTime(now.year - 18) : _dateOfBirth,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) setState(() => _dateOfBirth = DateUtils.dateOnly(picked));
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    try {
      final authCtrl = ref.read(authControllerProvider);
      await authCtrl.registerPatient(
        name: _nameCtrl.text.trim(),
        surname: _surnameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        dateOfBirth: _dateOfBirth.toIso8601String().split('T').first,
        dni: int.parse(_dniCtrl.text.trim()),
        address: _addressCtrl.text.trim(),
        number: int.parse(_numberCtrl.text.trim()),
      );
      if (!mounted) return;
      AppSnackBar.success(context, 'Registro exitoso. Ya podés iniciar sesión.');
      context.go(AppRoutes.login);
    } catch (e) {
      final message = e is AppException ? e.message : 'No se pudo completar el registro.';
      if (mounted) AppSnackBar.error(context, message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day/$month/${d.year}';
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label requerido';
    return null;
  }

  String? _requiredInt(String? value, String label) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '$label requerido';
    if (int.tryParse(text) == null) return '$label inválido';
    return null;
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar paciente'),
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft),
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(PhosphorIconsRegular.envelope),
                        ),
                        validator: (v) {
                          final t = (v ?? '').trim();
                          if (t.isEmpty) return 'Email requerido';
                          if (!_isValidEmail(t)) return 'Email inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(PhosphorIconsRegular.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? PhosphorIconsRegular.eye
                                  : PhosphorIconsRegular.eyeSlash,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) {
                          if ((v ?? '').isEmpty) return 'Contraseña requerida';
                          if (v!.length < 8) return 'Mínimo 8 caracteres';
                          return null;
                        },
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
                        onTap: _loading ? null : _pickDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Fecha de nacimiento'),
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
                      const SizedBox(height: AppSpacing.xl),
                      FilledButton.icon(
                        onPressed: _loading ? null : _register,
                        icon: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(PhosphorIconsRegular.userPlus),
                        label: Text(_loading ? 'Registrando...' : 'Registrar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
