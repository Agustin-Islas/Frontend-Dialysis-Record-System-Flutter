class SessionDto {
  final String? id;

  final String? date;
  final String? hour;
  final String? clinicalDate;

  final int? bag;

  final double? concentration;
  final int? drainage;
  final int? infusion;
  final int? partial;

  final String? observations;
  final int? severityLevel;

  final String? patientName;
  final String? patientId;

  SessionDto({
    this.id,
    this.date,
    this.hour,
    this.clinicalDate,
    this.bag,
    this.concentration,
    this.drainage,
    this.infusion,
    this.partial,
    this.observations,
    this.severityLevel,
    this.patientName,
    this.patientId,
  });

  String? get effectiveDate => clinicalDate ?? date;

  bool get isNightShift =>
      date != null && clinicalDate != null && date != clinicalDate;

  factory SessionDto.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is double) return v.toInt();
      return int.tryParse(v.toString());
    }

    double? toDouble(dynamic v) {
      if (v == null) return null;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return SessionDto(
      id: json['id']?.toString(),
      date: json['date']?.toString(),
      hour: json['hour']?.toString(),
      clinicalDate: json['clinicalDate']?.toString(),
      bag: toInt(json['bag']),
      concentration: toDouble(json['concentration']),
      drainage: toInt(json['drainage']),
      infusion: toInt(json['infusion']),
      partial: toInt(json['partial']),
      observations: json['observations']?.toString(),
      severityLevel: toInt(json['severityLevel']),
      patientName: json['patientName']?.toString(),
      patientId: json['patientId']?.toString(),
    );
  }
}
