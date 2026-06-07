import 'package:flutter/material.dart';

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
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (hasObservations)
          Icon(Icons.sticky_note_2_outlined, size: 18, color: scheme.primary),
        _MetaPill(label: 'Cambios: $changesCount'),
        _MetaPill(label: 'Total: ${_signed(totalMl)} ml', strong: true),
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
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
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
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
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
  final bool strong;

  const _MetaPill({required this.label, this.strong = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
