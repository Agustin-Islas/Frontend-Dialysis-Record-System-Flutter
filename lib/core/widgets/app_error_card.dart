import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:frontend_dialysis_record/core/design/design.dart';

/// Unified error state card used across all screens.
///
/// Replaces the duplicated `_ErrorState`, `_HistoryErrorState`,
/// and `_StateCard` widgets with a single consistent component.
class AppErrorCard extends StatelessWidget {
  /// Primary error message.
  final String message;

  /// Optional technical details (shown in smaller text).
  final String? details;

  /// Optional retry callback.
  final VoidCallback? onRetry;

  /// Optional custom icon. Defaults to warning circle.
  final IconData? icon;

  const AppErrorCard({
    super.key,
    required this.message,
    this.details,
    this.onRetry,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon ?? PhosphorIconsRegular.warningCircle,
                    size: 40,
                    color: scheme.error,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (details != null && details!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      details!,
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (onRetry != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(PhosphorIconsRegular.arrowClockwise),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
