import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_dialysis_record/core/providers/providers.dart';
import 'package:intl/intl.dart';
import 'package:frontend_dialysis_record/core/network/app_exception.dart';

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
import 'package:frontend_dialysis_record/core/widgets/widgets.dart';
import 'package:frontend_dialysis_record/core/design/design.dart';

class PatientDetailForDoctorScreen extends ConsumerStatefulWidget {
  final String patientId;

  const PatientDetailForDoctorScreen({
    super.key,
    required this.patientId,
  });

  @override
  ConsumerState<PatientDetailForDoctorScreen> createState() =>
      _PatientDetailForDoctorScreenState();
}

class _PatientDetailForDoctorScreenState extends ConsumerState<PatientDetailForDoctorScreen> {
  late DateTime _selectedMonth;
  final DateFormat _monthFormat = DateFormat('MMMM yyyy', 'es');
  final DateFormat _dayFormat = DateFormat('EEEE dd/MM', 'es');
  final MonthlyDialysisPdfService _pdfService = MonthlyDialysisPdfService();
  final FourWeeksDialysisPdfService _fourWeeksPdfService = FourWeeksDialysisPdfService();
  bool _generatingPdf = false;

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

  Future<void> _generatePdf(MeResponse patient, List<SessionDto> sessions) async {
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
      final name = (patient.name ?? 'paciente')
          .replaceAll(RegExp(r'\s+'), '_')
          .toLowerCase();
      final fileName =
          'registro_dialisis_${name}_${_selectedMonth.year}_${_selectedMonth.month.toString().padLeft(2, '0')}.pdf';
      await _pdfService.download(bytes, fileName);
      if (mounted) AppSnackBar.success(context, 'PDF generado');
    } catch (e) {
      final message = e is AppException ? e.message : 'No se pudo generar el PDF.';
      if (mounted) AppSnackBar.error(context, message);
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

      final name = (patient.name ?? 'paciente').replaceAll(RegExp(r'\s+'), '_').toLowerCase();
      final fileName = 'registro_4semanas_${name}_${endDate.year}_${endDate.month.toString().padLeft(2, '0')}_${endDate.day.toString().padLeft(2, '0')}.pdf';
      
      await _fourWeeksPdfService.download(bytes, fileName);
      if (mounted) AppSnackBar.success(context, 'PDF de 4 semanas generado');
    } catch (e) {
      final message = e is AppException ? e.message : 'No se pudo generar el PDF de 4 semanas.';
      if (mounted) AppSnackBar.error(context, message);
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }

  Map<String, List<SessionDto>> _groupByDay(List<SessionDto> sessions) {
    final grouped = <String, List<SessionDto>>{};
    for (final session in sessions) {
      final key = session.date ?? 'Sin fecha';
      grouped.putIfAbsent(key, () => []).add(session);
    }
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    return {
      for (final key in sortedKeys)
        key: (grouped[key]!..sort((a, b) => (a.bag ?? 999).compareTo(b.bag ?? 999))),
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
          final patient = patients.firstWhere(
            (p) => p.id == widget.patientId,
            orElse: () => MeResponse(id: widget.patientId, name: 'Desconocido', role: 'PATIENT'),
          );

          final sessionsAsync = ref.watch(
            monthSessionsProvider((patientId: widget.patientId, month: _selectedMonth)),
          );

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    sessionsAsync.when(
                      loading: () => const AppSkeletonScreen(itemCount: 4),
                      error: (e, _) => AppErrorCard(
                        message: 'Error al cargar cambios',
                        details: e.toString(),
                        onRetry: () => ref.invalidate(monthSessionsProvider),
                      ),
                      data: (sessions) {
                        final summary = MonthlyUltrafiltrationCalculator.calculate(
                          month: _selectedMonth,
                          sessions: sessions,
                        );
                        final grouped = _groupByDay(sessions);
                        final currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
                        final canGoForward = !DateTime(
                          _selectedMonth.year,
                          _selectedMonth.month + 1,
                        ).isAfter(currentMonth);

                        return Column(
                          children: [
                            _PatientMonthPanel(
                              patient: patient,
                              patientName: '${patient.name ?? "-"} ${patient.surname ?? ""}'.trim(),
                              summary: summary,
                              monthLabel: _monthLabel(),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _MonthFilterCard(
                              monthLabel: _monthLabel(),
                              onPickMonth: _pickMonth,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Card(
                              elevation: 0,
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
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
                                          onPressed: () => _changeMonth(-1),
                                          icon: const Icon(Icons.chevron_left),
                                        ),
                                        IconButton(
                                          tooltip: 'Mes siguiente',
                                          onPressed: canGoForward ? () => _changeMonth(1) : null,
                                          icon: const Icon(Icons.chevron_right),
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
                                              PopupMenuItem(
                                                value: 0,
                                                child: Text('Reporte Mensual'),
                                              ),
                                              PopupMenuItem(
                                                value: 1,
                                                child: Text('Reporte Últimas 4 Semanas'),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(AppSpacing.lg),
                                    child: sessions.isEmpty
                                        ? const AppEmptyState(
                                            message: 'No hay cambios para este mes.',
                                            icon: Icons.calendar_today,
                                          )
                                        : Column(
                                            children: grouped.entries.map((entry) {
                                              final daySessions = entry.value;
                                              return Card(
                                                elevation: 0,
                                                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                                                  side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                                                ),
                                                child: ExpansionTile(
                                                  initiallyExpanded: false,
                                                  title: DaySessionGroupTitle(
                                                    dayTitle: _formatDayTitle(entry.key),
                                                    changesCount: daySessions.length,
                                                    totalMl: _dayTotal(daySessions),
                                                    hasObservations: daySessions.any((s) => (s.observations ?? '').trim().isNotEmpty),
                                                  ),
                                                  children: daySessions.map((s) => SessionExpansionCard(session: s)).toList(),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
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
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              patientName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xs,
              children: [
                if (patient.email != null) Text(patient.email!, style: TextStyle(color: scheme.onPrimaryContainer)),
                if (patient.dni != null) Text('DNI: ${patient.dni}', style: TextStyle(color: scheme.onPrimaryContainer)),
                Text(monthLabel, style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cambios totales', style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppSpacing.xs),
                  Text('${summary.totalChanges}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
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
                  itemBuilder: (context, index) => _DoctorWeeklyUfTile(week: index + 1, value: weeklyValues[index]),
                );
              },
            ),
          ],
        ),
      ),
    );
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
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('UF semana $week', style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.xs),
          Text('$value ml/día', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _MonthFilterCard extends StatelessWidget {
  final String monthLabel;
  final VoidCallback onPickMonth;

  const _MonthFilterCard({required this.monthLabel, required this.onPickMonth});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filtrar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: OutlinedButton.icon(
                  onPressed: onPickMonth,
                  icon: const Icon(Icons.calendar_month_outlined),
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
  static const monthNames = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];

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
              items: years.map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  selectedYear = value;
                  if (!_isMonthEnabled(selectedMonth)) {
                    selectedMonth = List.generate(12, (i) => i + 1).where(_isMonthEnabled).first;
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
                return ChoiceChip(
                  label: Text(monthNames[index]),
                  selected: selectedMonth == month,
                  onSelected: _isMonthEnabled(month) ? (_) => setState(() => selectedMonth = month) : null,
                );
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(context, DateTime(selectedYear, selectedMonth)), child: const Text('Aceptar')),
      ],
    );
  }
}
