import 'package:flutter/material.dart';
import 'package:frontend_dialysis_record/features/auth/models/me_response.dart';
import 'package:frontend_dialysis_record/features/auth/authController/auth_controller.dart';

class PatientTodayScreen extends StatelessWidget {
  final MeResponse me;
  final AuthController authController;

  const PatientTodayScreen({
    super.key,
    required this.me,
    required this.authController,
  });

  @override
  Widget build(BuildContext context) {
    // Placeholder: después acá armamos la UI real tipo “cards” como tu imagen.
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Hoy',
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
                    '✅ Login OK (placeholder)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text('Paciente: ${me.name ?? "-"} ${me.surname ?? ""}'.trim()),
                  if (me.id != null) Text('Patient ID: ${me.id}'),
                  if (me.email != null) Text('Email: ${me.email}'),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Dejo otra card vacía como guía visual para el “panel del día”
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Acá va el resumen del día (intercambios, drenaje, infusión, balance, estado).\n'
                'Luego debajo van las cards por horario.',
              ),
            ),
          ),

          const SizedBox(height: 100), // para que no tape el FAB
        ],
      ),
    );
  }
}
