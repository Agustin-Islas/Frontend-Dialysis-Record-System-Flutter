import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
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
  final Map<int, _DayData> _dayDataCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _preloadDays());
  }

  Future<void> _preloadDays() async {
    final me = ref.read(authStateProvider).valueOrNull;
    if (me?.id == null) return;
    
    for (int i = 0; i < 5; i++) {
      final day = DateUtils.dateOnly(DateTime.now()).subtract(Duration(days: i));
      _loadDay(day, index: i).then((data) {
        if (mounted) setState(() => _dayDataCache[i] = data);
      });
    }
  }

  DateTime get _selectedDate {
    final today = DateUtils.dateOnly(DateTime.now());
    return today.subtract(Duration(days: _daysAgo));
  }

  Future<void> openCreateSession() =>
      _openSessionForm(initialDate: _selectedDate);

  Future<_DayData> _loadDay(DateTime day, {int? index}) async {
    final me = ref.read(authStateProvider).valueOrNull;
    final patientId = me?.id;
    if (patientId == null) return _DayData.empty();

    final patientCtrl = ref.read(patientControllerProvider);
    final results = await Future.wait([
      patientCtrl.getSessionsByDay(patientId: patientId, day: day),
      patientCtrl.getSessionSummaryByDay(patientId: patientId, day: day),
    ]);

    final data = _DayData(
      sessions: results[0] as List<SessionDto>,
      summary: results[1] as SessionSummary,
    );
    
    if (index != null && mounted) {
      _dayDataCache[index] = data;
    }
    
    return data;
  }

  void _refresh() {
    _dayDataCache.clear();
    _preloadDays();
    setState(() {});
  }

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
    final format = DateFormat('EEEE', 'es');
    final text = format.format(day);
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
        itemCount: 5,
        reverse: true,
        controller: _pageController,
        onPageChanged: (index) => setState(() => _daysAgo = index),
        itemBuilder: (context, index) {
          final day = DateUtils.dateOnly(
            DateTime.now(),
          ).subtract(Duration(days: index));
          return FutureBuilder<_DayData>(
            key: ValueKey('$index-${day.toIso8601String()}'),
            initialData: _dayDataCache[index],
            future: _loadDay(day, index: index),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
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
    final scheme = Theme.of(context).colorScheme;
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Buenos días' : hour < 19 ? 'Buenas tardes' : 'Buenas noches';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            Text(
              displayName.isEmpty ? 'Usuario' : displayName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.primary,
              ),
            ),
          ],
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: scheme.onPrimaryContainer.withValues(alpha: 0.1),
                  foregroundColor: scheme.onPrimaryContainer,
                ),
                tooltip: 'Día anterior',
                onPressed: onPrevious,
                icon: const Icon(PhosphorIconsBold.caretLeft),
              ),
              const SizedBox(width: AppSpacing.md),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.onPrimaryContainer,
                  foregroundColor: scheme.primaryContainer,
                  elevation: 0,
                ),
                onPressed: onToday,
                icon: const Icon(PhosphorIconsBold.calendarBlank),
                label: const Text('Volver a hoy', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: AppSpacing.md),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: scheme.onPrimaryContainer.withValues(alpha: 0.1),
                  foregroundColor: scheme.onPrimaryContainer,
                ),
                tooltip: canGoForward ? 'Día siguiente' : 'No hay días futuros',
                onPressed: onNext,
                icon: const Icon(PhosphorIconsBold.caretRight),
              ),
            ],
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
    final scheme = Theme.of(context).colorScheme;
    
    return SizedBox(
      height: 68,
      child: ListView.separated(
        reverse: true, // This puts index 0 on the far right
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final day = today.subtract(Duration(days: index));
          final isSelected = index == selectedDaysAgo;
          
          return InkWell(
            onTap: () => onSelected(index),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: AppAnimations.fast,
              width: 90,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? scheme.primary : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? [BoxShadow(color: scheme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    titleFor(day),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: isSelected ? scheme.onPrimary : scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    shortDateFormat.format(day),
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? scheme.onPrimary.withValues(alpha: 0.8) : scheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
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
