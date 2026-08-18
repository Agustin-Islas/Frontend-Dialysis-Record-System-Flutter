import 'package:frontend_dialysis_record/features/invitations/api/invitation_api.dart';
import 'package:frontend_dialysis_record/features/invitations/models/create_invitation_dto.dart';
import 'package:frontend_dialysis_record/features/invitations/models/invitation_dto.dart';

class InvitationController {
  final InvitationApi invitationApi;

  InvitationController(this.invitationApi);

  Future<InvitationDto> createInvitation({
    int? patientDni,
    String? patientEmail,
  }) {
    return invitationApi.createInvitation(
      dto: CreateInvitationDto(
        patientDni: patientDni,
        patientEmail: patientEmail,
      ),
    );
  }

  Future<List<InvitationDto>> getMyDoctorInvitations() {
    return invitationApi.getMyDoctorInvitations();
  }

  Future<List<InvitationDto>> getMyPatientInvitations({
    String? email,
    int? dni,
  }) {
    return invitationApi.getMyPatientInvitations(email: email, dni: dni);
  }

  Future<InvitationDto> acceptInvitation(String invitationId) {
    return invitationApi.acceptInvitation(invitationId);
  }

  Future<InvitationDto> rejectInvitation(String invitationId) {
    return invitationApi.rejectInvitation(invitationId);
  }
}
