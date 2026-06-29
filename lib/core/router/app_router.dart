import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend_dialysis_record/features/auth/providers/auth_providers.dart';
import 'package:frontend_dialysis_record/features/auth/views/login_screen.dart';
import 'package:frontend_dialysis_record/features/auth/views/session_gate.dart';
import 'package:frontend_dialysis_record/features/doctors/views/doctor_home_screen.dart';
import 'package:frontend_dialysis_record/features/doctors/views/doctor_patients_screen.dart';
import 'package:frontend_dialysis_record/features/doctors/views/patient_detail_for_doctor_screen.dart';
import 'package:frontend_dialysis_record/features/patients/views/patient_home_screen.dart';
import 'package:frontend_dialysis_record/features/patients/views/patient_today_screen.dart';
import 'package:frontend_dialysis_record/features/patients/views/patient_history_screen.dart';
import 'package:frontend_dialysis_record/features/patients/views/patient_profile_screen.dart';
import 'package:frontend_dialysis_record/features/patients/views/patient_register_screen.dart';
import 'package:frontend_dialysis_record/features/doctors/views/doctor_register_screen.dart';

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

/// GoRouter configuration provider.
///
/// Uses [authStateProvider] for redirect guards. When not authenticated,
/// the user is redirected to login. When authenticated, going to login
/// redirects to the role-specific home.
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final me = authState.valueOrNull;
      final isAuthenticated = me != null;

      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.registerPatient ||
          state.matchedLocation == AppRoutes.registerDoctor;
      final isSplash = state.matchedLocation == AppRoutes.splash;

      // While loading, stay on splash
      if (isLoading && isSplash) return null;

      // Not authenticated → go to login (unless already on auth route)
      if (!isAuthenticated) {
        return isAuthRoute ? null : AppRoutes.login;
      }

      // Authenticated → redirect from auth routes to home
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
        builder: (context, state) => const SessionGate(),
      ),

      // Auth routes
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.registerPatient,
        builder: (context, state) => const PatientRegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.registerDoctor,
        builder: (context, state) => const DoctorRegisterScreen(),
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
                builder: (context, state) => PatientTodayScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.patientHistory,
                builder: (context, state) => const PatientHistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.patientProfile,
                builder: (context, state) => const PatientProfileScreen(),
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
                builder: (context, state) => const DoctorPatientsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.doctorProfile,
                builder: (context, state) => const _DoctorProfilePlaceholder(),
              ),
            ],
          ),
        ],
      ),

      // Doctor patient detail (push route, not shell)
      GoRoute(
        path: AppRoutes.doctorPatientDetail,
        builder: (context, state) {
          final patientId = state.pathParameters['patientId']!;
          return PatientDetailForDoctorScreen(patientId: patientId);
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
