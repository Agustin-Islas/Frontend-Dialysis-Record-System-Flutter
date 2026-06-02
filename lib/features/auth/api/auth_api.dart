import 'package:dio/dio.dart';
import 'package:frontend_dialysis_record/core/auth/token_storage.dart';
import 'package:frontend_dialysis_record/core/network/api_paths.dart';
import 'package:frontend_dialysis_record/core/network/app_exception.dart';
import 'package:frontend_dialysis_record/core/network/dio_client.dart';
import 'package:frontend_dialysis_record/features/auth/models/login_request.dart';
import 'package:frontend_dialysis_record/features/auth/models/login_response.dart';
import 'package:frontend_dialysis_record/features/auth/models/me_response.dart';
import 'package:frontend_dialysis_record/features/auth/models/register_patient_request.dart';

class AuthApi {
  final DioClient dioClient;
  final TokenStorage tokenStorage;

  AuthApi(this.dioClient, this.tokenStorage);

  Future<LoginResponse> login(LoginRequest req) async {
    try {
      final response = await dioClient.dio.post(ApiPaths.login, data: req.toJson());
      return LoginResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.error is AppException ? e.error as AppException : AppException.fromDio(e);
    }
  }

  Future<void> registerPatient(RegisterPatientRequest request) async {
    try {
      await dioClient.dio.post('/auth/register/patient', data: request.toJson());
    } on DioException catch (e) {
      throw e.error is AppException ? e.error as AppException : AppException.fromDio(e);
    }
  }

  Future<MeResponse> getMeForRole(String role) async {
    final path = role == 'DOCTOR' ? ApiPaths.doctorMe : ApiPaths.patientMe;
    final accessToken = await tokenStorage.readAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw const AppException('No hay una sesión activa.', statusCode: 401);
    }

    try {
      final response = await dioClient.dio.get(path);
      return MeResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.error is AppException ? e.error as AppException : AppException.fromDio(e);
    }
  }
}
