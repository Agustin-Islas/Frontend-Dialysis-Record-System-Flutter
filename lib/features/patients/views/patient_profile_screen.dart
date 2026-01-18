import 'package:flutter/material.dart';
import 'package:frontend_dialysis_record/features/auth/models/me_response.dart';
import 'package:frontend_dialysis_record/features/auth/views/login_screen.dart';
import 'package:frontend_dialysis_record/features/auth/authController/auth_controller.dart';

class PatientProfileScreen extends StatelessWidget {
  final MeResponse me;
  final AuthController authController;

  const PatientProfileScreen({super.key, required this.me, required this.authController});

  @override
  Widget build(BuildContext context) {
    return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              me.name != null ? 'Resumen de ${me.name}' : 'Resumen',
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
                      '✅ Mi perfil',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              authController.logout();
                              if (!context.mounted) return;
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => LoginScreen()),
                                );
                            },
                            child: const Text('Cerrar sesión'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
        ],);
  }
}
