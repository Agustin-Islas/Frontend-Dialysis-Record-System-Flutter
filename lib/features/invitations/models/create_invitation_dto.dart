class CreateInvitationDto {
  final int? patientDni;
  final String? patientEmail;

  CreateInvitationDto({this.patientDni, this.patientEmail});

  Map<String, dynamic> toJson() {
    return {'patientDni': patientDni, 'patientEmail': patientEmail};
  }
}
