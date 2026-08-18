import 'package:dio/dio.dart';
import 'package:frontend_dialysis_record/core/network/api_paths.dart';
import 'package:frontend_dialysis_record/core/network/app_exception.dart';
import 'package:frontend_dialysis_record/core/network/dio_client.dart';
import 'package:frontend_dialysis_record/features/auth/models/me_response.dart';
import 'package:frontend_dialysis_record/features/auth/models/register_doctor_request.dart';
import 'package:frontend_dialysis_record/features/auth/models/register_patient_request.dart';

class AuthApi {
  final DioClient dioClient;

  AuthApi(this.dioClient);

  Future<void> registerPatient(RegisterPatientRequest request) async {
    try {
      await dioClient.dio.post(
        '/auth/register/patient',
        data: request.toJson(),
      );
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : AppException.fromDio(e);
    }
  }

  Future<void> registerDoctor(RegisterDoctorRequest request) async {
    try {
      await dioClient.dio.post('/auth/register/doctor', data: request.toJson());
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : AppException.fromDio(e);
    }
  }

  Future<MeResponse> getMe() async {
    // Como Supabase no guarda el rol (Paciente/Doctor) en su JWT por defecto,
    // probamos el endpoint de paciente. Si da error de acceso, probamos el de doctor.
    try {
      final response = await dioClient.dio.get(ApiPaths.patientMe);
      final data = response.data as Map<String, dynamic>;
      data['role'] = 'PATIENT';
      return MeResponse.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 ||
          e.response?.statusCode == 404 ||
          e.response?.statusCode == 401) {
        // Intentar doctor
        try {
          final doctorRes = await dioClient.dio.get(ApiPaths.doctorMe);
          final doctorData = doctorRes.data as Map<String, dynamic>;
          doctorData['role'] = 'DOCTOR';
          return MeResponse.fromJson(doctorData);
        } on DioException catch (e2) {
          throw e2.error is AppException
              ? e2.error as AppException
              : AppException.fromDio(e2);
        }
      }
      throw e.error is AppException
          ? e.error as AppException
          : AppException.fromDio(e);
    }
  }
}
