import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_dialysis_record/core/providers/providers.dart';
import 'package:frontend_dialysis_record/features/auth/models/me_response.dart';
import 'package:frontend_dialysis_record/features/sessions/models/session_dto.dart';
import 'package:frontend_dialysis_record/features/sessions/models/session_summary.dart';

/// Provider family for loading sessions of a specific day.
final daySessionsProvider =
    FutureProvider.autoDispose.family<List<SessionDto>, ({String patientId, DateTime day})>(
  (ref, params) async {
    final controller = ref.watch(patientControllerProvider);
    return controller.getSessionsByDay(
      patientId: params.patientId,
      day: params.day,
    );
  },
);

/// Provider family for loading the summary of a specific day.
final daySummaryProvider =
    FutureProvider.autoDispose.family<SessionSummary, ({String patientId, DateTime day})>(
  (ref, params) async {
    final controller = ref.watch(patientControllerProvider);
    return controller.getSessionSummaryByDay(
      patientId: params.patientId,
      day: params.day,
    );
  },
);

/// Provider family for loading sessions of a month range.
final monthSessionsProvider = FutureProvider.autoDispose.family<List<SessionDto>,
    ({String patientId, DateTime month})>(
  (ref, params) async {
    final controller = ref.watch(patientControllerProvider);
    return controller.getSessionsByDateRange(
      patientId: params.patientId,
      startDate: DateTime(params.month.year, params.month.month, 1),
      endDate: DateTime(params.month.year, params.month.month + 1, 0),
    );
  },
);

/// Provider for fetching all patients (used in doctor's patient picker).
final allPatientsProvider = FutureProvider.autoDispose<List<MeResponse>>((ref) async {
  final controller = ref.watch(patientControllerProvider);
  return controller.getAllPatients();
});
