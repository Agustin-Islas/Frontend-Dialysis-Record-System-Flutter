import 'package:frontend_dialysis_record/features/auth/models/register_doctor_request.dart';
import 'package:frontend_dialysis_record/features/auth/models/register_patient_request.dart';
import '../api/auth_api.dart';
import '../models/me_response.dart';
import 'package:frontend_dialysis_record/core/network/dio_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController {
  final DioClient dioClient;
  late final AuthApi authApi;

  AuthController(this.dioClient) {
    authApi = AuthApi(dioClient);
  }

  Future<MeResponse?> getMe() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return null;
    return await authApi.getMe();
  }

  Future<void> registerPatient({
    required String email,
    required String name,
    required String surname,
    required int dni,
    required String dateOfBirth, // "YYYY-MM-DD"
    required String address,
    required int number,
  }) async {
    final req = RegisterPatientRequest(
      email: email,
      name: name,
      surname: surname,
      dni: dni,
      dateOfBirth: dateOfBirth,
      address: address,
      number: number,
    );

    await authApi.registerPatient(req);
  }

  Future<void> registerDoctor({
    required String email,
    required String name,
    required String surname,
  }) async {
    final req = RegisterDoctorRequest(
      email: email,
      name: name,
      surname: surname,
    );

    await authApi.registerDoctor(req);
  }
}
