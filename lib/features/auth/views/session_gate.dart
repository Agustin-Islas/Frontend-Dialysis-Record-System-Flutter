import 'package:flutter/material.dart';
import 'package:frontend_dialysis_record/core/di/app_di.dart';
import 'package:frontend_dialysis_record/features/auth/models/me_response.dart';
import 'package:frontend_dialysis_record/features/auth/views/login_screen.dart';
import 'package:frontend_dialysis_record/features/doctors/views/doctor_home_screen.dart';
import 'package:frontend_dialysis_record/features/patients/views/patient_home_screen.dart';

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late Future<MeResponse?> _future;

  @override
  void initState() {
    super.initState();
    _future = AppDI.authController.getMe();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MeResponse?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final me = snapshot.data;
        if (snapshot.hasError || me == null) {
          return const LoginScreen();
        }

        if (me.role == 'DOCTOR') {
          return DoctorHomeScreen(
            me: me,
            authController: AppDI.authController,
            doctorController: AppDI.doctorController,
            patientController: AppDI.patientController,
          );
        }

        if (me.role == 'PATIENT') {
          return PatientHomeScreen(
            me: me,
            authController: AppDI.authController,
            patientController: AppDI.patientController,
          );
        }

        return const LoginScreen();
      },
    );
  }
}
