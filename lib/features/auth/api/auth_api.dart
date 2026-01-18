import 'package:dio/dio.dart';
import 'package:frontend_dialysis_record/features/auth/models/register_patient_request.dart';

import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/me_response.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_paths.dart';
import 'package:frontend_dialysis_record/core/auth/token_storage.dart';

class AuthApi {
  final DioClient dioClient;
  final TokenStorage tokenStorage;

  AuthApi(this.dioClient, this.tokenStorage);

  Future<LoginResponse> login(LoginRequest req) async {
    try {
      final response =
          await dioClient.dio.post(ApiPaths.login, data: req.toJson());
      return LoginResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Credenciales inválidas');
      }
      throw Exception(
          'Error de red/servidor (${e.response?.statusCode ?? 'sin status'})');
    }
  }

  Future<void> registerPatient(RegisterPatientRequest request) async {
    await dioClient.dio.post(
      '/auth/register/patient',
      data: request.toJson(),
    );
  }

  Future<MeResponse> getMeForRole(String role) async {
    final path = (role == 'DOCTOR') ? ApiPaths.doctorMe : ApiPaths.patientMe;

    // Leer access token y mandarlo en Authorization
    final accessToken = await tokenStorage.readAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('No hay accessToken guardado (no se puede llamar /me)');
    }

    try {
      final response = await dioClient.dio.get(
        path,
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );
      return MeResponse.fromJson(response.data);
    } on DioException catch (e) {
      // Si backend responde 401 por token expirado, opcional: refresh + retry
      final status = e.response?.statusCode;
      if (status == 401) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          final newAccess = await tokenStorage.readAccessToken();
          final retry = await dioClient.dio.get(
            path,
            options: Options(headers: {'Authorization': 'Bearer $newAccess'}),
          );
          return MeResponse.fromJson(retry.data);
        }
      }

      if (status == 403) {
        // 403 suele ser: token válido pero sin permisos/rol para ese endpoint
        throw Exception('403 Forbidden: token válido pero sin permisos para $path (rol/authorities).');
      }

      throw Exception('Error en /me (${status ?? 'sin status'})');
    }
  }

  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await tokenStorage.readRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final res = await dioClient.dio.post(
        ApiPaths.refresh,
        data: {'refreshToken': refreshToken},
      );

      final data = res.data as Map<String, dynamic>;
      final newAccess = data['accessToken'] as String?;
      final newRefresh = data['refreshToken'] as String?;

      if (newAccess == null || newAccess.isEmpty) return false;

      await tokenStorage.saveAccessToken(newAccess);
      if (newRefresh != null && newRefresh.isNotEmpty) {
        await tokenStorage.saveRefreshToken(newRefresh);
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
