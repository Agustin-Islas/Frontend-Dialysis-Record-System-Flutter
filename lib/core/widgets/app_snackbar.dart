import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:frontend_dialysis_record/core/design/design.dart';

/// Semantic SnackBar helpers with consistent styling.
///
/// Uses color to communicate state type (Principio 10):
/// - success → green
/// - error → red
/// - info → blue
/// - warning → amber
abstract final class AppSnackBar {
  static void success(BuildContext context, String message) {
    _show(context, message, AppColors.success, AppColors.onSuccess, PhosphorIconsRegular.checkCircle);
  }

  static void error(BuildContext context, String message) {
    _show(context, message, AppColors.error, AppColors.onError, PhosphorIconsRegular.warningCircle);
  }

  static void info(BuildContext context, String message) {
    _show(context, message, AppColors.info, AppColors.onInfo, PhosphorIconsRegular.info);
  }

  static void warning(BuildContext context, String message) {
    _show(context, message, AppColors.warning, AppColors.onWarning, PhosphorIconsRegular.warning);
  }

  static void _show(
    BuildContext context,
    String message,
    Color backgroundColor,
    Color foregroundColor,
    IconData icon,
  ) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          backgroundColor: backgroundColor,
          content: Row(
            children: [
              Icon(icon, color: foregroundColor, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: foregroundColor, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );
  }
}
