import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_dialysis_record/core/providers/providers.dart';
import 'package:frontend_dialysis_record/features/auth/models/me_response.dart';

/// Provider for loading the doctor's associated patients.
final doctorPatientsProvider = FutureProvider.autoDispose<List<MeResponse>>((ref) async {
  final controller = ref.watch(doctorControllerProvider);
  return controller.getMyPatients();
});
