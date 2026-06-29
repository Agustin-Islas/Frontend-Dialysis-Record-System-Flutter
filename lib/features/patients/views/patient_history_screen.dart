import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:frontend_dialysis_record/core/design/design.dart';
import 'package:frontend_dialysis_record/core/providers/providers.dart';
import 'package:frontend_dialysis_record/core/widgets/widgets.dart';
import 'package:frontend_dialysis_record/core/network/app_exception.dart';
import 'package:frontend_dialysis_record/features/auth/providers/auth_providers.dart';
import 'package:frontend_dialysis_record/features/patients/views/widgets/session_expansion_card.dart';
import 'package:frontend_dialysis_record/features/reports/four_weeks_dialysis_pdf_service.dart';
import 'package:frontend_dialysis_record/features/reports/monthly_dialysis_pdf_service.dart';
import 'package:frontend_dialysis_record/features/sessions/models/four_weeks_ultrafiltration_summary.dart';
import 'package:frontend_dialysis_record/features/sessions/models/monthly_ultrafiltration_summary.dart';
import 'package:frontend_dialysis_record/features/sessions/models/session_dto.dart';
import 'package:frontend_dialysis_record/features/sessions/models/session_summary.dart';
import 'package:frontend_dialysis_record/features/sessions/views/session_create_bottom_sheet.dart';
import 'package:frontend_dialysis_record/features/sessions/views/widgets/day_session_group_title.dart';

class PatientHistoryScreen extends ConsumerStatefulWidget {
  const PatientHistoryScreen({super.key});

  @override
  ConsumerState<PatientHistoryScreen> createState() => _PatientHistoryScreenState();
}

class _PatientHistoryScreenState extends ConsumerState<PatientHistoryScreen> {
  late DateTime _selectedMonth;
  late Future<List<SessionDto>> _sessionsFuture;

  final DateFormat _monthFormat = DateFormat('MMMM yyyy', 'es');
  final DateFormat _dayLabelFormat = DateFormat('EEEE dd/MM', 'es');
  final MonthlyDialysisPdfService _pdfService = MonthlyDialysisPdfService();
  final FourWeeksDialysisPdfService _fourWeeksPdfService = FourWeeksDialysisPdfService();
  bool _generatingPdf = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _reloadFutures();
  }

  void _reloadFutures() {
    _sessionsFuture = _loadMonth();
  }

  Future<List<SessionDto>> _loadMonth() {
    final me = ref.read(authStateProvider).valueOrNull;
    final patientId = me?.id;
    if (patientId == null) return Future.value([]);

    final patientCtrl = ref.read(patientControllerProvider);
    return patientCtrl.getSessionsByDateRange(
      patientId: patientId,
      startDate: DateTime(_selectedMonth.year, _selectedMonth.month, 1),
      endDate: DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0),
    );
  }

  void _reload() => setState(_reloadFutures);

  void _changeMonth(int increment) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + increment);
      _reloadFutures();
    });
  }

  Future<void> _pickMonth() async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => _MonthYearPickerDialog(
        initialDate: _selectedMonth,
        firstDate: DateTime(2020, 1),
        lastDate: DateTime.now(),
      ),
    );

    if (picked == null) return;

    setState(() {
      _selectedMonth = DateTime(picked.year, picked.month);
      _reloadFutures();
    });
  }

  Future<void> _generatePdf() async {
    setState(() => _generatingPdf = true);
    try {
      final me = ref.read(authStateProvider).valueOrNull;
      final sessions = await _loadMonth();
      final summary = MonthlyUltrafiltrationCalculator.calculate(
        month: _selectedMonth,
        sessions: sessions,
      );
      final bytes = await _pdfService.buildMonthlyReport(
        patient: me!,
        month: _selectedMonth,
        sessions: sessions,
        summary: summary,
      );
      final fileName = 'reporte_${_selectedMonth.month.toString().padLeft(2, '0')}_${_selectedMonth.year}.pdf';
      await _pdfService.download(bytes, fileName);
      if (mounted) AppSnackBar.success(context, 'PDF generado');
    } catch (e) {
      final message = e is AppException
          ? e.message
          : 'No se pudo generar el PDF.';
      if (mounted) AppSnackBar.error(context, message);
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }

  Future<void> _generate4WeeksPdf() async {
    setState(() => _generatingPdf = true);
    try {
      final me = ref.read(authStateProvider).valueOrNull;
      final patientId = me?.id;
      if (patientId == null) return;
      
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 27));

      final patientCtrl = ref.read(patientControllerProvider);
      final sessions = await patientCtrl.getSessionsByDateRange(
        patientId: patientId,
        startDate: startDate,
        endDate: endDate,
      );

      final summary = FourWeeksUltrafiltrationCalculator.calculate(
        endDate: endDate,
        sessions: sessions,
      );

      final bytes = await _fourWeeksPdfService.build4WeeksReport(
        patient: me!,
        endDate: endDate,
        sessions: sessions,
        summary: summary,
      );

      final DateFormat dayMonth = DateFormat('dd_MM');
      final DateFormat dayMonthYear = DateFormat('dd_MM_yyyy');
      final fileName = 'reporte_${dayMonth.format(startDate)}_${dayMonthYear.format(endDate)}.pdf';
      
      await _fourWeeksPdfService.download(bytes, fileName);
      if (mounted) AppSnackBar.success(context, 'PDF de 4 semanas generado');
    } catch (e) {
      final message = e is AppException ? e.message : 'No se pudo generar el PDF de 4 semanas.';
      if (mounted) AppSnackBar.error(context, message);
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }


  Future<void> _editSession(SessionDto session) async {
    if (session.id == null) return;
    final me = ref.read(authStateProvider).valueOrNull;
    final initialDate = session.date != null
        ? DateTime.tryParse(session.date!) ?? DateTime.now()
        : DateTime.now();

    final patientCtrl = ref.read(patientControllerProvider);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SessionCreateBottomSheet(
        initialDate: initialDate,
        initialSession: session,
        customConcentrations: me?.customConcentrations ?? [],
        onSubmit: (data) async {
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
          if (!mounted) return;
          AppSnackBar.success(context, 'Cambio actualizado');
          _reload();
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

    final patientCtrl = ref.read(patientControllerProvider);
    await patientCtrl.deleteSession(sessionId: session.id!);
    if (!mounted) return;
    AppSnackBar.success(context, 'Cambio eliminado');
    _reload();
  }

  Map<String, List<SessionDto>> _groupByDay(List<SessionDto> sessions) {
    final grouped = <String, List<SessionDto>>{};
    for (final s in sessions) {
      final key = s.date ?? 'Sin fecha';
      grouped.putIfAbsent(key, () => []).add(s);
    }
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    return {
      for (final key in sortedKeys)
        key: (grouped[key]!
          ..sort((a, b) => (a.bag ?? 999).compareTo(b.bag ?? 999))),
    };
  }

  String _formatDayTitle(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return _capitalize(_dayLabelFormat.format(date));
    } catch (_) {
      return isoDate;
    }
  }

  int _dayTotal(List<SessionDto> sessions) {
    return sessions.fold<int>(0, (total, s) => total + (s.partial ?? 0));
  }

  static String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<SessionDto>>(
        future: _sessionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppSkeletonScreen(title: 'Historial', itemCount: 4);
          }

          if (snapshot.hasError) {
            return AppErrorCard(
              message: 'No se pudo cargar el historial.',
              details: snapshot.error.toString(),
              onRetry: _reload,
            );
          }

          final sessions = snapshot.data ?? [];
          final grouped = _groupByDay(sessions);
          final monthLabel = _capitalize(_monthFormat.format(_selectedMonth));
          final summary = MonthlyUltrafiltrationCalculator.calculate(
            month: _selectedMonth,
            sessions: sessions,
          );

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: 4 + (sessions.isEmpty ? 1 : grouped.length),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _UltrafiltrationSummaryCard(summary: summary).withEntryAnimation();
                  }
                  if (index == 1) {
                    return Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: _MonthFilterCard(
                        monthLabel: monthLabel,
                        onPickMonth: _pickMonth,
                      ),
                    );
                  }
                  if (index == 2) {
                    return const SizedBox(height: AppSpacing.md);
                  }
                  if (index == 3) {
                    return Card(
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadius)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Historial de cambios',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Mes anterior',
                              icon: const Icon(Icons.chevron_left),
                              onPressed: () => _changeMonth(-1),
                            ),
                            IconButton(
                              tooltip: 'Mes siguiente',
                              icon: const Icon(Icons.chevron_right),
                              onPressed: !DateTime(_selectedMonth.year, _selectedMonth.month + 1).isAfter(DateTime(DateTime.now().year, DateTime.now().month)) ? () => _changeMonth(1) : null,
                            ),
                            if (_generatingPdf)
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            else
                              PopupMenuButton<int>(
                                icon: const Icon(PhosphorIconsRegular.filePdf),
                                tooltip: 'Generar reporte PDF',
                                onSelected: (value) {
                                  if (value == 0) {
                                    _generatePdf();
                                  } else if (value == 1) {
                                    _generate4WeeksPdf();
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(value: 0, child: Text('Reporte Mensual')),
                                  PopupMenuItem(value: 1, child: Text('Reporte Últimas 4 Semanas')),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (sessions.isEmpty) {
                    return const Card(
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppSpacing.cardRadius)),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: AppEmptyState(
                          message: 'No hay cambios registrados para este mes.',
                          icon: PhosphorIconsRegular.calendarX,
                        ),
                      ),
                    );
                  }

                  final isLast = index - 4 == grouped.length - 1;
                  final entry = grouped.entries.elementAt(index - 4);
                  final daySessions = entry.value;
                  final total = _dayTotal(daySessions);
                  final hasObservations = daySessions.any((s) => (s.observations ?? '').trim().isNotEmpty);

                  return Card(
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: isLast 
                        ? const BorderRadius.vertical(bottom: Radius.circular(AppSpacing.cardRadius))
                        : BorderRadius.zero,
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, isLast ? AppSpacing.lg : AppSpacing.sm),
                      child: Card(
                        elevation: 0,
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                        ),
                        child: ExpansionTile(
                          initiallyExpanded: false,
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.xs,
                          ),
                          title: DaySessionGroupTitle(
                            dayTitle: _formatDayTitle(entry.key),
                            changesCount: daySessions.length,
                            totalMl: total,
                            hasObservations: hasObservations,
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                          children: daySessions
                              .map(
                                (s) => SessionExpansionCard(
                                  session: s,
                                  onEdit: s.id == null ? null : () => _editSession(s),
                                  onDelete: s.id == null ? null : () => _deleteSession(s),
                                ),
                              )
                              .toList(),
                        ),
                      ).withEntryAnimation(delay: Duration(milliseconds: 50 * (index - 4))),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MonthFilterCard extends StatelessWidget {
  final String monthLabel;
  final VoidCallback onPickMonth;

  const _MonthFilterCard({
    required this.monthLabel,
    required this.onPickMonth,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtrar',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: FilledButton.tonalIcon(
                  onPressed: onPickMonth,
                  icon: const Icon(PhosphorIconsRegular.calendarBlank),
                  label: Text(monthLabel),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UltrafiltrationSummaryCard extends StatelessWidget {
  final MonthlyUltrafiltrationSummary summary;

  const _UltrafiltrationSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final weeklyValues = summary.weeklyUltrafiltration;

    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(PhosphorIconsRegular.heartbeat, color: scheme.onPrimaryContainer),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Resumen del mes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Promedio de cambios diarios',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _formatAvg(summary.totalChanges, summary.weekDayCounts.reduce((a, b) => a + b)),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth < 560 ? 2 : 4;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 4,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                    mainAxisExtent: 78,
                  ),
                  itemBuilder: (context, index) => _WeeklyUfTile(
                    week: index + 1,
                    value: weeklyValues[index],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatAvg(int total, int days) {
    if (days == 0) return '0';
    final avg = total / days;
    if (avg == avg.truncateToDouble()) return avg.toInt().toString();
    return avg.toStringAsFixed(2).replaceFirst(RegExp(r'0*$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
}

class _WeeklyUfTile extends StatelessWidget {
  final int week;
  final int value;

  const _WeeklyUfTile({required this.week, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'UF semana $week',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$value ml/día',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class MonthSummaryCard extends StatelessWidget {
  final SessionSummary summary;

  const MonthSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen del mes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                Chip(label: Text('Cambios: ${summary.sessionsCount}')),
                Chip(label: Text('Drenaje: ${summary.totalDrainage} ml')),
                Chip(label: Text('Infusión: ${summary.totalInfusion} ml')),
                Chip(label: Text('Balance: ${summary.totalBalance} ml')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthYearPickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const _MonthYearPickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<_MonthYearPickerDialog> {
  late int selectedYear;
  late int selectedMonth;

  static const monthNames = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  @override
  void initState() {
    super.initState();
    selectedYear = widget.initialDate.year;
    selectedMonth = widget.initialDate.month;
  }

  bool _isMonthEnabled(int month) {
    final candidate = DateTime(selectedYear, month);
    final min = DateTime(widget.firstDate.year, widget.firstDate.month);
    final max = DateTime(widget.lastDate.year, widget.lastDate.month);
    return !candidate.isBefore(min) && !candidate.isAfter(max);
  }

  @override
  Widget build(BuildContext context) {
    final years = List.generate(
      widget.lastDate.year - widget.firstDate.year + 1,
      (index) => widget.firstDate.year + index,
    ).reversed.toList();

    return AlertDialog(
      title: const Text('Seleccionar mes'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              initialValue: selectedYear,
              decoration: const InputDecoration(labelText: 'Año'),
              items: years
                  .map((year) => DropdownMenuItem(
                        value: year,
                        child: Text(year.toString()),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  selectedYear = value;
                  if (!_isMonthEnabled(selectedMonth)) {
                    selectedMonth = List.generate(12, (i) => i + 1)
                        .where(_isMonthEnabled)
                        .first;
                  }
                });
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: List.generate(12, (index) {
                final month = index + 1;
                return ChoiceChip(
                  label: Text(monthNames[index]),
                  selected: selectedMonth == month,
                  onSelected: _isMonthEnabled(month)
                      ? (_) => setState(() => selectedMonth = month)
                      : null,
                );
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, DateTime(selectedYear, selectedMonth)),
          child: const Text('Aceptar'),
        ),
      ],
    );
  }
}
