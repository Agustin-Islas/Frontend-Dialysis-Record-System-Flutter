import 'package:dio/dio.dart';
import 'package:frontend_dialysis_record/core/network/app_exception.dart';
import 'package:frontend_dialysis_record/core/network/dio_client.dart';
import 'package:frontend_dialysis_record/features/invitations/models/create_invitation_dto.dart';
import 'package:frontend_dialysis_record/features/invitations/models/invitation_dto.dart';

class InvitationApi {
  final DioClient dioClient;

  InvitationApi(this.dioClient);

  Future<InvitationDto> createInvitation({
    required CreateInvitationDto dto,
  }) async {
    try {
      final res = await dioClient.dio.post(
        '/api/invitations',
        data: dto.toJson(),
      );
      return InvitationDto.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : AppException.fromDio(e);
    }
  }

  Future<List<InvitationDto>> getMyDoctorInvitations() async {
    try {
      final res = await dioClient.dio.get('/api/invitations/doctor/me');
      final data = res.data;
      if (data is List) {
        return data
            .map((e) => InvitationDto.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : AppException.fromDio(e);
    }
  }

  Future<List<InvitationDto>> getMyPatientInvitations({
    String? email,
    int? dni,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (email != null) queryParams['email'] = email;
      if (dni != null) queryParams['dni'] = dni;

      final res = await dioClient.dio.get(
        '/api/invitations/patient/me',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      final data = res.data;
      if (data is List) {
        return data
            .map((e) => InvitationDto.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : AppException.fromDio(e);
    }
  }

  Future<InvitationDto> acceptInvitation(String invitationId) async {
    try {
      final res = await dioClient.dio.post(
        '/api/invitations/$invitationId/accept',
      );
      return InvitationDto.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : AppException.fromDio(e);
    }
  }

  Future<InvitationDto> rejectInvitation(String invitationId) async {
    try {
      final res = await dioClient.dio.post(
        '/api/invitations/$invitationId/reject',
      );
      return InvitationDto.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : AppException.fromDio(e);
    }
  }
}
