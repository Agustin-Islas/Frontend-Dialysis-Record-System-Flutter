import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:frontend_dialysis_record/core/design/design.dart';

/// Reusable confirmation dialog for destructive actions.
///
/// Implements design principle #12: prevent errors by confirming
/// destructive actions before executing them.
class AppConfirmDialog extends StatelessWidget {
  /// Dialog title.
  final String title;

  /// Descriptive message about the action.
  final String message;

  /// Text for the confirm button. Defaults to 'Confirmar'.
  final String confirmLabel;

  /// Text for the cancel button. Defaults to 'Cancelar'.
  final String cancelLabel;

  /// Whether this is a destructive action (shows red confirm button).
  final bool destructive;

  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirmar',
    this.cancelLabel = 'Cancelar',
    this.destructive = true,
  });

  /// Show the dialog and return `true` if confirmed.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirmar',
    String cancelLabel = 'Cancelar',
    bool destructive = true,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AppConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        destructive: destructive,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      icon: Icon(
        destructive
            ? PhosphorIconsRegular.warning
            : PhosphorIconsRegular.question,
        color: destructive ? scheme.error : scheme.primary,
        size: 32,
      ),
      title: Text(title),
      content: Text(
        message,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                )
              : null,
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
