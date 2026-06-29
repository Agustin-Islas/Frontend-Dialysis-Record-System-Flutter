import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_dialysis_record/core/widgets/widgets.dart';
import 'package:frontend_dialysis_record/features/auth/providers/auth_providers.dart';

/// Initial loading screen shown while checking authentication state.
///
/// The GoRouter redirect guard handles navigation based on auth state,
/// so this widget only needs to show a loading indicator.
class SessionGate extends ConsumerWidget {
  const SessionGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      body: authState.when(
        loading: () => const AppSkeletonScreen(itemCount: 3),
        error: (error, _) => AppErrorCard(
          message: 'No se pudo verificar la sesión.',
          details: error.toString(),
          onRetry: () => ref.invalidate(authStateProvider),
        ),
        data: (_) => const AppSkeletonScreen(itemCount: 3),
      ),
    );
  }
}
