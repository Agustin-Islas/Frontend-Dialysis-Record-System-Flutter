import 'package:frontend_dialysis_record/features/auth/models/register_patient_request.dart';
import '../api/auth_api.dart';
import '../models/login_request.dart';
import '../models/me_response.dart';
import 'package:frontend_dialysis_record/core/auth/token_storage.dart';
import 'package:frontend_dialysis_record/core/auth/jwt_decoder.dart';
import 'package:frontend_dialysis_record/core/network/dio_client.dart';

class AuthController {
  final DioClient dioClient;
  final TokenStorage tokenStorage;
  late final AuthApi authApi;

  AuthController(this.dioClient, this.tokenStorage) {
    authApi = AuthApi(dioClient, tokenStorage);
  }

  Future<MeResponse?> login(String email, String password) async {
    final loginRequest = LoginRequest(email: email, password: password);
    final loginResponse = await authApi.login(loginRequest);
    await tokenStorage.saveAccessToken(loginResponse.accessToken);
    final role = JwtDecoder.getRole(loginResponse.accessToken);
    return await authApi.getMeForRole(role!);
  }

  Future<void> logout() async {
    await tokenStorage.clearAll();
  }

  Future<MeResponse?> getMe() async {
    final token = await tokenStorage.readAccessToken();
    if (token == null) return null;
    final role = JwtDecoder.getRole(token);
    return await authApi.getMeForRole(role!);
  }

  Future<void> registerPatient({
      required String email,
      required String password,
      required String name,
      required String surname,
      required int dni,
      required String dateOfBirth, // "YYYY-MM-DD"
      required String address,
      required int number,
  }) async {
    final req = RegisterPatientRequest(
      email: email,
      password: password,
      name: name,
      surname: surname,
      dni: dni,
      dateOfBirth: dateOfBirth,
      address: address,
      number: number,
    );

    await authApi.registerPatient(req);
  }
}