import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend_dialysis_record/core/providers/providers.dart';
import 'package:frontend_dialysis_record/features/auth/models/me_response.dart';

/// Manages authentication state across the app.
class AuthNotifier extends AsyncNotifier<MeResponse?> {
  @override
  Future<MeResponse?> build() async {
    // Escuchar cambios de sesión en Supabase para auto-actualizar el estado
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session == null) {
        state = const AsyncData(null);
      } else {
        refresh();
      }
    });

    return _fetchAndSync();
  }

  Future<MeResponse?> _fetchAndSync() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return null;

    final controller = ref.read(authControllerProvider);
    try {
      return await controller.getMe();
    } catch (e) {
      // Si getMe falla, el usuario existe en Supabase pero quizás aún no en Spring Boot
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null &&
          user.userMetadata != null &&
          user.userMetadata!.containsKey('role')) {
        try {
          final role = user.userMetadata!['role'];
          if (role == 'PATIENT') {
            await controller.registerPatient(
              email: user.email ?? '',
              name: user.userMetadata!['name'] ?? '',
              surname: user.userMetadata!['surname'] ?? '',
              dni: user.userMetadata!['dni'] ?? 0,
              dateOfBirth: user.userMetadata!['dateOfBirth'] ?? '',
              address: user.userMetadata!['address'] ?? '',
              number: user.userMetadata!['number'] ?? 0,
            );
          } else if (role == 'DOCTOR') {
            await controller.registerDoctor(
              email: user.email ?? '',
              name: user.userMetadata!['name'] ?? '',
              surname: user.userMetadata!['surname'] ?? '',
            );
          }
          // Tras registrar, volvemos a intentar getMe
          return await controller.getMe();
        } catch (syncError) {
          if (kDebugMode) debugPrint('Error syncing with backend: $syncError');
          rethrow;
        }
      }
      rethrow;
    }
  }

  /// Clear session and redirect to login.
  Future<void> logout({bool global = false}) async {
    final scope = global ? SignOutScope.global : SignOutScope.local;
    await Supabase.instance.client.auth.signOut(scope: scope);
    state = const AsyncData(null);
  }

  /// Refresh user data without clearing the session.
  Future<void> refresh() async {
    try {
      final me = await _fetchAndSync();
      state = AsyncData(me);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final authStateProvider = AsyncNotifierProvider<AuthNotifier, MeResponse?>(
  AuthNotifier.new,
);
