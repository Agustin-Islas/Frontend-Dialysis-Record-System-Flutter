import 'package:flutter/material.dart';
import 'package:frontend_dialysis_record/features/auth/models/me_response.dart';
import 'package:frontend_dialysis_record/features/auth/authController/auth_controller.dart';

class PatientHistoryScreen extends StatelessWidget {
  final MeResponse me;
  final AuthController authController;

  const PatientHistoryScreen({super.key, required this.me, required this.authController});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Text(
          'Historial (pendiente)\nPaciente: ${me.name ?? "-"}',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
