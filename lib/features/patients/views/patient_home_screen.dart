import 'package:flutter/material.dart';
import 'package:frontend_dialysis_record/features/auth/models/me_response.dart';
import 'package:frontend_dialysis_record/features/auth/authController/auth_controller.dart';
import 'package:frontend_dialysis_record/features/patients/views/patient_today_screen.dart';
import 'package:frontend_dialysis_record/features/patients/views/patient_history_screen.dart';
import 'package:frontend_dialysis_record/features/patients/views/patient_profile_screen.dart';

class PatientHomeScreen extends StatefulWidget {
  final MeResponse me;
  final AuthController authController;

  const PatientHomeScreen({
    super.key,
    required this.me,
    required this.authController,
  });

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _currentIndex = 0;

  void _goTo(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  void _onNewRecord() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nuevo registro (pendiente de implementar)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      PatientTodayScreen(me: widget.me, authController: widget.authController),
      PatientHistoryScreen(me: widget.me, authController: widget.authController),
      PatientProfileScreen(me: widget.me, authController: widget.authController),
    ];

    return Scaffold(
      extendBody: true,

      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _onNewRecord,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      bottomNavigationBar: _PatientBottomBar(
        currentIndex: _currentIndex,
        onTap: _goTo,
      ),
    );
  }
}

/// Barra inferior custom con espacio al medio para el FAB.
class _PatientBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _PatientBottomBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget item({
      required int index,
      required IconData icon,
      required String label,
    }) {
      final selected = currentIndex == index;
      final color = selected
          ? theme.colorScheme.primary
          : theme.textTheme.bodyMedium?.color?.withOpacity(0.7);

      return Expanded(
        child: InkWell(
          onTap: () => onTap(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    height: 1.0,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 76, // <- más alto para evitar overflow (web/desktop)
        child: Row(
          children: [
            item(index: 0, icon: Icons.home_rounded, label: 'Hoy'),
            item(index: 1, icon: Icons.view_agenda_rounded, label: 'Historial'),

            // Espacio para el FAB al centro
            const SizedBox(width: 72),

            item(index: 2, icon: Icons.bar_chart_rounded, label: 'Resumen'),
          ],
        ),
      ),
    );
  }
}