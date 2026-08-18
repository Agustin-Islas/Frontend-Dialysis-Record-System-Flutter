import 'package:frontend_dialysis_record/core/network/dio_client.dart';
import 'package:frontend_dialysis_record/features/auth/authController/auth_controller.dart';
import 'package:frontend_dialysis_record/features/doctors/api/doctor_api.dart';
import 'package:frontend_dialysis_record/features/doctors/doctorController/doctor_controller.dart';
import 'package:frontend_dialysis_record/features/patients/api/patient_api.dart';
import 'package:frontend_dialysis_record/features/patients/patientController/patient_controller.dart';

class AppDI {
  AppDI._();

  // 1) UN solo dioClient, usando la sesión de supabase internamente
  static final DioClient dioClient = DioClient();

  // 2) Controllers / APIs que usan SIEMPRE ese dioClient
  static final AuthController authController = AuthController(dioClient);

  static final PatientApi patientApi = PatientApi(dioClient);
  static final PatientController patientController = PatientController(
    patientApi,
  );

  static final DoctorApi doctorApi = DoctorApi(dioClient);
  static final DoctorController doctorController = DoctorController(doctorApi);
}
