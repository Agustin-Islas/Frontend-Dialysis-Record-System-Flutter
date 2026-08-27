import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend_dialysis_record/features/sessions/models/session_dto.dart';

class ObservationsTimelinePanel extends StatelessWidget {
  final List<SessionDto> sessions;
  final ScrollController? scrollController;

  const ObservationsTimelinePanel({
    super.key,
    required this.sessions,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    // Filtrar sesiones que tengan observaciones
    final filteredSessions = sessions
        .where((s) => s.observations != null && s.observations!.trim().isNotEmpty)
        .toList();

    // Ordenar de más reciente a más antigua (usando date/hour si se pudiera parsear, 
    // asumiremos que la lista original ya viene ordenada o las listamos en el orden en que llegan, 
    // comúnmente invertido para ver recientes arriba)
    final displaySessions = filteredSessions.reversed.toList();

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Observaciones Clínicas',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: displaySessions.isEmpty
                ? const Center(
                    child: Text('No hay observaciones registradas.'),
                  )
                : ListView.builder(
                    controller: scrollController,
                    itemCount: displaySessions.length,
                    itemBuilder: (context, index) {
                      final session = displaySessions[index];
                      return _buildObservationCard(context, session);
                    },
                  ),
          ),
        ],
      );
  }

  Widget _buildObservationCard(BuildContext context, SessionDto session) {
    final severity = session.severityLevel ?? 3;
    Color severityColor;
    IconData severityIcon;

    switch (severity) {
      case 1:
        severityColor = Colors.redAccent;
        severityIcon = Icons.error_outline;
        break;
      case 2:
        severityColor = Colors.orangeAccent;
        severityIcon = Icons.warning_amber_rounded;
        break;
      case 3:
      default:
        severityColor = Colors.blueGrey;
        severityIcon = Icons.info_outline;
        break;
    }

    String displayDate = session.date ?? 'Fecha desconocida';
    if (session.date != null) {
      try {
        final parsed = DateTime.parse(session.date!);
        final formatted = DateFormat('EEEE dd/MM/yyyy', 'es').format(parsed);
        displayDate = formatted[0].toUpperCase() + formatted.substring(1);
      } catch (_) {}
    }

    String displayHour = session.hour ?? '-';
    if (displayHour.length > 5) {
      displayHour = displayHour.substring(0, 5);
    }

    final int partialValue = session.partial ?? 0;
    final bool isPositivePartial = partialValue > 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: severityColor.withValues(alpha: 0.5), width: 1),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(severityIcon, color: severityColor),
          title: Text(
            displayDate,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          subtitle: Text(
            session.observations ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  Text('Detalle del recambio', style: TextStyle(fontWeight: FontWeight.bold, color: severityColor)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildInfoCol(context, 'Hora', displayHour),
                      _buildInfoCol(context, 'Bolsa', 'N° ${session.bag ?? '-'}'),
                      _buildInfoCol(context, 'Concentración', '${session.concentration ?? '-'}%', alignment: CrossAxisAlignment.end),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildInfoCol(context, 'Infusión', '${session.infusion ?? '-'} ml'),
                      _buildInfoCol(context, 'Drenaje', '${session.drainage ?? '-'} ml'),
                      _buildInfoCol(context, 'Parcial', '${session.partial ?? '-'} ml',
                          alignment: CrossAxisAlignment.end,
                          valueColor: isPositivePartial ? Colors.redAccent : null),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCol(BuildContext context, String label, String value, {CrossAxisAlignment alignment = CrossAxisAlignment.start, Color? valueColor}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: valueColor ?? Theme.of(context).colorScheme.onSurface)),
        ],
      ),
    );
  }
}

void showObservationsPanel(BuildContext context, List<SessionDto> sessions) {
  final width = MediaQuery.of(context).size.width;
  if (width > 600) {
    // Drawer style for desktop/tablet
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            elevation: 16,
            child: SizedBox(
              width: 400,
              height: double.infinity,
              child: ObservationsTimelinePanel(sessions: sessions),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(animation),
          child: child,
        );
      },
    );
  } else {
    // Bottom sheet for mobile
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.60,
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Solo agregamos el drag handle si el tema no lo trae, pero para evitar doble handle,
              // usaremos el estilo nativo de la app. Como la imagen muestra que el nativo ya tiene
              // un drag handle transparente, simplemente devolvemos el panel.
              Expanded(
                child: ObservationsTimelinePanel(
                  sessions: sessions,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
