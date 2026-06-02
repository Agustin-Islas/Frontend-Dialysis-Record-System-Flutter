class SessionCreateRequest {
  final String date; // yyyy-MM-dd
  final String hour; // HH:mm:ss
  final int? bag;
  final double? concentration;
  final int? infusion;
  final int? drainage;
  final String? observations;

  SessionCreateRequest({
    required this.date,
    required this.hour,
    this.bag,
    this.concentration,
    this.infusion,
    this.drainage,
    this.observations,
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'hour': hour,
        'bag': bag,
        'concentration': concentration,
        'infusion': infusion,
        'drainage': drainage,
        'observations': observations,
      };
}
