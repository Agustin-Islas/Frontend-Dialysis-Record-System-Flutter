import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend_dialysis_record/core/network/app_exception.dart';
import 'package:frontend_dialysis_record/features/auth/authController/auth_controller.dart';
import 'package:frontend_dialysis_record/features/auth/models/me_response.dart';
import 'package:frontend_dialysis_record/features/patients/patientController/patient_controller.dart';
import 'package:frontend_dialysis_record/features/patients/views/widgets/session_expansion_card.dart';
import 'package:frontend_dialysis_record/features/sessions/models/session_dto.dart';
import 'package:frontend_dialysis_record/features/sessions/models/session_summary.dart';
import 'package:frontend_dialysis_record/features/sessions/views/session_create_bottom_sheet.dart';

class PatientTodayScreen extends StatefulWidget {
  final MeResponse me;
  final AuthController authController;
  final PatientController patientController;

  const PatientTodayScreen({
    super.key,
    required this.me,
    required this.authController,
    required this.patientController,
  });

  @override
  State<PatientTodayScreen> createState() => PatientTodayScreenState();
}

class PatientTodayScreenState extends State<PatientTodayScreen> {
  final PageController _pageController = PageController();
  final DateFormat _longDateFormat = DateFormat('EEEE d/MM', 'es');
  final DateFormat _shortDateFormat = DateFormat('dd/MM');
  final DateFormat _heroDateFormat = DateFormat('EEEE dd/MM', 'es');
  int _daysAgo = 0;

  DateTime get _selectedDate {
    final today = DateUtils.dateOnly(DateTime.now());
    return today.subtract(Duration(days: _daysAgo));
  }

  Future<void> openCreateSession() => _openSessionForm(initialDate: _selectedDate);

  Future<_DayData> _loadDay(DateTime day) async {
    final patientId = widget.me.id;
    if (patientId == null) return _DayData.empty();

    final results = await Future.wait([
      widget.patientController.getSessionsByDay(patientId: patientId, day: day),
      widget.patientController.getSessionSummaryByDay(patientId: patientId, day: day),
    ]);

    return _DayData(
      sessions: results[0] as List<SessionDto>,
      summary: results[1] as SessionSummary,
    );
  }

  void _refresh() => setState(() {});

  void _goToDay(int daysAgo) {
    if (daysAgo < 0) return;
    _pageController.animateToPage(
      daysAgo,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _openSessionForm({
    required DateTime initialDate,
    SessionDto? session,
  }) async {
    final patientId = widget.me.id;
    if (patientId == null) {
      _showMessage('No hay patientId en /me');
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SessionCreateBottomSheet(
        initialDate: initialDate,
        initialSession: session,
        customConcentrations: widget.me.customConcentrations,
        onSubmit: (data) async {
          try {
            if (session == null) {
              await widget.patientController.createSession(
                patientId: patientId,
                date: data.date,
                hour: data.hour,
                bag: data.bag,
                concentration: data.concentration,
                infusion: data.infusion,
                drainage: data.drainage,
                observations: data.observations,
              );
              _showMessage('Cambio creado');
            } else {
              await widget.patientController.updateSession(
                sessionId: session.id!,
                date: data.date,
                hour: data.hour,
                bag: data.bag,
                concentration: data.concentration,
                infusion: data.infusion,
                drainage: data.drainage,
                observations: data.observations,
              );
              _showMessage('Cambio actualizado');
            }
            _refresh();
          } catch (e) {
            final message = e is AppException ? e.message : 'No se pudo guardar el cambio.';
            _showMessage(message);
            rethrow;
          }
        },
      ),
    );
  }

  Future<void> _deleteSession(SessionDto session) async {
    if (session.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cambio'),
        content: const Text('Esta accion eliminara el registro seleccionado.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.patientController.deleteSession(sessionId: session.id!);
      _showMessage('Cambio eliminado');
      _refresh();
    } catch (e) {
      final message = e is AppException ? e.message : 'No se pudo eliminar el cambio.';
      _showMessage(message);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _titleFor(DateTime day) {
    final today = DateUtils.dateOnly(DateTime.now());
    final diff = today.difference(DateUtils.dateOnly(day)).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    final text = _longDateFormat.format(day);
    return text[0].toUpperCase() + text.substring(1);
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _daysAgo = index),
        itemBuilder: (context, index) {
          final day = DateUtils.dateOnly(DateTime.now()).subtract(Duration(days: index));
          return FutureBuilder<_DayData>(
            key: ValueKey('$index-${day.toIso8601String()}'),
            future: _loadDay(day),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return _ErrorState(
                  message: 'No se pudieron cargar los cambios.',
                  details: snapshot.error.toString(),
                  onRetry: _refresh,
                );
              }

              final data = snapshot.data ?? _DayData.empty();
              final sessions = [...data.sessions]..sort((a, b) => (a.bag ?? 999).compareTo(b.bag ?? 999));

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _GreetingHeader(me: widget.me),
                  const SizedBox(height: 12),
                  _DayHero(
                    title: _capitalize(_heroDateFormat.format(day)),
                    canGoForward: index > 0,
                    onPrevious: () => _goToDay(index + 1),
                    onNext: index == 0 ? null : () => _goToDay(index - 1),
                    onToday: index == 0 ? null : () => _goToDay(0),
                  ),
                  const SizedBox(height: 12),
                  _DayStrip(
                    selectedDaysAgo: index,
                    shortDateFormat: _shortDateFormat,
                    titleFor: _titleFor,
                    onSelected: _goToDay,
                  ),
                  const SizedBox(height: 12),
                  _DaySummaryCard(summary: data.summary),
                  const SizedBox(height: 12),
                  if (sessions.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('No hay cambios registrados para ${_titleFor(day).toLowerCase()}.'),
                      ),
                    )
                  else
                    ...sessions.map(
                      (s) => SessionExpansionCard(
                        session: s,
                        onEdit: s.id == null ? null : () => _openSessionForm(initialDate: day, session: s),
                        onDelete: s.id == null ? null : () => _deleteSession(s),
                      ),
                    ),
                  const SizedBox(height: 100),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  final MeResponse me;

  const _GreetingHeader({required this.me});

  @override
  Widget build(BuildContext context) {
    final name = (me.name ?? '').trim();
    return Text(
      name.isEmpty ? 'Hola!' : 'Hola $name!',
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _DayHero extends StatelessWidget {
  final String title;
  final bool canGoForward;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onToday;

  const _DayHero({
    required this.title,
    required this.canGoForward,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                tooltip: 'Día anterior',
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Volver a hoy',
                onPressed: onToday,
                icon: const Icon(Icons.today_outlined),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: canGoForward ? 'Día siguiente' : 'No hay días futuros',
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Desliza o usa los días para revisar registros anteriores.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: scheme.onPrimaryContainer.withValues(alpha: 0.72)),
          ),
        ],
      ),
    );
  }
}

class _DayStrip extends StatelessWidget {
  final int selectedDaysAgo;
  final DateFormat shortDateFormat;
  final String Function(DateTime day) titleFor;
  final ValueChanged<int> onSelected;

  const _DayStrip({
    required this.selectedDaysAgo,
    required this.shortDateFormat,
    required this.titleFor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 15,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = today.subtract(Duration(days: index));
          return ChoiceChip(
            selected: index == selectedDaysAgo,
            onSelected: (_) => onSelected(index),
            label: SizedBox(
              width: 76,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    titleFor(day),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                  Text(shortDateFormat.format(day), style: const TextStyle(fontSize: 11)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DaySummaryCard extends StatelessWidget {
  final SessionSummary summary;

  const _DaySummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.4,
      children: [
        _MetricTile(label: 'Cambios', value: summary.sessionsCount.toString(), icon: Icons.event_note_outlined),
        _MetricTile(label: 'Total del día', value: '${summary.totalBalance} ml', icon: Icons.scale_outlined),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricTile({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor)),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final String details;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.details,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(details, maxLines: 4, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 12),
                FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DayData {
  final List<SessionDto> sessions;
  final SessionSummary summary;

  const _DayData({required this.sessions, required this.summary});

  factory _DayData.empty() {
    return _DayData(sessions: const [], summary: SessionSummary.empty());
  }
}
