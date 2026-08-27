import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:frontend_dialysis_record/core/design/design.dart';
import 'package:frontend_dialysis_record/core/providers/providers.dart';
import 'package:frontend_dialysis_record/core/widgets/widgets.dart';
import 'package:frontend_dialysis_record/features/auth/providers/auth_providers.dart';
import 'package:frontend_dialysis_record/features/patients/views/widgets/session_expansion_card.dart';
import 'package:frontend_dialysis_record/features/sessions/models/session_dto.dart';
import 'package:frontend_dialysis_record/features/sessions/models/session_summary.dart';
import 'package:frontend_dialysis_record/features/sessions/views/session_create_bottom_sheet.dart';

final GlobalKey<PatientTodayScreenState> patientTodayKey =
    GlobalKey<PatientTodayScreenState>();

class PatientTodayScreen extends ConsumerStatefulWidget {
  PatientTodayScreen() : super(key: patientTodayKey);

  @override
  ConsumerState<PatientTodayScreen> createState() => PatientTodayScreenState();
}

class PatientTodayScreenState extends ConsumerState<PatientTodayScreen> {
  final PageController _pageController = PageController();

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
      final day = DateUtils.dateOnly(
        DateTime.now(),
      ).subtract(Duration(days: i));
      _loadDay(day, index: i).then((data) {
        if (mounted) setState(() => _dayDataCache[i] = data);
      });
    }
  }

  DateTime get _selectedDate {
    final today = DateUtils.dateOnly(DateTime.now());
    return today.subtract(Duration(days: _daysAgo));
  }

  bool _isBottomSheetOpen = false;

  Future<void> openCreateSession() async {
    if (_isBottomSheetOpen) return;
    _isBottomSheetOpen = true;
    try {
      await _openSessionForm(
        initialDate: _selectedDate,
        existingSessions: _dayDataCache.values.expand((d) => d.sessions).toList(),
      );
    } finally {
      if (mounted) {
        _isBottomSheetOpen = false;
      }
    }
  }

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
    List<SessionDto> existingSessions = const [],
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
        existingSessions: existingSessions,
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
            if (mounted) {
              AppSnackBar.showException(
                context,
                e,
                'No se pudo guardar el cambio.',
              );
            }
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
      if (mounted) {
        AppSnackBar.showException(context, e, 'No se pudo eliminar el cambio.');
      }
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
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
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
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
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
                      _DaySummaryCard(
                        summary: data.summary,
                      ).withEntryAnimation(),
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Registros del día',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (sessions.isEmpty)
                        AppEmptyState(
                          message:
                              'No hay cambios registrados para ${_titleFor(day).toLowerCase()}.',
                          icon: PhosphorIconsRegular.noteBlank,
                        )
                      else
                        ...sessions.asMap().entries.map(
                          (entry) =>
                              SessionExpansionCard(
                                session: entry.value,
                                onEdit: entry.value.id == null
                                    ? null
                                    : () => _openSessionForm(
                                        initialDate: day,
                                        session: entry.value,
                                        existingSessions: _dayDataCache.values
                                            .expand((d) => d.sessions)
                                            .toList(),
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary,
            scheme.primary.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    PhosphorIconsRegular.calendarBlank,
                    color: scheme.onPrimary.withValues(alpha: 0.9),
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              if (onToday != null) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: onToday,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: scheme.onPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Volver a hoy',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          Positioned(
            left: 0,
            child: InkWell(
              onTap: onPrevious,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.onPrimary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  PhosphorIconsRegular.caretLeft,
                  color: scheme.onPrimary,
                  size: 20,
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            child: InkWell(
              onTap: onNext,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.onPrimary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  PhosphorIconsRegular.caretRight,
                  color: canGoForward
                      ? scheme.onPrimary
                      : scheme.onPrimary.withValues(alpha: 0.4),
                  size: 20,
                ),
              ),
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
    final scheme = Theme.of(context).colorScheme;

    Widget buildItem(int index, bool isRow) {
      final day = today.subtract(Duration(days: index));
      final isSelected = index == selectedDaysAgo;
      
      EdgeInsets padding;
      if (isRow) {
        // En vista centrada (Desktop/Tablet), iteramos 4..0.
        // Espaciado a la derecha, salvo el último (Hoy = 0)
        padding = EdgeInsets.only(right: index == 0 ? 0 : AppSpacing.sm);
      } else {
        // En móvil (ListView reverse: true), iteramos 0..4.
        // Espaciado a la izquierda, salvo el último visualmente a la izq (4).
        padding = EdgeInsets.only(
          left: index == 4 ? 0 : AppSpacing.sm, 
          right: index == 0 ? AppSpacing.lg : 0
        );
      }

      return Padding(
        padding: padding,
        child: InkWell(
          onTap: () => onSelected(index),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: AppAnimations.fast,
            width: 90,
            height: 86,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: isSelected ? scheme.primary : scheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: isSelected
                  ? null
                  : Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.5),
                    ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  PhosphorIconsRegular.calendarBlank,
                  color: isSelected
                      ? scheme.onPrimary
                      : scheme.onSurfaceVariant,
                  size: 18,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  titleFor(day),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w600,
                    fontSize: 13,
                    color: isSelected
                        ? scheme.onPrimary
                        : scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  shortDateFormat.format(day),
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected
                        ? scheme.onPrimary.withValues(alpha: 0.9)
                        : scheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // 5 items * 90px = 450px + espaciados ~ 40px
        // Si el ancho disponible es mayor a 520, entran cómodamente y los centramos
        if (constraints.maxWidth > 520) {
          return SizedBox(
            height: 86,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) => 4 - i).map((index) => buildItem(index, true)).toList(),
            ),
          );
        }

        // En pantallas pequeñas, usamos la lista horizontal con reverso
        return SizedBox(
          height: 86,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            reverse: true, // Esto hace que empiece alineado a la derecha
            itemCount: 5,
            itemBuilder: (context, index) => buildItem(index, false),
          ),
        );
      },
    );
  }
}

class _DaySummaryCard extends StatelessWidget {
  final SessionSummary summary;

  const _DaySummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            label: 'Cambios',
            value: summary.sessionsCount.toString(),
            subtitle: 'Registros en el día',
            icon: PhosphorIconsRegular.arrowsClockwise,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _MetricTile(
            label: 'Total del día',
            value: '${summary.totalBalance} ml',
            subtitle: 'Balance acumulado',
            icon: PhosphorIconsRegular.drop,
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: scheme.primary, size: 24),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
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
