import 'package:flutter/material.dart';
import 'package:frontend_dialysis_record/core/design/design.dart';

/// Responsive layout wrapper that constrains content width
/// and applies consistent padding based on screen size.
///
/// Implements design principle #14: responsive design for
/// phones, tablets, and desktop.
class AppResponsiveLayout extends StatelessWidget {
  /// Content to display.
  final Widget child;

  /// Maximum content width. Defaults to 1040.
  final double maxWidth;

  /// Whether to wrap in SafeArea. Defaults to true.
  final bool useSafeArea;

  const AppResponsiveLayout({
    super.key,
    required this.child,
    this.maxWidth = 1040,
    this.useSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );

    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    return content;
  }

  /// Returns adaptive horizontal padding based on screen width.
  static double horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1200) return AppSpacing.xxxl;
    if (width >= 600) return AppSpacing.xxl;
    return AppSpacing.lg;
  }
}
