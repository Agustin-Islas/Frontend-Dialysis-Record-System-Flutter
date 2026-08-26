import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend_dialysis_record/core/design/design.dart';

import 'package:frontend_dialysis_record/core/router/app_router.dart';
import 'package:frontend_dialysis_record/core/widgets/widgets.dart';

class PatientRegisterScreen extends ConsumerStatefulWidget {
  const PatientRegisterScreen({super.key});

  @override
  ConsumerState<PatientRegisterScreen> createState() =>
      _PatientRegisterScreenState();
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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        data: {
          'name': _nameCtrl.text.trim(),
          'surname': _surnameCtrl.text.trim(),
          'dni': int.parse(_dniCtrl.text.trim()),
          'dateOfBirth': _dateOfBirth.toIso8601String().split('T').first,
          'address': _addressCtrl.text.trim(),
          'number': int.parse(_numberCtrl.text.trim()),
          'role': 'PATIENT',
        },
      );

      if (!mounted) return;

      if (res.session == null) {
        AppSnackBar.success(
          context,
          'Registro exitoso. Revisa tu correo (o la carpeta Spam) e ingresa el código.',
        );
        context.go('/verify-otp', extra: {'email': _emailCtrl.text.trim()});
      } else {
        AppSnackBar.success(context, 'Registro exitoso. Iniciando sesión...');
        context.go(AppRoutes.login);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showException(
          context,
          e,
          'No se pudo completar el registro.',
        );
      }
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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Card(
                  elevation: 0,
                  color: scheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
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
                                  decoration: const InputDecoration(
                                    labelText: 'Nombre',
                                  ),
                                  validator: (v) => _required(v, 'Nombre'),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
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
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(PhosphorIconsRegular.envelope),
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
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
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
                              decoration: const InputDecoration(
                                labelText: 'Fecha de nacimiento',
                              ),
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
                            decoration: const InputDecoration(
                              labelText: 'Domicilio',
                            ),
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
                          SizedBox(
                            height: 54,
                            child: FilledButton.icon(
                              onPressed: _loading ? null : _register,
                              icon: _loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(PhosphorIconsRegular.userPlus),
                              label: Text(_loading ? 'Registrando...' : 'Registrar'),
                            ),
                          ),
                        ],
                      ),
                    ),
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
