import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend_dialysis_record/features/auth/providers/auth_providers.dart';
import 'package:frontend_dialysis_record/features/auth/views/login_screen.dart';
import 'package:frontend_dialysis_record/features/auth/views/otp_verification_screen.dart';
import 'package:frontend_dialysis_record/features/auth/views/session_gate.dart';
import 'package:frontend_dialysis_record/features/auth/views/forgot_password_screen.dart';
import 'package:frontend_dialysis_record/features/auth/views/update_password_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend_dialysis_record/features/doctors/views/doctor_home_screen.dart';
import 'package:frontend_dialysis_record/features/doctors/views/doctor_patients_screen.dart';
import 'package:frontend_dialysis_record/features/doctors/views/patient_detail_for_doctor_screen.dart';
import 'package:frontend_dialysis_record/features/patients/views/patient_home_screen.dart';
import 'package:frontend_dialysis_record/features/patients/views/patient_today_screen.dart';
import 'package:frontend_dialysis_record/features/patients/views/patient_history_screen.dart';
import 'package:frontend_dialysis_record/features/patients/views/patient_profile_screen.dart';
import 'package:frontend_dialysis_record/features/patients/views/patient_register_screen.dart';
import 'package:frontend_dialysis_record/features/doctors/views/doctor_register_screen.dart';
import 'package:frontend_dialysis_record/core/router/not_found_screen.dart';

/// Named route paths used across the app.
abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String registerPatient = '/register/patient';
  static const String registerDoctor = '/register/doctor';

  // Patient shell
  static const String patientToday = '/patient/today';
  static const String patientHistory = '/patient/history';
  static const String patientProfile = '/patient/profile';

  // Doctor shell
  static const String doctorPatients = '/doctor/patients';
  static const String doctorProfile = '/doctor/profile';
  static const String doctorPatientDetail = '/doctor/patients/:patientId';
}

// Helper for premium page transitions
Page<dynamic> _premiumTransition(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 400),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curve,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 0.05),
            end: Offset.zero,
          ).animate(curve),
          child: child,
        ),
      );
    },
  );
}

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, _) => notifyListeners());
  }
}

/// GoRouter configuration provider.
///
/// Uses [authStateProvider] for redirect guards. When not authenticated,
/// the user is redirected to login. When authenticated, going to login
/// redirects to the role-specific home.
final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    refreshListenable: refreshNotifier,
    errorBuilder: (context, state) => const NotFoundScreen(),
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoading = authState.isLoading;
      final me = authState.valueOrNull;
      final isAuthenticated = me != null;
      final hasSupabaseSession = Supabase.instance.client.auth.currentSession != null;

      final isAuthRoute =
          state.matchedLocation.startsWith(AppRoutes.login) ||
          state.matchedLocation == AppRoutes.registerPatient ||
          state.matchedLocation == AppRoutes.registerDoctor ||
          state.matchedLocation == '/forgot-password';

      final isUnauthAllowed =
          isAuthRoute ||
          state.matchedLocation == '/verify-otp' ||
          state.matchedLocation == '/update-password';

      final isSplash = state.matchedLocation == AppRoutes.splash;

      // While loading, stay on splash
      if (isLoading && isSplash) return null;

      // Si hubo error de red/sincronización pero Supabase mantiene una sesión viva, 
      // nos quedamos en Splash (SessionGate) para mostrar el error o esperar el refresco, 
      // evitando que el usuario sea pateado al login por parpadeo.
      if (authState.hasError && hasSupabaseSession) {
        return isSplash ? null : AppRoutes.splash;
      }

      // Not authenticated → go to login (unless already on allowed route)
      if (!isAuthenticated) {
        return isUnauthAllowed ? null : AppRoutes.login;
      }

      // Authenticated → redirect from auth routes to home
      // Note: we don't redirect from /verify-otp because we want the screen itself
      // to handle the navigation (e.g. to /update-password)
      if (isAuthRoute || isSplash) {
        return me.role == 'DOCTOR'
            ? AppRoutes.doctorPatients
            : AppRoutes.patientToday;
      }

      return null;
    },
    routes: [
      // Splash / initial loading
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) =>
            _premiumTransition(const SessionGate(), state),
      ),

      // Auth routes
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) =>
            _premiumTransition(const LoginScreen(), state),
        routes: [
          GoRoute(
            path: 'otp',
            pageBuilder: (context, state) {
              final email = state.extra as String? ?? '';
              return _premiumTransition(
                OtpVerificationScreen(email: email),
                state,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) =>
            _premiumTransition(const ForgotPasswordScreen(), state),
      ),
      GoRoute(
        path: '/verify-otp',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final email = extra['email'] as String? ?? '';
          final type = extra['type'] as OtpType? ?? OtpType.signup;
          final onSuccessRoute = extra['onSuccessRoute'] as String? ?? '/login';
          return _premiumTransition(
            OtpVerificationScreen(
              email: email,
              type: type,
              onSuccessRoute: onSuccessRoute,
            ),
            state,
          );
        },
      ),
      GoRoute(
        path: '/update-password',
        pageBuilder: (context, state) =>
            _premiumTransition(const UpdatePasswordScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.registerPatient,
        pageBuilder: (context, state) =>
            _premiumTransition(const PatientRegisterScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.registerDoctor,
        pageBuilder: (context, state) =>
            _premiumTransition(const DoctorRegisterScreen(), state),
      ),

      // Patient shell with bottom navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return PatientHomeScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.patientToday,
                pageBuilder: (context, state) =>
                    NoTransitionPage(child: PatientTodayScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.patientHistory,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: PatientHistoryScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.patientProfile,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: PatientProfileScreen()),
              ),
            ],
          ),
        ],
      ),

      // Doctor shell with bottom navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return DoctorHomeScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.doctorPatients,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: DoctorPatientsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.doctorProfile,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: _DoctorProfilePlaceholder()),
              ),
            ],
          ),
        ],
      ),

      // Doctor patient detail (push route, not shell)
      GoRoute(
        path: AppRoutes.doctorPatientDetail,
        pageBuilder: (context, state) {
          final patientId = state.pathParameters['patientId']!;
          return _premiumTransition(
            PatientDetailForDoctorScreen(patientId: patientId),
            state,
          );
        },
      ),
    ],
  );
});

/// Placeholder for doctor profile — the actual profile widget
/// is embedded directly in [DoctorHomeScreen] for now.
class _DoctorProfilePlaceholder extends StatelessWidget {
  const _DoctorProfilePlaceholder();

  @override
  Widget build(BuildContext context) {
    // This will be replaced by the actual profile content
    // rendered inside DoctorHomeScreen's shell
    return const SizedBox.shrink();
  }
}
