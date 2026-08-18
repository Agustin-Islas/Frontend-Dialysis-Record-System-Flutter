import 'package:flutter/material.dart';
import 'package:frontend_dialysis_record/features/sessions/models/session_dto.dart';

class MonthlyUltrafiltrationSummary {
  final int totalChanges;
  final List<int> weeklyUltrafiltration;
  final List<int> weekDayCounts;
  final int elapsedDays;

  const MonthlyUltrafiltrationSummary({
    required this.totalChanges,
    required this.weeklyUltrafiltration,
    required this.weekDayCounts,
    required this.elapsedDays,
  });

  factory MonthlyUltrafiltrationSummary.empty(DateTime month) {
    final monthStart = DateUtils.dateOnly(DateTime(month.year, month.month, 1));
    final monthEnd = DateUtils.dateOnly(
      DateTime(month.year, month.month + 1, 0),
    );
    final now = DateUtils.dateOnly(DateTime.now());

    int elapsed;
    if (now.isBefore(monthStart)) {
      elapsed = 0;
    } else if (now.isAfter(monthEnd)) {
      elapsed = monthEnd.day;
    } else {
      elapsed = now.day - 1;
    }

    return MonthlyUltrafiltrationSummary(
      totalChanges: 0,
      weeklyUltrafiltration: [0, 0, 0, 0],
      weekDayCounts: [7, 7, 7, monthEnd.day - 21],
      elapsedDays: elapsed,
    );
  }
}

class MonthlyUltrafiltrationCalculator {
  static MonthlyUltrafiltrationSummary calculate({
    required DateTime month,
    required List<SessionDto> sessions,
  }) {
    final monthStart = DateUtils.dateOnly(DateTime(month.year, month.month, 1));
    final monthEnd = DateUtils.dateOnly(
      DateTime(month.year, month.month + 1, 0),
    );

    final nowDateTime = DateTime.now();
    final currentClinicalDate = nowDateTime.hour < 5
        ? DateUtils.dateOnly(nowDateTime.subtract(const Duration(days: 1)))
        : DateUtils.dateOnly(nowDateTime);

    final actualWeekDayCounts = List<int>.filled(4, 0);
    for (int i = 1; i <= monthEnd.day; i++) {
      final currentDay = monthStart.add(Duration(days: i - 1));
      if (!currentDay.isBefore(currentClinicalDate)) break;

      final weekIndex = i <= 7
          ? 0
          : i <= 14
          ? 1
          : i <= 21
          ? 2
          : 3;
      actualWeekDayCounts[weekIndex]++;
    }
    for (int i = 0; i < 4; i++) {
      if (actualWeekDayCounts[i] == 0) {
        actualWeekDayCounts[i] = 1; // Prevent division by zero
      }
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

      if (day.isBefore(monthStart) || day.isAfter(monthEnd)) continue;

      if (!day.isBefore(currentClinicalDate)) continue;

      totalChanges++;
      final weekIndex = day.day <= 7
          ? 0
          : day.day <= 14
          ? 1
          : day.day <= 21
          ? 2
          : 3;
      if (weekIndex < 0 || weekIndex > 3) continue;
      weekTotals[weekIndex] +=
          session.partial ??
          ((session.infusion ?? 0) - (session.drainage ?? 0));
    }

    int elapsedDays;
    if (currentClinicalDate.isBefore(monthStart)) {
      elapsedDays = 0;
    } else if (currentClinicalDate.isAfter(monthEnd)) {
      elapsedDays = monthEnd.day;
    } else {
      elapsedDays = currentClinicalDate.day - 1;
    }

    return MonthlyUltrafiltrationSummary(
      totalChanges: totalChanges,
      weeklyUltrafiltration: List.generate(
        4,
        (index) => (weekTotals[index] / actualWeekDayCounts[index]).round(),
        growable: false,
      ),
      weekDayCounts: actualWeekDayCounts,
      elapsedDays: elapsedDays,
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
