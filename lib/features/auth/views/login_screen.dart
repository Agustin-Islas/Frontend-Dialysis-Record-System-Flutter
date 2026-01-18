import 'package:flutter/material.dart';
import 'package:frontend_dialysis_record/features/patients/views/patient_home_screen.dart';
import 'package:frontend_dialysis_record/features/patients/views/patient_register_screen.dart';
import 'package:frontend_dialysis_record/core/network/dio_client.dart';
import 'package:frontend_dialysis_record/core/auth/token_storage.dart';
import 'package:frontend_dialysis_record/features/auth/authController/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final authController = AuthController(DioClient(), TokenStorage());
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool _checkingSession = true; // <- para evitar mostrar el form mientras chequea

  @override
  void initState() {
    super.initState();
    _restoreSessionIfPossible();
  }

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

  Future<void> _restoreSessionIfPossible() async {
    setState(() {
      _checkingSession = true;
      isLoading = true;
    });

    try {
      // 1) si no hay token, no hay sesión
      final token = await authController.tokenStorage.readAccessToken();
      if (token == null || token.trim().isEmpty) {
        if (!mounted) return;
        setState(() {
          _checkingSession = false;
          isLoading = false;
        });
        return;
      }

      // 2) hay token: intentar traer /me (si el token está vencido va a fallar)
      final meResponse = await authController.getMe();

      if (!mounted) return;

      // Si por algún motivo devuelve null, caemos al login
      if (meResponse == null) {
        await authController.logout(); // limpia tokens
        setState(() {
          _checkingSession = false;
          isLoading = false;
        });
        return;
      }

      // 3) navegar directo según rol
      if (meResponse.role == 'PATIENT') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PatientHomeScreen(me: meResponse, authController: authController),
          ),
        );
        return;
      }

      if (meResponse.role == 'DOCTOR') {
        // TODO: DoctorHomeScreen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesión DOCTOR detectada (home pendiente)')),
        );
      }

      setState(() {
        _checkingSession = false;
        isLoading = false;
      });
    } catch (_) {
      // token inválido / expiró / error de red → mostramos login normal
      await authController.logout(); // limpia tokens para que no quede “pegado”
      if (!mounted) return;
      setState(() {
        _checkingSession = false;
        isLoading = false;
      });
    }
  }

  Future<void> login() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    FocusScope.of(context).unfocus();

    setState(() => isLoading = true);
    try {
      final meResponse = await authController.login(
        emailController.text.trim(),
        passwordController.text,
      );

      if (!mounted) return;
      setState(() => isLoading = false);

      if (meResponse == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credenciales inválidas o error de conexión')),
        );
        return;
      }

      if (meResponse.role == 'PATIENT') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PatientHomeScreen(me: meResponse, authController: authController),
          ),
        );
      } else if (meResponse.role == 'DOCTOR') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login DOCTOR OK (pendiente de implementar home)')),
        );
      } else {
        debugPrint(meResponse.role);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rol desconocido: ${meResponse.role}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar sesión: $e')),
      );
    }
  }

  void registerPatient() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PatientRegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // mientras chequea sesión, mostramos loader a pantalla completa
    if (_checkingSession) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Email'),
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
                decoration: const InputDecoration(labelText: 'Password'),
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
              if (isLoading) const CircularProgressIndicator() else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: login,
                    child: const Text('Iniciar Sesión'),
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
    );
  }
}
