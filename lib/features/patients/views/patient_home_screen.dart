import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import 'package:frontend_dialysis_record/features/auth/providers/auth_providers.dart';
import 'package:frontend_dialysis_record/features/patients/views/patient_today_screen.dart';

/// Patient home screen acting as a shell for GoRouter's StatefulShellRoute.
///
/// Contains the bottom NavigationBar and renders the current branch.
class PatientHomeScreen extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const PatientHomeScreen({super.key, required this.navigationShell});

  @override
  ConsumerState<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends ConsumerState<PatientHomeScreen> {
  bool _isFabHidden = false;

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authStateProvider).valueOrNull;
    final patientId = me?.id;

    return Scaffold(
      body: widget.navigationShell,

      floatingActionButton:
          widget.navigationShell.currentIndex == 0 && patientId != null && !_isFabHidden
          ? FloatingActionButton(
              onPressed: () async {
                setState(() => _isFabHidden = true);
                await patientTodayKey.currentState?.openCreateSession();
                if (mounted) setState(() => _isFabHidden = false);
              },
              tooltip: 'Nuevo cambio',
              child: const Icon(PhosphorIconsBold.plus),
            )
          : null,

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
          elevation: 0,
          selectedIndex: widget.navigationShell.currentIndex,
          onDestinationSelected: (index) {
            widget.navigationShell.goBranch(
              index,
              initialLocation: index == widget.navigationShell.currentIndex,
            );
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(PhosphorIconsRegular.house),
              selectedIcon: Icon(PhosphorIconsFill.house),
              label: 'Hoy',
            ),
            NavigationDestination(
              icon: Icon(PhosphorIconsRegular.clockCounterClockwise),
              selectedIcon: Icon(PhosphorIconsFill.clockCounterClockwise),
              label: 'Historial',
            ),
            NavigationDestination(
              icon: Icon(PhosphorIconsRegular.user),
              selectedIcon: Icon(PhosphorIconsFill.user),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
