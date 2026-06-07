import 'package:flutter/material.dart';
import 'package:frontend_dialysis_record/core/di/app_di.dart';
import 'package:frontend_dialysis_record/core/network/app_exception.dart';
import 'package:frontend_dialysis_record/features/auth/views/login_screen.dart';

class DoctorRegisterScreen extends StatefulWidget {
  const DoctorRegisterScreen({super.key});

  @override
  State<DoctorRegisterScreen> createState() => _DoctorRegisterScreenState();
}

class _DoctorRegisterScreenState extends State<DoctorRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final surnameController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    surnameController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(value);
  }

  String? _validateName(String? value, {required String label}) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return '$label requerido';
    if (v.length < 2) return '$label demasiado corto';
    if (v.length > 60) return '$label demasiado largo';
    return null;
  }

  String? _validatePassword(String? value) {
    final v = value ?? '';
    if (v.trim().isEmpty) return 'Password requerido';
    if (v.length < 8) return 'Debe tener al menos 8 caracteres';
    if (v.length > 72) return 'Maximo 72 caracteres';
    return null;
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    FocusScope.of(context).unfocus();
    setState(() => isLoading = true);

    try {
      await AppDI.authController.registerDoctor(
        email: emailController.text.trim(),
        password: passwordController.text,
        name: nameController.text.trim(),
        surname: surnameController.text.trim(),
      );

      if (!mounted) return;
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registro medico exitoso. Inicia sesion.'),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      final message = e is AppException
          ? e.message
          : 'No se pudo registrar el medico.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  InputDecoration _dec(String label, {IconData? icon, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de medico')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Crea tu cuenta medica',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: _dec('Email', icon: Icons.email_outlined),
                      validator: (value) {
                        final v = (value ?? '').trim();
                        if (v.isEmpty) return 'Email requerido';
                        if (!_isValidEmail(v)) return 'Email invalido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      decoration: _dec(
                        'Password',
                        hint: 'Minimo 8 caracteres',
                        icon: Icons.lock_outline,
                      ),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _ResponsiveField(
                          child: TextFormField(
                            controller: nameController,
                            textInputAction: TextInputAction.next,
                            decoration: _dec(
                              'Nombre',
                              icon: Icons.person_outline,
                            ),
                            validator: (v) => _validateName(v, label: 'Nombre'),
                          ),
                        ),
                        _ResponsiveField(
                          child: TextFormField(
                            controller: surnameController,
                            textInputAction: TextInputAction.done,
                            decoration: _dec(
                              'Apellido',
                              icon: Icons.person_outline,
                            ),
                            validator: (v) =>
                                _validateName(v, label: 'Apellido'),
                            onFieldSubmitted: (_) =>
                                isLoading ? null : _submit(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        height: 48,
                        width: 220,
                        child: isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : FilledButton.icon(
                                onPressed: _submit,
                                icon: const Icon(Icons.check),
                                label: const Text('Crear cuenta'),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            },
                      child: const Text('Ya tengo cuenta - Iniciar sesion'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResponsiveField extends StatelessWidget {
  final Widget child;

  const _ResponsiveField({required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width < 680 ? double.infinity : 270,
      child: child,
    );
  }
}
