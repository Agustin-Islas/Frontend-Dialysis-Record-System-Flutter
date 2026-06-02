import 'package:flutter/material.dart';
import 'package:frontend_dialysis_record/features/sessions/models/session_dto.dart';

class MonthlyUltrafiltrationSummary {
  final int totalChanges;
  final List<int> weeklyUltrafiltration;
  final List<int> weekDayCounts;

  const MonthlyUltrafiltrationSummary({
    required this.totalChanges,
    required this.weeklyUltrafiltration,
    required this.weekDayCounts,
  });

  factory MonthlyUltrafiltrationSummary.empty(DateTime month) {
    return const MonthlyUltrafiltrationSummary(
      totalChanges: 0,
      weeklyUltrafiltration: [0, 0, 0, 0],
      weekDayCounts: [7, 7, 7, 7],
    );
  }
}

class MonthlyUltrafiltrationCalculator {
  static MonthlyUltrafiltrationSummary calculate({
    required DateTime month,
    required List<SessionDto> sessions,
  }) {
    final monthStart = DateUtils.dateOnly(DateTime(month.year, month.month, 1));
    final monthEnd = DateUtils.dateOnly(DateTime(month.year, month.month + 1, 0));
    final weekDayCounts = <int>[7, 7, 7, monthEnd.day - 21];
    final weekTotals = List<int>.filled(4, 0);
    var totalChanges = 0;

    for (final session in sessions) {
      final dateValue = session.date;
      if (dateValue == null) continue;
      final date = DateTime.tryParse(dateValue);
      if (date == null) continue;

      final day = DateUtils.dateOnly(date);
      if (day.isBefore(monthStart) || day.isAfter(monthEnd)) continue;

      totalChanges++;
      final weekIndex = day.day <= 7
          ? 0
          : day.day <= 14
              ? 1
              : day.day <= 21
                  ? 2
                  : 3;
      if (weekIndex < 0 || weekIndex > 3) continue;
      weekTotals[weekIndex] += session.partial ?? ((session.infusion ?? 0) - (session.drainage ?? 0));
    }

    return MonthlyUltrafiltrationSummary(
      totalChanges: totalChanges,
      weeklyUltrafiltration: List.generate(
        4,
        (index) => (weekTotals[index] / weekDayCounts[index]).round(),
        growable: false,
      ),
      weekDayCounts: weekDayCounts,
    );
  }
}
