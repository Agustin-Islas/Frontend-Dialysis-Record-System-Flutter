class SessionSummary {
  final int sessionsCount;
  final int totalInfusion;
  final int totalDrainage;
  final int totalBalance;

  const SessionSummary({
    required this.sessionsCount,
    required this.totalInfusion,
    required this.totalDrainage,
    required this.totalBalance,
  });

  factory SessionSummary.empty() {
    return const SessionSummary(
      sessionsCount: 0,
      totalInfusion: 0,
      totalDrainage: 0,
      totalBalance: 0,
    );
  }

  factory SessionSummary.fromJson(Map<String, dynamic> json) {
    return SessionSummary(
      sessionsCount: _toInt(json['sessionsCount']),
      totalInfusion: _toInt(json['totalInfusion']),
      totalDrainage: _toInt(json['totalDrainage']),
      totalBalance: _toInt(json['totalBalance']),
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}
