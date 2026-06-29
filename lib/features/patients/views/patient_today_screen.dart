import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:frontend_dialysis_record/core/design/design.dart';
import 'package:frontend_dialysis_record/core/providers/providers.dart';
import 'package:frontend_dialysis_record/core/widgets/widgets.dart';
import 'package:frontend_dialysis_record/core/network/app_exception.dart';
import 'package:frontend_dialysis_record/features/auth/providers/auth_providers.dart';
import 'package:frontend_dialysis_record/features/patients/views/widgets/session_expansion_card.dart';
import 'package:frontend_dialysis_record/features/sessions/models/session_dto.dart';
import 'package:frontend_dialysis_record/features/sessions/models/session_summary.dart';
import 'package:frontend_dialysis_record/features/sessions/views/session_create_bottom_sheet.dart';

final GlobalKey<PatientTodayScreenState> patientTodayKey = GlobalKey<PatientTodayScreenState>();

class PatientTodayScreen extends ConsumerStatefulWidget {
  PatientTodayScreen() : super(key: patientTodayKey);

  @override
  ConsumerState<PatientTodayScreen> createState() => PatientTodayScreenState();
}

class PatientTodayScreenState extends ConsumerState<PatientTodayScreen> {
  final PageController _pageController = PageController();
  final DateFormat _longDateFormat = DateFormat('EEEE d/MM', 'es');
  final DateFormat _shortDateFormat = DateFormat('dd/MM');
  final DateFormat _heroDateFormat = DateFormat('EEEE dd/MM', 'es');
  int _daysAgo = 0;

  DateTime get _selectedDate {
    final today = DateUtils.dateOnly(DateTime.now());
    return today.subtract(Duration(days: _daysAgo));
  }

  Future<void> openCreateSession() =>
      _openSessionForm(initialDate: _selectedDate);

  Future<_DayData> _loadDay(DateTime day) async {
    final me = ref.read(authStateProvider).valueOrNull;
    final patientId = me?.id;
    if (patientId == null) return _DayData.empty();

    final patientCtrl = ref.read(patientControllerProvider);
    final results = await Future.wait([
      patientCtrl.getSessionsByDay(patientId: patientId, day: day),
      patientCtrl.getSessionSummaryByDay(patientId: patientId, day: day),
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
      duration: AppAnimations.slow,
      curve: AppAnimations.defaultCurve,
    );
  }

  Future<void> _openSessionForm({
    required DateTime initialDate,
    SessionDto? session,
  }) async {
    final me = ref.read(authStateProvider).valueOrNull;
    final patientId = me?.id;
    if (patientId == null) {
      AppSnackBar.error(context, 'No hay patientId en /me');
      return;
    }

    final patientCtrl = ref.read(patientControllerProvider);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SessionCreateBottomSheet(
        initialDate: initialDate,
        initialSession: session,
        customConcentrations: me?.customConcentrations ?? [],
        onSubmit: (data) async {
          try {
            if (session == null) {
              await patientCtrl.createSession(
                patientId: patientId,
                date: data.date,
                hour: data.hour,
                bag: data.bag,
                concentration: data.concentration,
                infusion: data.infusion,
                drainage: data.drainage,
                observations: data.observations,
              );
              if (mounted) AppSnackBar.success(context, 'Cambio creado');
            } else {
              await patientCtrl.updateSession(
                sessionId: session.id!,
                date: data.date,
                hour: data.hour,
                bag: data.bag,
                concentration: data.concentration,
                infusion: data.infusion,
                drainage: data.drainage,
                observations: data.observations,
              );
              if (mounted) AppSnackBar.success(context, 'Cambio actualizado');
            }
            _refresh();
          } catch (e) {
            final message = e is AppException
                ? e.message
                : 'No se pudo guardar el cambio.';
            if (mounted) AppSnackBar.error(context, message);
            rethrow;
          }
        },
      ),
    );
  }

  Future<void> _deleteSession(SessionDto session) async {
    if (session.id == null) return;
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Eliminar cambio',
      message: 'Esta acción eliminará el registro seleccionado.',
      confirmLabel: 'Eliminar',
    );
    if (!confirmed) return;

    try {
      final patientCtrl = ref.read(patientControllerProvider);
      await patientCtrl.deleteSession(sessionId: session.id!);
      if (mounted) AppSnackBar.success(context, 'Cambio eliminado');
      _refresh();
    } catch (e) {
      final message = e is AppException
          ? e.message
          : 'No se pudo eliminar el cambio.';
      if (mounted) AppSnackBar.error(context, message);
    }
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
    final me = ref.watch(authStateProvider).valueOrNull;

    return SafeArea(
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _daysAgo = index),
        itemBuilder: (context, index) {
          final day = DateUtils.dateOnly(
            DateTime.now(),
          ).subtract(Duration(days: index));
          return FutureBuilder<_DayData>(
            key: ValueKey('$index-${day.toIso8601String()}'),
            future: _loadDay(day),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppSkeletonScreen(title: 'Hoy', itemCount: 3);
              }

              if (snapshot.hasError) {
                return AppErrorCard(
                  message: 'No se pudieron cargar los cambios.',
                  details: snapshot.error.toString(),
                  onRetry: _refresh,
                );
              }

              final data = snapshot.data ?? _DayData.empty();
              final sessions = [...data.sessions]
                ..sort((a, b) => (a.bag ?? 999).compareTo(b.bag ?? 999));

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      _GreetingHeader(name: me?.name),
                      const SizedBox(height: AppSpacing.md),
                      _DayHero(
                        title: _capitalize(_heroDateFormat.format(day)),
                        canGoForward: index > 0,
                        onPrevious: () => _goToDay(index + 1),
                        onNext: index == 0 ? null : () => _goToDay(index - 1),
                        onToday: index == 0 ? null : () => _goToDay(0),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _DayStrip(
                        selectedDaysAgo: index,
                        shortDateFormat: _shortDateFormat,
                        titleFor: _titleFor,
                        onSelected: _goToDay,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _DaySummaryCard(summary: data.summary).withEntryAnimation(),
                      const SizedBox(height: AppSpacing.md),
                      if (sessions.isEmpty)
                        AppEmptyState(
                          message: 'No hay cambios registrados para ${_titleFor(day).toLowerCase()}.',
                          icon: PhosphorIconsRegular.noteBlank,
                        )
                      else
                        ...sessions.asMap().entries.map(
                          (entry) => SessionExpansionCard(
                            session: entry.value,
                            onEdit: entry.value.id == null
                                ? null
                                : () => _openSessionForm(
                                    initialDate: day,
                                    session: entry.value,
                                  ),
                            onDelete: entry.value.id == null
                                ? null
                                : () => _deleteSession(entry.value),
                          ).withEntryAnimation(
                            delay: Duration(milliseconds: 50 * entry.key),
                          ),
                        ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  final String? name;

  const _GreetingHeader({required this.name});

  @override
  Widget build(BuildContext context) {
    final displayName = (name ?? '').trim();
    return Text(
      displayName.isEmpty ? 'Hola!' : 'Hola $displayName!',
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
      ),
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
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
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
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                tooltip: 'Día anterior',
                onPressed: onPrevious,
                icon: const Icon(PhosphorIconsRegular.caretLeft),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.filledTonal(
                tooltip: 'Volver a hoy',
                onPressed: onToday,
                icon: const Icon(PhosphorIconsRegular.calendarBlank),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.filledTonal(
                tooltip: canGoForward ? 'Día siguiente' : 'No hay días futuros',
                onPressed: onNext,
                icon: const Icon(PhosphorIconsRegular.caretRight),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Desliza o usa los días para revisar registros anteriores.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onPrimaryContainer.withValues(alpha: 0.72),
            ),
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
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    shortDateFormat.format(day),
                    style: const TextStyle(fontSize: 11),
                  ),
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
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 2.4,
      children: [
        _MetricTile(
          label: 'Cambios',
          value: summary.sessionsCount.toString(),
          icon: PhosphorIconsRegular.notepad,
        ),
        _MetricTile(
          label: 'Total del día',
          value: '${summary.totalBalance} ml',
          icon: PhosphorIconsRegular.scales,
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
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

class _DayData {
  final List<SessionDto> sessions;
  final SessionSummary summary;

  const _DayData({required this.sessions, required this.summary});

  factory _DayData.empty() {
    return _DayData(sessions: const [], summary: SessionSummary.empty());
  }
}
