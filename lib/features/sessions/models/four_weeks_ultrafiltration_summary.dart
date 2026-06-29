import 'package:flutter/material.dart';
import 'package:frontend_dialysis_record/features/sessions/models/session_dto.dart';

class FourWeeksUltrafiltrationSummary {
  final int totalChanges;
  final List<int> weeklyUltrafiltration;
  final List<int> weekDayCounts;
  final int elapsedDays;

  const FourWeeksUltrafiltrationSummary({
    required this.totalChanges,
    required this.weeklyUltrafiltration,
    required this.weekDayCounts,
    required this.elapsedDays,
  });

  factory FourWeeksUltrafiltrationSummary.empty() {
    return const FourWeeksUltrafiltrationSummary(
      totalChanges: 0,
      weeklyUltrafiltration: [0, 0, 0, 0],
      weekDayCounts: [7, 7, 7, 7],
      elapsedDays: 28,
    );
  }
}

class FourWeeksUltrafiltrationCalculator {
  static FourWeeksUltrafiltrationSummary calculate({
    required DateTime endDate,
    required List<SessionDto> sessions,
  }) {
    // endDate is today. startDate is today - 27 days.
    // Total exactly 28 days.
    final end = DateUtils.dateOnly(endDate);
    final start = end.subtract(const Duration(days: 27));
    final weekDayCounts = <int>[7, 7, 7, 7];
    final weekTotals = List<int>.filled(4, 0);
    var totalChanges = 0;

    for (final session in sessions) {
      final dateValue = session.date;
      if (dateValue == null) continue;
      final date = DateTime.tryParse(dateValue);
      if (date == null) continue;

      final day = DateUtils.dateOnly(date);
      if (day.isBefore(start) || day.isAfter(end)) continue;

      totalChanges++;
      
      // Calculate which week it falls into
      final differenceInDays = day.difference(start).inDays; // 0 to 27
      final weekIndex = differenceInDays ~/ 7; // 0, 1, 2, or 3

      if (weekIndex < 0 || weekIndex > 3) continue;
      
      weekTotals[weekIndex] += session.partial ?? ((session.infusion ?? 0) - (session.drainage ?? 0));
    }

    return FourWeeksUltrafiltrationSummary(
      totalChanges: totalChanges,
      weeklyUltrafiltration: List.generate(
        4,
        (index) => (weekTotals[index] / weekDayCounts[index]).round(),
        growable: false,
      ),
      weekDayCounts: weekDayCounts,
      elapsedDays: 28,
    );
  }
}
