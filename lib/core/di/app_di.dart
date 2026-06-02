import 'package:frontend_dialysis_record/core/auth/token_storage.dart';
import 'package:frontend_dialysis_record/core/network/dio_client.dart';
import 'package:frontend_dialysis_record/features/auth/authController/auth_controller.dart';
import 'package:frontend_dialysis_record/features/doctors/api/doctor_api.dart';
import 'package:frontend_dialysis_record/features/doctors/doctorController/doctor_controller.dart';
import 'package:frontend_dialysis_record/features/patients/api/patient_api.dart';
import 'package:frontend_dialysis_record/features/patients/patientController/patient_controller.dart';

class AppDI {
  AppDI._();

  // 1) UN solo storage
  static final TokenStorage tokenStorage = TokenStorage();

  // 2) UN solo dioClient, usando ese storage (interceptor + refresh)
  static final DioClient dioClient = DioClient(tokenStorage: tokenStorage);

  // 3) Controllers / APIs que usan SIEMPRE ese dioClient + storage
  static final AuthController authController = AuthController(dioClient, tokenStorage);

  static final PatientApi patientApi = PatientApi(dioClient);
  static final PatientController patientController = PatientController(patientApi);

  static final DoctorApi doctorApi = DoctorApi(dioClient);
  static final DoctorController doctorController = DoctorController(doctorApi);
}
