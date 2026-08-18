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
      elapsedDays: 27,
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

    final nowDateTime = DateTime.now();
    final currentClinicalDate = nowDateTime.hour < 5
        ? DateUtils.dateOnly(nowDateTime.subtract(const Duration(days: 1)))
        : DateUtils.dateOnly(nowDateTime);

    // Adjust weekDayCounts if the currentClinicalDate is within the 4-week window
    for (int i = 0; i <= 27; i++) {
      final currentDay = start.add(Duration(days: i));
      if (!currentDay.isBefore(currentClinicalDate)) {
        // If currentDay is today or in the future, it hasn't ended. Subtract it from its week.
        final weekIndex = i ~/ 7;
        if (weekIndex >= 0 && weekIndex < 4) {
          weekDayCounts[weekIndex]--;
        }
      }
    }
    // Prevent division by zero
    for (int i = 0; i < 4; i++) {
      if (weekDayCounts[i] == 0) weekDayCounts[i] = 1;
    }

    final weekTotals = List<int>.filled(4, 0);
    var totalChanges = 0;

    for (final session in sessions) {
      final dateValue = session.date;
      if (dateValue == null) continue;
      final date = _parseDate(dateValue);
      if (date == null) continue;

      var day = DateUtils.dateOnly(date);

      // Adjust for clinical date: post-midnight sessions belong to previous day
      final hourStr = session.hour;
      if (hourStr != null && hourStr.isNotEmpty) {
        final timeParts = hourStr.split(':');
        if (timeParts.isNotEmpty) {
          final h = int.tryParse(timeParts[0]);
          if (h != null && h < 5) {
            day = day.subtract(const Duration(days: 1));
          }
        }
      }

      if (day.isBefore(start) || day.isAfter(end)) continue;

      if (!day.isBefore(currentClinicalDate)) continue;

      totalChanges++;

      // Calculate which week it falls into
      final differenceInDays = day.difference(start).inDays; // 0 to 27
      final weekIndex = differenceInDays ~/ 7; // 0, 1, 2, or 3

      if (weekIndex < 0 || weekIndex > 3) continue;

      weekTotals[weekIndex] +=
          session.partial ??
          ((session.infusion ?? 0) - (session.drainage ?? 0));
    }

    return FourWeeksUltrafiltrationSummary(
      totalChanges: totalChanges,
      weeklyUltrafiltration: List.generate(
        4,
        (index) => (weekTotals[index] / weekDayCounts[index]).round(),
        growable: false,
      ),
      weekDayCounts: weekDayCounts,
      elapsedDays: weekDayCounts.fold(0, (sum, count) => sum + count),
    );
  }

  static DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    final iso = DateTime.tryParse(dateStr);
    if (iso != null) return iso;
    final parts = dateStr.split(RegExp(r'[/.-]'));
    if (parts.length == 3) {
      final d = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final y = int.tryParse(parts[2]);
      if (d != null && m != null && y != null) {
        if (y > 1000 && m >= 1 && m <= 12 && d >= 1 && d <= 31) {
          return DateTime(y, m, d);
        }
        if (d > 1000 && m >= 1 && m <= 12 && y >= 1 && y <= 31) {
          return DateTime(d, m, y);
        }
      }
    }
    return null;
  }
}
