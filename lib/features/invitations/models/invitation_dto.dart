class InvitationDto {
  final String id;
  final String doctorId;
  final String doctorName;
  final int? patientDni;
  final String? patientEmail;
  final String status;
  final String? createdAt;
  final String? expiresAt;

  InvitationDto({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    this.patientDni,
    this.patientEmail,
    required this.status,
    this.createdAt,
    this.expiresAt,
  });

  factory InvitationDto.fromJson(Map<String, dynamic> json) {
    return InvitationDto(
      id: json['id']?.toString() ?? '',
      doctorId: json['doctorId']?.toString() ?? '',
      doctorName: json['doctorName']?.toString() ?? '',
      patientDni: json['patientDni'] != null
          ? int.tryParse(json['patientDni'].toString())
          : null,
      patientEmail: json['patientEmail']?.toString(),
      status: json['status']?.toString() ?? 'PENDING',
      createdAt: json['createdAt']?.toString(),
      expiresAt: json['expiresAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'patientDni': patientDni,
      'patientEmail': patientEmail,
      'status': status,
      'createdAt': createdAt,
      'expiresAt': expiresAt,
    };
  }
}
