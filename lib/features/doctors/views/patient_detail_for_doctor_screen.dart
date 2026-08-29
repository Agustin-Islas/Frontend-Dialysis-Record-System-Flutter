import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:frontend_dialysis_record/core/providers/providers.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';


import 'package:frontend_dialysis_record/features/auth/models/me_response.dart';
import 'package:frontend_dialysis_record/features/doctors/providers/doctor_providers.dart';
import 'package:frontend_dialysis_record/features/patients/providers/patient_providers.dart';
import 'package:frontend_dialysis_record/features/patients/views/widgets/session_expansion_card.dart';
import 'package:frontend_dialysis_record/features/reports/four_weeks_dialysis_pdf_service.dart';
import 'package:frontend_dialysis_record/features/reports/monthly_dialysis_pdf_service.dart';
import 'package:frontend_dialysis_record/features/sessions/models/four_weeks_ultrafiltration_summary.dart';
import 'package:frontend_dialysis_record/features/sessions/models/monthly_ultrafiltration_summary.dart';
import 'package:frontend_dialysis_record/features/sessions/models/session_dto.dart';
import 'package:frontend_dialysis_record/features/sessions/views/widgets/day_session_group_title.dart';
import 'package:frontend_dialysis_record/features/doctors/views/widgets/observations_timeline_panel.dart';
import 'package:frontend_dialysis_record/core/widgets/widgets.dart';
import 'package:frontend_dialysis_record/core/design/design.dart';

class PatientDetailForDoctorScreen extends ConsumerStatefulWidget {
  final String patientId;

  const PatientDetailForDoctorScreen({super.key, required this.patientId});

  @override
  ConsumerState<PatientDetailForDoctorScreen> createState() =>
      _PatientDetailForDoctorScreenState();
}

class _PatientDetailForDoctorScreenState
    extends ConsumerState<PatientDetailForDoctorScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _generatingPdf = false;
  int _selectedChartIndex = 0; // 0 for UF, 1 for Glucosa
  final ItemScrollController _itemScrollController = ItemScrollController();
  final Map<int, ExpansibleController> _tileControllers = {};
  final DateFormat _monthFormat = DateFormat('MMMM yyyy', 'es');
  final DateFormat _dayFormat = DateFormat('EEEE dd/MM', 'es');
  final MonthlyDialysisPdfService _pdfService = MonthlyDialysisPdfService();
  final FourWeeksDialysisPdfService _fourWeeksPdfService =
      FourWeeksDialysisPdfService();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  void _changeMonth(int delta) {
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + delta);
    final currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
    if (next.isAfter(currentMonth)) return;

    setState(() => _selectedMonth = next);
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
    if (picked != null) {
      setState(() => _selectedMonth = DateTime(picked.year, picked.month));
    }
  }

  Future<void> _generatePdf(
    MeResponse patient,
    List<SessionDto> sessions,
  ) async {
    setState(() => _generatingPdf = true);
    try {
      final summary = MonthlyUltrafiltrationCalculator.calculate(
        month: _selectedMonth,
        sessions: sessions,
      );
      final bytes = await _pdfService.buildMonthlyReport(
        patient: patient,
        month: _selectedMonth,
        sessions: sessions,
        summary: summary,
      );
      final fileName =
          'reporte_${_selectedMonth.month.toString().padLeft(2, '0')}_${_selectedMonth.year}.pdf';
      await _pdfService.download(bytes, fileName);
      if (mounted) AppSnackBar.success(context, 'PDF generado');
    } catch (e) {
      if (mounted) {
        AppSnackBar.showException(context, e, 'No se pudo generar el PDF.');
      }
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }

  Future<void> _generate4WeeksPdf(MeResponse patient) async {
    setState(() => _generatingPdf = true);
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 27));

      final patientCtrl = ref.read(patientControllerProvider);
      final sessions = await patientCtrl.getSessionsByDateRange(
        patientId: widget.patientId,
        startDate: startDate,
        endDate: endDate,
      );

      final summary = FourWeeksUltrafiltrationCalculator.calculate(
        endDate: endDate,
        sessions: sessions,
      );

      final bytes = await _fourWeeksPdfService.build4WeeksReport(
        patient: patient,
        endDate: endDate,
        sessions: sessions,
        summary: summary,
      );

      final DateFormat dayMonth = DateFormat('dd_MM');
      final DateFormat dayMonthYear = DateFormat('dd_MM_yyyy');
      final fileName =
          'reporte_${dayMonth.format(startDate)}_${dayMonthYear.format(endDate)}.pdf';

      await _fourWeeksPdfService.download(bytes, fileName);
      if (mounted) AppSnackBar.success(context, 'PDF de 4 semanas generado');
    } catch (e) {
      if (mounted) {
        AppSnackBar.showException(
          context,
          e,
          'No se pudo generar el PDF de 4 semanas.',
        );
      }
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }

  Map<String, List<SessionDto>> _groupByDay(List<SessionDto> sessions) {
    final grouped = <String, List<SessionDto>>{};
    for (final session in sessions) {
      final key = session.effectiveDate ?? 'Sin fecha';
      grouped.putIfAbsent(key, () => []).add(session);
    }
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    return {
      for (final key in sortedKeys)
        key: (grouped[key]!
          ..sort((a, b) {
            final bagComp = (a.bag ?? 999).compareTo(b.bag ?? 999);
            if (bagComp != 0) return bagComp;
            final aNight = a.isNightShift ? 1 : 0;
            final bNight = b.isNightShift ? 1 : 0;
            if (aNight != bNight) return aNight.compareTo(bNight);
            return (a.hour ?? '').compareTo(b.hour ?? '');
          })),
    };
  }

  String _monthLabel() {
    final value = _monthFormat.format(_selectedMonth);
    return value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
  }

  String _formatDayTitle(String isoDate) {
    final parsed = DateTime.tryParse(isoDate);
    if (parsed == null) return isoDate;
    final text = _dayFormat.format(parsed);
    return text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
  }

  int _dayTotal(List<SessionDto> sessions) {
    return sessions.fold<int>(0, (t, s) => t + (s.partial ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    final patientsAsync = ref.watch(doctorPatientsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del paciente')),
      body: patientsAsync.when(
        loading: () => const AppSkeletonScreen(itemCount: 4),
        error: (e, _) => AppErrorCard(
          message: 'Error al cargar pacientes',
          details: e.toString(),
          onRetry: () => ref.invalidate(doctorPatientsProvider),
        ),
        data: (patients) {
          final patient = patients.where((p) => p.id == widget.patientId).firstOrNull;

          if (patient == null) {
            return SafeArea(
              child: Center(
                child: AppEmptyState(
                  icon: PhosphorIconsRegular.userMinus,
                  message: 'El paciente solicitado no existe o no tienes acceso a él.',
                  actionLabel: 'Volver a mis pacientes',
                  onAction: () => context.go('/doctor/patients'),
                ),
              ),
            );
          }

          final sessionsAsync = ref.watch(
            monthSessionsProvider((
              patientId: widget.patientId,
              month: _selectedMonth,
            )),
          );

          return SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    child: sessionsAsync.when(
                      loading: () => const AppSkeletonScreen(itemCount: 4),
                      error: (e, _) {
                        final isAppEx = e.runtimeType.toString() == 'AppException';
                        return AppErrorCard(
                          message: 'Error al cargar los registros',
                          details: isAppEx ? (e as dynamic).message : 'No se pudieron cargar los registros de diálisis. $e',
                          onRetry: () => ref.invalidate(monthSessionsProvider),
                        );
                      },
                      data: (sessions) {
                        final summary = MonthlyUltrafiltrationCalculator.calculate(
                          month: _selectedMonth,
                          sessions: sessions,
                        );
                        final grouped = _groupByDay(sessions);
                        final currentMonth = DateTime(
                          DateTime.now().year,
                          DateTime.now().month,
                        );
                        final canGoForward = !DateTime(
                          _selectedMonth.year,
                          _selectedMonth.month + 1,
                        ).isAfter(currentMonth);

                        final dayEntries = grouped.entries.toList();
                        
                        int daysInMonth = DateUtils.getDaysInMonth(_selectedMonth.year, _selectedMonth.month);
                        final dailyTotals = List<double>.filled(daysInMonth, 0);

                        for (final s in sessions) {
                          if (s.effectiveDate == null) continue;
                          final date = DateTime.tryParse(s.effectiveDate!);
                          if (date == null) continue;
                          if (date.year == _selectedMonth.year && date.month == _selectedMonth.month) {
                            final total = s.partial ?? ((s.infusion ?? 0) - (s.drainage ?? 0));
                            dailyTotals[date.day - 1] += total;
                          }
                        }

                        int daysWithData = 0;
                        double sumData = 0;
                        for (final val in dailyTotals) {
                          if (val != 0) {
                            daysWithData++;
                            sumData += val;
                          }
                        }
                        final mean = daysWithData > 0 ? sumData / daysWithData : 0.0;

                        Widget buildChartCard(int startIndex) {
                           Widget ufChartWidget = _DailyUltrafiltrationChart(
                             month: _selectedMonth,
                             sessions: sessions,
                             mean: mean,
                             onDayTapped: (day) {
                               final entryIndex = dayEntries.indexWhere((e) {
                                 final dt = DateTime.tryParse(e.key);
                                 return dt != null && dt.day == day;
                               });
                               if (entryIndex != -1) {
                                 final listIndex = startIndex + entryIndex;
                                 _itemScrollController.scrollTo(
                                   index: listIndex,
                                   duration: const Duration(milliseconds: 600),
                                   curve: Curves.easeInOutCubic,
                                 );
                                 Future.delayed(
                                   const Duration(milliseconds: 700),
                                   () {
                                     if (_tileControllers[entryIndex] != null &&
                                         !_tileControllers[entryIndex]!.isExpanded) {
                                       _tileControllers[entryIndex]!.expand();
                                     }
                                   },
                                 );
                               }
                             },
                           );
                           
                           Widget pieChartWidget = _ConcentrationPieChart(
                             month: _selectedMonth,
                             sessions: sessions,
                           );
                           
                           Widget chartWidget = _selectedChartIndex == 0 ? ufChartWidget : pieChartWidget;
                           
                           if (isWide) {
                             chartWidget = Expanded(child: chartWidget);
                           }

                           return Card(
                             elevation: 0,
                             shape: RoundedRectangleBorder(
                               borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                               side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
                             ),
                             child: Padding(
                               padding: const EdgeInsets.all(AppSpacing.lg),
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Row(
                                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                     children: [
                                       Expanded(
                                         child: Text(
                                           _selectedChartIndex == 0 ? 'Evolución de Balance Diario' : 'Carga de Glucosa',
                                           style: const TextStyle(
                                             fontSize: 16,
                                             fontWeight: FontWeight.w700,
                                           ),
                                           maxLines: 2,
                                           overflow: TextOverflow.ellipsis,
                                         ),
                                       ),
                                       const SizedBox(width: 8),
                                       SegmentedButton<int>(
                                         segments: const [
                                           ButtonSegment(value: 0, icon: Icon(PhosphorIconsRegular.chartLineUp), label: Text('UF')),
                                           ButtonSegment(value: 1, icon: Icon(PhosphorIconsRegular.chartPieSlice), label: Text('Glucosa')),
                                         ],
                                         selected: {_selectedChartIndex},
                                         onSelectionChanged: (newSelection) {
                                           setState(() {
                                             _selectedChartIndex = newSelection.first;
                                           });
                                         },
                                         showSelectedIcon: false,
                                         style: ButtonStyle(
                                            visualDensity: VisualDensity.compact,
                                         ),
                                       ),
                                     ],
                                   ),
                                   if (_selectedChartIndex == 0) ...[
                                     const SizedBox(height: 8),
                                     Row(
                                       mainAxisSize: MainAxisSize.min,
                                       children: [
                                         Icon(
                                           Icons.touch_app_outlined,
                                           size: 18,
                                           color: Theme.of(context).colorScheme.primary,
                                         ),
                                         const SizedBox(width: 4),
                                         Text(
                                           'Toca una barra para ir al detalle del día',
                                           style: TextStyle(
                                             fontSize: 12,
                                             color: Theme.of(context).colorScheme.onSurfaceVariant,
                                           ),
                                         ),
                                       ],
                                     ),
                                   ],
                                   const SizedBox(height: AppSpacing.lg),
                                   chartWidget,
                                 ],
                               ),
                             ),
                           );
                        }

                        // Determine indices
                        int sessionStartIndex = 0;
                        final items = <Widget>[];

                        items.add(_PatientMonthPanel(
                          patient: patient,
                          patientName: '${patient.name ?? "-"} ${patient.surname ?? ""}'.trim(),
                          summary: summary,
                          monthLabel: _monthLabel(),
                        ));

                        items.add(Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.md),
                          child: _MonthFilterRow(
                            monthLabel: _monthLabel(),
                            onPickMonth: _pickMonth,
                          ),
                        ));

                        if (!isWide) {
                          // Dummy calculation of startIndex for the chart to pass down
                          // Left items: panel (0), filter (1), chart (2), header (3), divider (4) -> index 5
                          items.add(buildChartCard(5)); 
                          items.add(const SizedBox(height: AppSpacing.md));
                        }

                        items.add(Card(
                          elevation: 0,
                          margin: EdgeInsets.zero,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(AppSpacing.cardRadius),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Historial de cambios',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Mes anterior',
                                  onPressed: () => _changeMonth(-1),
                                  icon: const Icon(Icons.chevron_left),
                                ),
                                IconButton(
                                  tooltip: 'Mes siguiente',
                                  onPressed: canGoForward ? () => _changeMonth(1) : null,
                                  icon: const Icon(Icons.chevron_right),
                                ),
                                IconButton(
                                  tooltip: 'Ver Observaciones',
                                  onPressed: () {
                                    showObservationsPanel(context, sessions);
                                  },
                                  icon: const Icon(PhosphorIconsRegular.stethoscope),
                                  color: Theme.of(context).colorScheme.primary,
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
                                    icon: const Icon(Icons.picture_as_pdf_outlined),
                                    tooltip: 'Generar reporte PDF',
                                    onSelected: (value) {
                                      if (value == 0) {
                                        _generatePdf(patient, sessions);
                                      } else if (value == 1) {
                                        _generate4WeeksPdf(patient);
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
                        ));
                        
                        items.add(Container(
                          color: Theme.of(context).colorScheme.surface,
                          height: 1,
                        ));

                        sessionStartIndex = items.length;

                        if (sessions.isEmpty) {
                          items.add(
                            const Card(
                              elevation: 0,
                              margin: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppSpacing.cardRadius)),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(AppSpacing.lg),
                                child: AppEmptyState(
                                  message: 'No hay cambios para este mes.',
                                  icon: Icons.calendar_today,
                                ),
                              ),
                            )
                          );
                        } else {
                          for (int i = 0; i < dayEntries.length; i++) {
                            final isLast = i == dayEntries.length - 1;
                            final entry = dayEntries[i];
                            final daySessions = entry.value;

                            items.add(
                              Card(
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
                                      controller: _tileControllers.putIfAbsent(i, () => ExpansibleController()),
                                      initiallyExpanded: false,
                                      title: DaySessionGroupTitle(
                                        dayTitle: _formatDayTitle(entry.key),
                                        changesCount: daySessions.length,
                                        totalMl: _dayTotal(daySessions),
                                        hasObservations: daySessions.any((s) => (s.observations ?? '').trim().isNotEmpty),
                                      ),
                                      children: daySessions.map((s) => SessionExpansionCard(session: s)).toList(),
                                    ),
                                  ),
                                ),
                              )
                            );
                          }
                        }

                        final listWidget = ScrollablePositionedList.builder(
                          itemScrollController: _itemScrollController,
                          padding: EdgeInsets.all(isWide ? 0 : AppSpacing.lg),
                          itemCount: items.length,
                          itemBuilder: (context, index) => items[index],
                        );

                        if (isWide) {
                          return Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: listWidget,
                                ),
                                const SizedBox(width: AppSpacing.lg),
                                Expanded(
                                  flex: 6,
                                  child: buildChartCard(sessionStartIndex),
                                ),
                              ],
                            ),
                          );
                        }

                        return listWidget;
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _PatientMonthPanel extends StatelessWidget {
  final MeResponse patient;
  final String patientName;
  final String monthLabel;
  final MonthlyUltrafiltrationSummary summary;

  const _PatientMonthPanel({
    required this.patient,
    required this.patientName,
    required this.monthLabel,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final weeklyValues = summary.weeklyUltrafiltration;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              patientName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xs,
              children: [
                if (patient.email != null)
                  Text(
                    patient.email!,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                if (patient.dni != null)
                  Text(
                    'DNI: ${patient.dni}',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    PhosphorIconsRegular.heartbeat,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Promedio de cambios diarios',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  _formatAvg(summary.totalChanges, summary.elapsedDays),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth < 650 ? 2 : 4;
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
                  itemBuilder: (context, index) => _DoctorWeeklyUfTile(
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
    if (days <= 0) return '0';
    final avg = total / days;
    if (avg == avg.truncateToDouble()) return avg.toInt().toString();
    return avg
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0*$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}

class _DoctorWeeklyUfTile extends StatelessWidget {
  final int week;
  final int value;

  const _DoctorWeeklyUfTile({required this.week, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 140,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'UF semana $week',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$value ml/día',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthFilterRow extends StatelessWidget {
  final String monthLabel;
  final VoidCallback onPickMonth;

  const _MonthFilterRow({required this.monthLabel, required this.onPickMonth});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Filtrar mes',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        InkWell(
          onTap: onPickMonth,
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  monthLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  PhosphorIconsRegular.calendarBlank,
                  color: scheme.primary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChartData {
  final String day;
  final double value;
  final Color color;
  _ChartData(this.day, this.value, this.color);
}

class _DailyUltrafiltrationChart extends StatefulWidget {
  final DateTime month;
  final List<SessionDto> sessions;
  final double mean;
  final void Function(int day)? onDayTapped;

  const _DailyUltrafiltrationChart({
    required this.month,
    required this.sessions,
    required this.mean,
    this.onDayTapped,
  });

  @override
  State<_DailyUltrafiltrationChart> createState() =>
      _DailyUltrafiltrationChartState();
}

class _DailyUltrafiltrationChartState
    extends State<_DailyUltrafiltrationChart> {
  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(
      widget.month.year,
      widget.month.month,
    );
    final dailyTotals = List<double>.filled(daysInMonth, 0);

    for (final s in widget.sessions) {
      if (s.effectiveDate == null) continue;
      final date = DateTime.tryParse(s.effectiveDate!);
      if (date == null) continue;
      if (date.year == widget.month.year && date.month == widget.month.month) {
        final total = s.partial ?? ((s.infusion ?? 0) - (s.drainage ?? 0));
        dailyTotals[date.day - 1] += total;
      }
    }

    final scheme = Theme.of(context).colorScheme;
    final List<_ChartData> chartData = [];
    
    double minVal = -1200;
    double maxVal = 400;
    
    int daysWithData = 0;

    int daysToShow = daysInMonth;
    final now = DateTime.now();
    if (widget.month.year == now.year && widget.month.month == now.month) {
      daysToShow = now.day;
    }

    final List<_ChartData> meanChartData = [];

    for (int i = 0; i < daysToShow; i++) {
      final val = dailyTotals[i];
      
      chartData.add(
        _ChartData(
          (i + 1).toString(),
          val,
          val > 0 ? scheme.error : const Color(0xFF4CAF50),
        ),
      );
      
      meanChartData.add(_ChartData((i + 1).toString(), widget.mean, scheme.primary));
      
      if (val != 0) {
        daysWithData++;
      }
      if (val < minVal) minVal = val;
      if (val > maxVal) maxVal = val;
    }
    
    if (minVal < -1200) minVal -= 100;
    if (maxVal > 400) maxVal += 100;
    
    return SizedBox(
      height: 250,
      width: double.infinity,
      child: SfCartesianChart(
        plotAreaBorderWidth: 0,
        margin: const EdgeInsets.only(top: 10, right: 10, bottom: 5),
        trackballBehavior: TrackballBehavior(
          enable: true,
          activationMode: ActivationMode.singleTap,
          lineType: TrackballLineType.vertical,
          lineColor: scheme.primary.withValues(alpha: 0.5),
          lineWidth: 1.5,
          lineDashArray: const <double>[5, 5],
          tooltipSettings: InteractiveTooltip(
            enable: true,
            color: scheme.surfaceContainerHighest,
            textStyle: TextStyle(
              color: scheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        primaryXAxis: CategoryAxis(
          crossesAt: 0,
          placeLabelsNearAxisLine: false,
          majorGridLines: const MajorGridLines(width: 0),
          axisLine: const AxisLine(width: 1.5, color: Colors.grey),
          labelStyle: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
          interval: daysInMonth > 15 ? 5 : 2,
          labelIntersectAction: AxisLabelIntersectAction.hide,
        ),
        primaryYAxis: NumericAxis(
          minimum: minVal,
          maximum: maxVal,
          axisLine: const AxisLine(width: 0),
          majorTickLines: const MajorTickLines(size: 0),
          majorGridLines: MajorGridLines(
            width: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.3),
            dashArray: const <double>[5, 5],
          ),
          labelStyle: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
        ),
        legend: Legend(
          isVisible: true,
          position: LegendPosition.bottom,
          toggleSeriesVisibility: true,
          textStyle: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600),
          iconHeight: 12,
          iconWidth: 12,
        ),
        series: <CartesianSeries<_ChartData, String>>[
          ColumnSeries<_ChartData, String>(
            name: 'Balance Diario',
            dataSource: chartData,
            xValueMapper: (_ChartData data, _) => data.day,
            yValueMapper: (_ChartData data, _) => data.value,
            pointColorMapper: (_ChartData data, _) => data.color,
            borderRadius: BorderRadius.circular(2),
            animationDuration: 1000,
            onPointTap: (ChartPointDetails details) {
              if (widget.onDayTapped != null && details.pointIndex != null) {
                final day = int.tryParse(chartData[details.pointIndex!].day);
                if (day != null) widget.onDayTapped!(day);
              }
            },
          ),
          if (daysWithData > 0)
            LineSeries<_ChartData, String>(
              name: 'Media Mensual',
              initialIsVisible: true,
              dataSource: meanChartData,
              xValueMapper: (_ChartData data, _) => data.day,
              yValueMapper: (_ChartData data, _) => data.value,
              color: scheme.primary,
              width: 2,
              dashArray: const <double>[5, 5],
              enableTooltip: false,
              markerSettings: const MarkerSettings(isVisible: false),
              animationDuration: 1000,
            ),
        ],
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
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
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
                  .map(
                    (y) =>
                        DropdownMenuItem(value: y, child: Text(y.toString())),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  selectedYear = value;
                  if (!_isMonthEnabled(selectedMonth)) {
                    selectedMonth = List.generate(
                      12,
                      (i) => i + 1,
                    ).where(_isMonthEnabled).first;
                  }
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: List.generate(12, (index) {
                final month = index + 1;
                final isSelected = selectedMonth == month;
                return ChoiceChip(
                  label: Text(
                    monthNames[index],
                    style: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  selectedColor: Theme.of(context).colorScheme.primary,
                  selected: isSelected,
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

class _PieChartData {
  final String label;
  final int count;
  final Color color;
  final String percentageText;
  final int avgPartial;

  _PieChartData(this.label, this.count, this.color, this.percentageText, this.avgPartial);
}

class _ConcentrationPieChart extends StatelessWidget {
  final DateTime month;
  final List<SessionDto> sessions;

  const _ConcentrationPieChart({
    required this.month,
    required this.sessions,
  });

  @override
  Widget build(BuildContext context) {
    DateTime? parseDateTime(String? dateStr, String? hourStr) {
      if (dateStr == null) return null;
      final d = DateTime.tryParse(dateStr);
      if (d == null) return null;
      if (hourStr == null) return d;
      final parts = hourStr.split(':');
      if (parts.length >= 2) {
        final h = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        return DateTime(d.year, d.month, d.day, h, m);
      }
      return d;
    }

    final sortedSessions = List<SessionDto>.from(sessions)
      ..sort((a, b) {
        final dateA = parseDateTime(a.date, a.hour);
        final dateB = parseDateTime(b.date, b.hour);
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        return dateA.compareTo(dateB);
      });

    final Map<double, int> counts = {};
    final Map<double, int> partialSums = {};
    final Map<double, int> partialCounts = {};
    
    for (int i = 0; i < sortedSessions.length; i++) {
      final s = sortedSessions[i];
      if (s.effectiveDate == null) continue;
      final date = DateTime.tryParse(s.effectiveDate!);
      if (date == null) continue;
      
      if (date.year == month.year && date.month == month.month) {
        // Contamos la bolsa infundida en ESTA sesión
        if (s.concentration != null) {
          counts[s.concentration!] = (counts[s.concentration!] ?? 0) + 1;
        }
        
        // Clínicamente, el 'parcial' (drenaje pos infusión) de ESTA sesión 
        // corresponde a la eficacia de la bolsa infundida en la sesión ANTERIOR.
        if (i > 0 && s.partial != null) {
          final prevSession = sortedSessions[i - 1];
          if (prevSession.concentration != null) {
            final prevConc = prevSession.concentration!;
            partialSums[prevConc] = (partialSums[prevConc] ?? 0) + s.partial!;
            partialCounts[prevConc] = (partialCounts[prevConc] ?? 0) + 1;
          }
        }
      }
    }

    final scheme = Theme.of(context).colorScheme;
    final chartData = counts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
      
    final int totalBags = counts.values.fold(0, (sum, count) => sum + count);
      
    final List<_PieChartData> dataSource = [];
    int fallbackColorIndex = 0;
    final fallbackColors = [
      const Color(0xFF2196F3), // Azul
      const Color(0xFFFF9800), // Naranja
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFFE91E63), // Rosa
      const Color(0xFF3F51B5), // Indigo
      const Color(0xFF795548), // Marrón
    ];

    for (final entry in chartData) {
      final isInt = entry.key % 1 == 0;
      final label = isInt
          ? '${entry.key.toInt()}%'
          : '${entry.key.toStringAsFixed(1).replaceAll('.', ',')}%';
          
      Color color;
      if (entry.key == 1.5) {
        color = const Color(0xFFFFC107); // Amarillo
      } else if (entry.key == 2.3 || entry.key == 2.5) {
        color = const Color(0xFF4CAF50); // Verde
      } else if (entry.key == 4.25) {
        color = scheme.error; // Rojo
      } else if (entry.key == 7.5) {
        color = const Color(0xFF9C27B0); // Morado (Icodextrina)
      } else {
        color = fallbackColors[fallbackColorIndex % fallbackColors.length];
        fallbackColorIndex++;
      }
      
      final validPartialsCount = partialCounts[entry.key] ?? 0;
      final avgPartial = validPartialsCount > 0 
          ? (partialSums[entry.key]! / validPartialsCount).round() 
          : 0;
          
      final percentage = (entry.value / totalBags * 100).toStringAsFixed(1).replaceAll('.', ',');
      
      dataSource.add(
        _PieChartData(label, entry.value, color, '$percentage%', avgPartial),
      );
    }

    if (dataSource.isEmpty) {
      return SizedBox(
        height: 250,
        child: Center(
          child: Text(
            'No hay datos de concentración en este mes',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 220,
          width: double.infinity,
          child: SfCircularChart(
            margin: EdgeInsets.zero,
            legend: const Legend(isVisible: false),
            annotations: <CircularChartAnnotation>[
              CircularChartAnnotation(
                widget: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$totalBags',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                    Text(
                      'Bolsas',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            tooltipBehavior: TooltipBehavior(
              enable: true,
              builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
                final pieData = data as _PieChartData;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '${pieData.percentageText} del total',
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
            series: <CircularSeries>[
              DoughnutSeries<_PieChartData, String>(
                dataSource: dataSource,
                xValueMapper: (_PieChartData data, _) => data.label,
                yValueMapper: (_PieChartData data, _) => data.count,
                pointColorMapper: (_PieChartData data, _) => data.color,
                dataLabelMapper: (_PieChartData data, _) => data.label,
                dataLabelSettings: DataLabelSettings(
                  isVisible: true,
                  textStyle: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                  labelPosition: ChartDataLabelPosition.outside,
                  labelIntersectAction: LabelIntersectAction.shift,
                  connectorLineSettings: const ConnectorLineSettings(
                    type: ConnectorType.curve,
                    length: '10%',
                  ),
                ),
                innerRadius: '60%',
                radius: '70%',
                animationDuration: 800,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: dataSource.map((data) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: data.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${data.label} (${data.count} bolsas)',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      Text(
                        'Parcial prom: ${data.avgPartial} ml',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: data.avgPartial <= 0 ? scheme.primary : scheme.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}





