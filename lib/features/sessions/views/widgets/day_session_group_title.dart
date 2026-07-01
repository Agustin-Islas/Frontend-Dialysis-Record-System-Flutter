import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:frontend_dialysis_record/core/design/design.dart';

class DaySessionGroupTitle extends StatelessWidget {
  final String dayTitle;
  final int changesCount;
  final int totalMl;
  final bool hasObservations;

  const DaySessionGroupTitle({
    super.key,
    required this.dayTitle,
    required this.changesCount,
    required this.totalMl,
    required this.hasObservations,
  });

  String _signed(int value) => value > 0 ? '+$value' : value.toString();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final meta = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (hasObservations)
          Icon(PhosphorIconsRegular.note, size: 18, color: scheme.primary),
        _MetaPill(label: 'Cambios: $changesCount', icon: PhosphorIconsRegular.arrowsClockwise),
        _MetaPill(label: 'Total: ${_signed(totalMl)} ml', icon: PhosphorIconsRegular.drop, strong: true),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 460) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dayTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.sm),
              meta,
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: Text(
                dayTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Flexible(
              child: Align(alignment: Alignment.centerRight, child: meta),
            ),
          ],
        );
      },
    );
  }
}

class _MetaPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool strong;

  const _MetaPill({required this.label, this.icon, this.strong = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: scheme.primary),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
