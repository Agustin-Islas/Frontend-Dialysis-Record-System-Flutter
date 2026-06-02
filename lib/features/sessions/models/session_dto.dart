
class SessionDto {
  final String? id;

  final String? date;

  final String? hour;

  final int? bag;

  final double? concentration;
  final int? drainage;
  final int? infusion;
  final int? partial;

  final String? observations;

  final String? patientName;
  final String? patientId;
  
  SessionDto({
    this.id,
    this.date,
    this.hour,
    this.bag,
    this.concentration,
    this.drainage,
    this.infusion,
    this.partial,
    this.observations,
    this.patientName,
    this.patientId,
  });

  factory SessionDto.fromJson(Map<String, dynamic> json) {
    int? _toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is double) return v.toInt();
      return int.tryParse(v.toString());
    }

    double? _toDouble(dynamic v) {
      if (v == null) return null;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return SessionDto(
      id: json['id']?.toString(),
      date: json['date']?.toString(),
      hour: json['hour']?.toString(),
      bag: _toInt(json['bag']),
      concentration: _toDouble(json['concentration']),
      drainage: _toInt(json['drainage']),
      infusion: _toInt(json['infusion']),
      partial: _toInt(json['partial']),
      observations: json['observations']?.toString(),
      patientName: json['patientName']?.toString(),
      patientId: json['patientId']?.toString(),
    );
  }
}
