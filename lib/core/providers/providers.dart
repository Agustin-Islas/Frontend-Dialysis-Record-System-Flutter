import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_dialysis_record/core/auth/token_storage.dart';
import 'package:frontend_dialysis_record/core/network/dio_client.dart';
import 'package:frontend_dialysis_record/features/auth/authController/auth_controller.dart';
import 'package:frontend_dialysis_record/features/doctors/api/doctor_api.dart';
import 'package:frontend_dialysis_record/features/doctors/doctorController/doctor_controller.dart';
import 'package:frontend_dialysis_record/features/patients/api/patient_api.dart';
import 'package:frontend_dialysis_record/features/patients/patientController/patient_controller.dart';
import 'package:frontend_dialysis_record/features/invitations/api/invitation_api.dart';
import 'package:frontend_dialysis_record/features/invitations/invitationController/invitation_controller.dart';

/// Infrastructure providers that replace the static [AppDI] class.
///
/// These providers expose the same instances but allow Riverpod-based
/// injection, making the code testable and removing global mutable state.

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});

final authControllerProvider = Provider<AuthController>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AuthController(dioClient);
});

final patientApiProvider = Provider<PatientApi>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return PatientApi(dioClient);
});

final patientControllerProvider = Provider<PatientController>((ref) {
  final patientApi = ref.watch(patientApiProvider);
  return PatientController(patientApi);
});

final doctorApiProvider = Provider<DoctorApi>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return DoctorApi(dioClient);
});

final doctorControllerProvider = Provider<DoctorController>((ref) {
  final doctorApi = ref.watch(doctorApiProvider);
  return DoctorController(doctorApi);
});

final invitationApiProvider = Provider<InvitationApi>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return InvitationApi(dioClient);
});

final invitationControllerProvider = Provider<InvitationController>((ref) {
  final invitationApi = ref.watch(invitationApiProvider);
  return InvitationController(invitationApi);
});
