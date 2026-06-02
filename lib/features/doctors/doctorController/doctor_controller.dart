import 'package:frontend_dialysis_record/features/auth/models/me_response.dart';
import 'package:frontend_dialysis_record/features/doctors/api/doctor_api.dart';

class DoctorController {
  final DoctorApi doctorApi;

  DoctorController(this.doctorApi);

  Future<List<MeResponse>> getMyPatients() => doctorApi.getMyPatients();

  Future<MeResponse> addPatient(String patientId) => doctorApi.addPatient(patientId);

  Future<void> removePatient(String patientId) => doctorApi.removePatient(patientId);
}
