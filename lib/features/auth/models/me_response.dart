class MeResponse {
  final String? id;
  final String? email;
  final String? name;
  final String? surname;
  final String role;
  final String? dni;
  final String? dateOfBirth;
  final String? address;
  final String? number;
  final String? doctorName;
  final String? doctorId;
  final int? patientCount;
  final List<String> patientIds;
  final List<double> customConcentrations;

  MeResponse({
    required this.role,
    this.id,
    this.email,
    this.name,
    this.surname,
    this.dni,
    this.dateOfBirth,
    this.address,
    this.number,
    this.doctorName,
    this.doctorId,
    this.patientCount,
    this.patientIds = const [],
    this.customConcentrations = const [],
  });

  factory MeResponse.fromJson(Map<String, dynamic> json) {
    final rawPatientIds = json['patientIds'];
    final rawCustomConcentrations = json['customConcentrations'];
    return MeResponse(
      role: (json['role'] ?? '').toString(),
      id: json['id']?.toString(),
      email: json['email']?.toString(),
      name: json['name']?.toString(),
      surname: json['surname']?.toString(),
      dni: json['dni']?.toString(),
      dateOfBirth: json['dateOfBirth']?.toString(),
      address: json['address']?.toString(),
      number: json['number']?.toString(),
      doctorName: json['doctorName']?.toString(),
      doctorId: json['doctorId']?.toString(),
      patientCount: _toInt(json['patientCount']),
      patientIds: rawPatientIds is List
          ? rawPatientIds.map((e) => e.toString()).toList()
          : const [],
      customConcentrations: rawCustomConcentrations is List
          ? rawCustomConcentrations.map(_toDouble).whereType<double>().toList()
          : const [],
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
