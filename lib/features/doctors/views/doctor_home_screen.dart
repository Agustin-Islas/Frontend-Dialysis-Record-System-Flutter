import 'package:flutter/material.dart';
import 'package:frontend_dialysis_record/features/auth/authController/auth_controller.dart';
import 'package:frontend_dialysis_record/features/auth/models/me_response.dart';
import 'package:frontend_dialysis_record/features/auth/views/login_screen.dart';
import 'package:frontend_dialysis_record/features/doctors/doctorController/doctor_controller.dart';
import 'package:frontend_dialysis_record/features/doctors/views/doctor_patients_screen.dart';
import 'package:frontend_dialysis_record/features/patients/patientController/patient_controller.dart';

class DoctorHomeScreen extends StatefulWidget {
  final MeResponse me;
  final AuthController authController;
  final DoctorController doctorController;
  final PatientController patientController;

  const DoctorHomeScreen({
    super.key,
    required this.me,
    required this.authController,
    required this.doctorController,
    required this.patientController,
  });

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DoctorPatientsScreen(
        doctorController: widget.doctorController,
        patientController: widget.patientController,
      ),
      _DoctorProfileScreen(me: widget.me, authController: widget.authController),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'Pacientes'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      ),
    );
  }
}

class _DoctorProfileScreen extends StatelessWidget {
  final MeResponse me;
  final AuthController authController;

  const _DoctorProfileScreen({required this.me, required this.authController});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Perfil médico', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${me.name ?? "-"} ${me.surname ?? ""}'.trim()),
                if (me.email != null) Text(me.email!),
                const SizedBox(height: 8),
                Text('Pacientes asociados: ${me.patientCount ?? me.patientIds.length}'),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              await authController.logout();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}
