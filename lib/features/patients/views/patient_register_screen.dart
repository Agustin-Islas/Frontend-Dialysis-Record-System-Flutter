import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend_dialysis_record/core/auth/token_storage.dart';
import 'package:frontend_dialysis_record/core/network/dio_client.dart';
import 'package:frontend_dialysis_record/features/auth/authController/auth_controller.dart';
import 'package:frontend_dialysis_record/features/auth/views/login_screen.dart';

class PatientRegisterScreen extends StatefulWidget {
  const PatientRegisterScreen({super.key});

  @override
  State<PatientRegisterScreen> createState() => _PatientRegisterScreenState();
}

class _PatientRegisterScreenState extends State<PatientRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateFormat = DateFormat('yyyy-MM-dd');

  late final AuthController authController = AuthController(DioClient(), TokenStorage());

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final surnameController = TextEditingController();
  final dniController = TextEditingController();
  final dateOfBirthController = TextEditingController();
  final addressController = TextEditingController();
  final numberController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    surnameController.dispose();
    dniController.dispose();
    dateOfBirthController.dispose();
    addressController.dispose();
    numberController.dispose();
    super.dispose();
  }

  // --- Helpers de validación ---
  bool _isValidEmail(String value) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(value);
  }

  String? _required(String? value, {String message = 'Campo requerido'}) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return message;
    return null;
  }

  String? _validatePassword(String? value) {
    final v = value ?? '';
    if (v.trim().isEmpty) return 'Password requerido';
    if (v.length < 8) return 'Debe tener al menos 8 caracteres';
    if (v.length > 72) return 'Máximo 72 caracteres';
    return null;
  }

  String? _validateName(String? value, {required String label}) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return '$label requerido';
    if (v.length < 2) return '$label demasiado corto';
    if (v.length > 60) return '$label demasiado largo';
    return null;
  }

  String? _validateDni(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'DNI requerido';
    final dni = int.tryParse(v);
    if (dni == null) return 'DNI inválido (solo números)';
    // Rango razonable (ajustalo si querés)
    if (dni < 1000000 || dni > 99999999) return 'DNI fuera de rango';
    return null;
  }

  String? _validatNumber(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Número requerido';
    final n = int.tryParse(v);
    if (n == null) return 'Número inválido (solo números)';
    if (n <= 0 || n > 9999999999) return 'Número fuera de rango';
    return null;
  }

  String? _validateDate(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Fecha de nacimiento requerida';
    try {
      final parsed = DateTime.parse(v); // espera yyyy-MM-dd
      final now = DateTime.now();
      if (parsed.isAfter(now)) return 'La fecha no puede ser futura';
      // ejemplo: al menos 0 años, y no más de 120
      final age = now.year - parsed.year - ((now.month < parsed.month || (now.month == parsed.month && now.day < parsed.day)) ? 1 : 0);
      if (age > 120) return 'Fecha inválida';
    } catch (_) {
      return 'Formato inválido (YYYY-MM-DD)';
    }
    return null;
  }

  Future<void> _pickDateOfBirth() async {
    FocusScope.of(context).unfocus();

    DateTime initial = DateTime(2000, 1, 1);
    try {
      final current = dateOfBirthController.text.trim();
      if (current.isNotEmpty) initial = DateTime.parse(current);
    } catch (_) {}

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime.now(),
      helpText: 'Seleccionar fecha de nacimiento',
    );

    if (picked != null) {
      dateOfBirthController.text = _dateFormat.format(picked);
      // fuerza revalidación visual si ya interactuó
      _formKey.currentState?.validate();
    }
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() => isLoading = true);

    try {
      await authController.registerPatient(
        email: emailController.text.trim(),
        password: passwordController.text,
        name: nameController.text.trim(),
        surname: surnameController.text.trim(),
        dni: int.parse(dniController.text.trim()),
        dateOfBirth: dateOfBirthController.text.trim(), // yyyy-MM-dd
        address: addressController.text.trim(),
        number: int.parse(numberController.text.trim()),
      );

      if (!mounted) return;
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro exitoso. Iniciá sesión.')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo registrar: $e')),
      );
    }
  }

  InputDecoration _dec(String label, {String? hint, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon) : null,
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de paciente')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Completá tus datos',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                // --- Cuenta ---
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: _dec('Email', icon: Icons.email_outlined),
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
                  textInputAction: TextInputAction.next,
                  decoration: _dec('Password', hint: 'Mínimo 8 caracteres', icon: Icons.lock_outline),
                  validator: _validatePassword,
                ),

                const SizedBox(height: 20),
                Text(
                  'Datos personales',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: nameController,
                        textInputAction: TextInputAction.next,
                        decoration: _dec('Nombre', icon: Icons.person_outline),
                        validator: (v) => _validateName(v, label: 'Nombre'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: surnameController,
                        textInputAction: TextInputAction.next,
                        decoration: _dec('Apellido', icon: Icons.person_outline),
                        validator: (v) => _validateName(v, label: 'Apellido'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: dniController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        decoration: _dec('DNI', icon: Icons.badge_outlined),
                        validator: _validateDni,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: dateOfBirthController,
                        readOnly: true,
                        decoration: _dec('Fecha de nacimiento', hint: 'YYYY-MM-DD', icon: Icons.calendar_month_outlined).copyWith(
                          suffixIcon: IconButton(
                            onPressed: _pickDateOfBirth,
                            icon: const Icon(Icons.date_range),
                            tooltip: 'Elegir fecha',
                          ),
                        ),
                        onTap: _pickDateOfBirth,
                        validator: _validateDate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                      controller: addressController,
                      textInputAction: TextInputAction.next,
                      decoration: _dec('Domicilio', icon: Icons.location_on_outlined),
                      validator: (v) => _required(v, message: 'Domicilio requerido'),
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                      controller: numberController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      decoration: _dec('Número de celular', icon: Icons.numbers_outlined),
                      validator: _validatNumber,
                      onFieldSubmitted: (_) => isLoading ? null : _submit(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                SizedBox(
                  height: 48,
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                          onPressed: _submit,
                          icon: const Icon(Icons.check),
                          label: const Text('Crear cuenta'),
                        ),
                ),
                const SizedBox(height: 12),

                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                  child: const Text('Ya tengo cuenta → Iniciar sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
