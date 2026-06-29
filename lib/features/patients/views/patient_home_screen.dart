import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:frontend_dialysis_record/core/design/design.dart';
import 'package:frontend_dialysis_record/core/router/app_router.dart';
import 'package:frontend_dialysis_record/features/auth/providers/auth_providers.dart';
import 'package:frontend_dialysis_record/features/patients/views/patient_today_screen.dart';

/// Patient home screen acting as a shell for GoRouter's StatefulShellRoute.
///
/// Contains the bottom NavigationBar and renders the current branch.
class PatientHomeScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const PatientHomeScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authStateProvider).valueOrNull;
    final patientId = me?.id;

    return Scaffold(
      body: navigationShell,

      floatingActionButton: navigationShell.currentIndex == 0 && patientId != null
          ? FloatingActionButton(
              onPressed: () {
                // The PatientTodayScreen handles the create session via a key
                // We trigger it through a callback mechanism
                patientTodayKey.currentState?.openCreateSession();
              },
              tooltip: 'Nuevo cambio',
              child: const Icon(PhosphorIconsBold.plus),
            )
          : null,

      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
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
    );
  }
}


