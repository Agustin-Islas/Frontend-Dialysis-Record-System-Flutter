import 'package:dio/dio.dart';
import 'package:frontend_dialysis_record/core/network/app_exception.dart';
import 'package:frontend_dialysis_record/core/network/dio_client.dart';
import 'package:frontend_dialysis_record/features/auth/models/me_response.dart';

class DoctorApi {
  final DioClient dioClient;

  DoctorApi(this.dioClient);

  Future<List<MeResponse>> getMyPatients() async {
    try {
      final res = await dioClient.dio.get('/api/doctors/me/patients');
      final data = res.data;
      if (data is List) {
        return data.map((e) => MeResponse.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw e.error is AppException ? e.error as AppException : AppException.fromDio(e);
    }
  }

  Future<MeResponse> addPatient(String patientId) async {
    try {
      final res = await dioClient.dio.post('/api/doctors/me/patients/$patientId');
      return MeResponse.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.error is AppException ? e.error as AppException : AppException.fromDio(e);
    }
  }

  Future<void> removePatient(String patientId) async {
    try {
      await dioClient.dio.delete('/api/doctors/me/patients/$patientId');
    } on DioException catch (e) {
      throw e.error is AppException ? e.error as AppException : AppException.fromDio(e);
    }
  }
}
