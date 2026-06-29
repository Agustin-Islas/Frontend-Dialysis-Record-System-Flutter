import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_dialysis_record/core/providers/providers.dart';
import 'package:frontend_dialysis_record/features/auth/models/me_response.dart';

/// Manages authentication state across the app.
///
/// Exposes the current user ([MeResponse]) or null if not authenticated.
/// Used by GoRouter's redirect guard to control navigation.
class AuthNotifier extends AsyncNotifier<MeResponse?> {
  @override
  Future<MeResponse?> build() async {
    final controller = ref.read(authControllerProvider);
    try {
      return await controller.getMe();
    } catch (_) {
      return null;
    }
  }

  /// Attempt login and update state.
  Future<MeResponse?> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final controller = ref.read(authControllerProvider);
      final me = await controller.login(email, password);
      state = AsyncData(me);
      return me;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Clear session and redirect to login.
  Future<void> logout() async {
    final controller = ref.read(authControllerProvider);
    await controller.logout();
    state = const AsyncData(null);
  }

  /// Refresh user data without clearing the session.
  Future<void> refresh() async {
    final controller = ref.read(authControllerProvider);
    try {
      final me = await controller.getMe();
      state = AsyncData(me);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, MeResponse?>(AuthNotifier.new);
