import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:frontend_dialysis_record/core/design/design.dart';
import 'package:frontend_dialysis_record/core/router/app_router.dart';
import 'package:frontend_dialysis_record/core/widgets/widgets.dart';
import 'package:frontend_dialysis_record/features/auth/providers/auth_providers.dart';

/// Doctor home screen acting as a shell for GoRouter's StatefulShellRoute.
///
/// Contains the bottom NavigationBar and renders the current branch.
class DoctorHomeScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const DoctorHomeScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: navigationShell.currentIndex == 1
          ? _DoctorProfileContent()
          : navigationShell,

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
            icon: Icon(PhosphorIconsRegular.users),
            selectedIcon: Icon(PhosphorIconsFill.users),
            label: 'Pacientes',
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

/// Doctor profile content rendered inline when the profile tab is selected.
class _DoctorProfileContent extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final me = authState.valueOrNull;

    if (me == null) {
      return const AppErrorCard(message: 'No se pudo cargar el perfil.');
    }

    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                'Perfil médico',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.md),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: scheme.primaryContainer,
                            child: Icon(
                              PhosphorIconsRegular.stethoscope,
                              color: scheme.primary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${me.name ?? "-"} ${me.surname ?? ""}'.trim(),
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (me.email != null)
                                  Text(
                                    me.email!,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Divider(),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Icon(PhosphorIconsRegular.usersThree, size: 20, color: scheme.onSurfaceVariant),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Pacientes asociados: ${me.patientCount ?? me.patientIds.length}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () async {
                    await ref.read(authStateProvider.notifier).logout();
                    if (!context.mounted) return;
                    context.go(AppRoutes.login);
                  },
                  icon: const Icon(PhosphorIconsRegular.signOut),
                  label: const Text('Cerrar sesión'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
