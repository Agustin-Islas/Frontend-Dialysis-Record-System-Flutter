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
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: ExpansionTile(
        shape: const Border(), // Removes top/bottom border when expanded
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                PhosphorIconsRegular.clock,
                color: scheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 4,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (session.isNightShift)
                    Tooltip(
                      message: 'Registrado el ${_formatDate(session.date)} a las $title',
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.amber.shade700,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              PhosphorIconsRegular.moon,
                              size: 12,
                              color: Colors.amber.shade800,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Noche',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (hasObservation)
                    Icon(
                      PhosphorIconsRegular.note,
                      size: 16,
                      color: scheme.primary,
                    ),
                ],
              ),
            ),
          ],
        ),
        trailing: _BalancePill(balance: partial),
        children: [
          if (session.isNightShift) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    PhosphorIconsRegular.moon,
                    size: 16,
                    color: Colors.amber.shade800,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cambio nocturno registrado el ${_formatDate(session.date)} después de medianoche, asignado a esta jornada clínica.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          _DetailRow(label: 'Bolsa', value: _bag(session.bag)),
          _DetailRow(
            label: 'Concentracion',
            value: _conc(session.concentration),
          ),
          const Divider(height: 20),
          _DetailRow(label: 'Drenaje', value: _ml(session.drainage)),
          _DetailRow(label: 'Infusion', value: _ml(session.infusion)),
          _DetailRow(label: 'Parcial', value: _ml(session.partial)),
          if ((session.observations ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Observaciones',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(session.observations!),
            ),
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

  String _bag(int? bag) => bag == null ? '-' : '$bag';

  String _conc(double? c) {
    if (c == null) return '-';
    final isInt = c % 1 == 0;
    return isInt
        ? '${c.toInt()}%'
        : '${c.toStringAsFixed(1).replaceAll('.', ',')}%';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final parts = dateStr.split(RegExp(r'[-/]'));
    if (parts.length == 3 && parts[0].length == 4) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }
    return dateStr;
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
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Parcial: $text ml',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: scheme.onSurfaceVariant,
        ),
      ),
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
            child: Text(
              label,
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
