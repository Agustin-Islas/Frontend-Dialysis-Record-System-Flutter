import 'package:flutter/material.dart';
import 'package:frontend_dialysis_record/core/di/app_di.dart';
import 'package:frontend_dialysis_record/core/network/app_exception.dart';
import 'package:frontend_dialysis_record/features/auth/views/session_gate.dart';
import 'package:frontend_dialysis_record/features/patients/views/patient_register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(value);
  }

  Future<void> login() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    FocusScope.of(context).unfocus();
    setState(() => isLoading = true);

    try {
      final me = await AppDI.authController.login(
        emailController.text.trim(),
        passwordController.text,
      );

      if (!mounted) return;
      setState(() => isLoading = false);

      if (me == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo iniciar sesión.')),
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SessionGate()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      final message = e is AppException ? e.message : 'Error al iniciar sesión.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void registerPatient() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PatientRegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        final v = (value ?? '').trim();
                        if (v.isEmpty) return 'Email requerido';
                        if (!_isValidEmail(v)) return 'Email inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      onFieldSubmitted: (_) => isLoading ? null : login(),
                      validator: (value) {
                        final v = value ?? '';
                        if (v.trim().isEmpty) return 'Password requerido';
                        if (v.length < 8) return 'Debe tener al menos 8 caracteres';
                        if (v.length > 72) return 'Máximo 72 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    if (isLoading)
                      const CircularProgressIndicator()
                    else ...[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: login,
                          child: const Text('Iniciar sesión'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: registerPatient,
                          child: const Text('Registrarse'),
                        ),
                      ),
                    ],
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
