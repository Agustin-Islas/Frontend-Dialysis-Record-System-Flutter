import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:frontend_dialysis_record/features/sessions/models/session_dto.dart';
import 'package:frontend_dialysis_record/core/design/design.dart';

class SessionExpansionCard extends StatelessWidget {
  final SessionDto session;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const SessionExpansionCard({
    super.key,
    required this.session,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = _formatHour(session.hour);
    final partial = session.partial ?? 0;
    final hasObservation = (session.observations ?? '').trim().isNotEmpty;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(PhosphorIconsRegular.clock, color: scheme.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Row(
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  if (hasObservation) ...[
                    const SizedBox(width: 8),
                    Icon(PhosphorIconsRegular.note, size: 16, color: scheme.primary),
                  ],
                ],
              ),
            ),
          ],
        ),
        trailing: _BalancePill(balance: partial),
        children: [
          const SizedBox(height: 8),
          _DetailRow(label: 'Bolsa', value: _bag(session.bag)),
          _DetailRow(label: 'Concentracion', value: _conc(session.concentration)),
          const Divider(height: 20),
          _DetailRow(label: 'Drenaje', value: _ml(session.drainage)),
          _DetailRow(label: 'Infusion', value: _ml(session.infusion)),
          _DetailRow(label: 'Parcial', value: _ml(session.partial)),
          if ((session.observations ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Observaciones', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Align(alignment: Alignment.centerLeft, child: Text(session.observations!)),
          ],
          if (onEdit != null || onDelete != null) ...[
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onEdit != null)
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(PhosphorIconsRegular.pencilSimple),
                    label: const Text('Editar'),
                  ),
                if (onDelete != null)
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(PhosphorIconsRegular.trash),
                    label: const Text('Eliminar'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatHour(String? hour) {
    if (hour == null || hour.trim().isEmpty) return 'Cambio';
    return hour.length >= 5 ? hour.substring(0, 5) : hour;
  }

  String _ml(int? v) => v == null ? '-' : '$v ml';

  String _bag(int? bag) => bag == null ? '-' : 'Bolsa $bag';

  String _conc(double? c) {
    if (c == null) return '-';
    final isInt = c % 1 == 0;
    return isInt ? '${c.toInt()}%' : '${c.toStringAsFixed(1).replaceAll('.', ',')}%';
  }
}

class _BalancePill extends StatelessWidget {
  final int balance;

  const _BalancePill({required this.balance});

  @override
  Widget build(BuildContext context) {
    final text = balance >= 0 ? '+$balance' : '$balance';
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('Parcial: $text ml', style: TextStyle(fontWeight: FontWeight.w700, color: scheme.primary)),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: Theme.of(context).hintColor)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
