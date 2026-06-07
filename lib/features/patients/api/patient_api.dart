import 'package:dio/dio.dart';
import 'package:frontend_dialysis_record/core/network/app_exception.dart';
import 'package:frontend_dialysis_record/core/network/dio_client.dart';
import 'package:frontend_dialysis_record/features/auth/models/me_response.dart';
import 'package:frontend_dialysis_record/features/sessions/models/session_dto.dart';
import 'package:frontend_dialysis_record/features/sessions/models/session_summary.dart';

class PatientApi {
  final DioClient dioClient;

  PatientApi(this.dioClient);

  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<List<SessionDto>> getSessionsByDay({
    required String patientId,
    required DateTime day,
  }) async {
    try {
      final dayStr = _formatDate(day);
      final res = await dioClient.dio.get(
        '/api/patients/$patientId/sessions/day/$dayStr',
      );
      final data = res.data;
      if (data is List) {
        return data
            .map((e) => SessionDto.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : AppException.fromDio(e);
    }
  }

  Future<SessionSummary> getSessionSummaryByDay({
    required String patientId,
    required DateTime day,
  }) async {
    try {
      final dayStr = _formatDate(day);
      final res = await dioClient.dio.get(
        '/api/patients/$patientId/sessions/summary/day/$dayStr',
      );
      return SessionSummary.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : AppException.fromDio(e);
    }
  }

  Future<List<SessionDto>> getSessionsByDateRange({
    required String patientId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final res = await dioClient.dio.get(
        '/api/patients/$patientId/sessions',
        queryParameters: {
          'startDate': _formatDate(startDate),
          'endDate': _formatDate(endDate),
        },
      );

      final data = res.data;
      if (data is List) {
        return data
            .map((e) => SessionDto.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : AppException.fromDio(e);
    }
  }

  Future<SessionSummary> getSessionSummaryByMonth({
    required String patientId,
    required int year,
    required int month,
  }) async {
    try {
      final res = await dioClient.dio.get(
        '/api/patients/$patientId/sessions/summary/month',
        queryParameters: {'year': year, 'month': month},
      );
      return SessionSummary.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : AppException.fromDio(e);
    }
  }

  Future<SessionDto> createSession({
    required String patientId,
    required Map<String, dynamic> body,
  }) async {
    try {
      final res = await dioClient.dio.post(
        '/api/patients/$patientId/sessions',
        data: body,
      );
      return SessionDto.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : AppException.fromDio(e);
    }
  }

  Future<SessionDto> updateSession({
    required String sessionId,
    required Map<String, dynamic> body,
  }) async {
    try {
      final res = await dioClient.dio.put(
        '/api/sessions/$sessionId',
        data: body,
      );
      return SessionDto.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : AppException.fromDio(e);
    }
  }

  Future<void> deleteSession({required String sessionId}) async {
    try {
      await dioClient.dio.delete('/api/sessions/$sessionId');
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : AppException.fromDio(e);
    }
  }

  Future<MeResponse> getPatientById(String patientId) async {
    try {
      final res = await dioClient.dio.get('/api/patients/$patientId');
      return MeResponse.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : AppException.fromDio(e);
    }
  }

  Future<List<MeResponse>> getAllPatients() async {
    try {
      final res = await dioClient.dio.get('/api/patients');
      final data = res.data;
      if (data is List) {
        return data
            .map((e) => MeResponse.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : AppException.fromDio(e);
    }
  }

  Future<MeResponse> updatePatient({
    required String patientId,
    required Map<String, dynamic> body,
  }) async {
    try {
      final res = await dioClient.dio.put(
        '/api/patients/$patientId',
        data: body,
      );
      return MeResponse.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : AppException.fromDio(e);
    }
  }
}
