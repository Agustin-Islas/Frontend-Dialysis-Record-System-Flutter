import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Animation constants and helpers for the design system.
///
/// All animations follow the medical UI guidelines:
/// - Duration: 150–250ms
/// - Subtle effects only (fade, scale, slide)
/// - Never distracting or blocking
abstract final class AppAnimations {
  // ── Durations ──────────────────────────────────────────────────────────
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 250);

  // ── Curves ─────────────────────────────────────────────────────────────
  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve enterCurve = Curves.easeOut;
  static const Curve exitCurve = Curves.easeIn;

  // ── Stagger delay for lists ────────────────────────────────────────────
  static const Duration staggerDelay = Duration(milliseconds: 50);
}

/// Extension on Widget for standard entry animations.
///
/// Usage:
/// ```dart
/// MyCard().withEntryAnimation(delay: 100.ms)
/// ```
extension AppAnimateExtension on Widget {
  /// Standard fade + slide-up entry animation for cards and list items.
  Widget withEntryAnimation({Duration? delay}) {
    return animate(delay: delay)
        .fadeIn(
          duration: AppAnimations.normal,
          curve: AppAnimations.defaultCurve,
        )
        .slideY(
          begin: 0.02,
          end: 0,
          duration: AppAnimations.normal,
          curve: AppAnimations.defaultCurve,
        );
  }

  /// Subtle scale animation for interactive elements on appear.
  Widget withScaleAnimation({Duration? delay}) {
    return animate(delay: delay)
        .fadeIn(
          duration: AppAnimations.fast,
          curve: AppAnimations.defaultCurve,
        )
        .scale(
          begin: const Offset(0.96, 0.96),
          end: const Offset(1, 1),
          duration: AppAnimations.normal,
          curve: AppAnimations.defaultCurve,
        );
  }
}
