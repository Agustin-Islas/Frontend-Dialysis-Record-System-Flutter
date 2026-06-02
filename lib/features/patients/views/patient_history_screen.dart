import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend_dialysis_record/core/network/app_exception.dart';
import 'package:frontend_dialysis_record/features/auth/authController/auth_controller.dart';
import 'package:frontend_dialysis_record/features/auth/models/me_response.dart';
import 'package:frontend_dialysis_record/features/patients/patientController/patient_controller.dart';
import 'package:frontend_dialysis_record/features/patients/views/widgets/session_expansion_card.dart';
import 'package:frontend_dialysis_record/features/reports/monthly_dialysis_pdf_service.dart';
import 'package:frontend_dialysis_record/features/sessions/models/monthly_ultrafiltration_summary.dart';
import 'package:frontend_dialysis_record/features/sessions/models/session_dto.dart';
import 'package:frontend_dialysis_record/features/sessions/models/session_summary.dart';
import 'package:frontend_dialysis_record/features/sessions/views/session_create_bottom_sheet.dart';

class PatientHistoryScreen extends StatefulWidget {
  final MeResponse me;
  final AuthController authController;
  final PatientController patientController;

  const PatientHistoryScreen({
    super.key,
    required this.me,
    required this.authController,
    required this.patientController,
  });

  @override
  State<PatientHistoryScreen> createState() => _PatientHistoryScreenState();
}

class _PatientHistoryScreenState extends State<PatientHistoryScreen> {
  late DateTime _selectedMonth;
  late Future<List<SessionDto>> _sessionsFuture;

  final DateFormat _monthFormat = DateFormat('MMMM yyyy', 'es');
  final DateFormat _dayLabelFormat = DateFormat('EEEE dd/MM', 'es');
  final MonthlyDialysisPdfService _pdfService = MonthlyDialysisPdfService();
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
    final patientId = widget.me.id;
    if (patientId == null) return Future.value([]);

    return widget.patientController.getSessionsByDateRange(
      patientId: patientId,
      startDate: DateTime(_selectedMonth.year, _selectedMonth.month, 1),
      endDate: DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0),
    );
  }

  void _reload() => setState(_reloadFutures);

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
      final sessions = await _loadMonth();
      final summary = MonthlyUltrafiltrationCalculator.calculate(
        month: _selectedMonth,
        sessions: sessions,
      );
      final bytes = await _pdfService.buildMonthlyReport(
        patient: widget.me,
        month: _selectedMonth,
        sessions: sessions,
        summary: summary,
      );
      final name = (widget.me.name ?? 'paciente').replaceAll(RegExp(r'\s+'), '_').toLowerCase();
      final fileName = 'registro_dialisis_${name}_${_selectedMonth.year}_${_selectedMonth.month.toString().padLeft(2, '0')}.pdf';
      _pdfService.download(bytes, fileName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF generado')));
      }
    } catch (e) {
      final message = e is AppException ? e.message : 'No se pudo generar el PDF.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }

  Future<void> _editSession(SessionDto session) async {
    if (session.id == null) return;
    final initialDate = session.date != null ? DateTime.tryParse(session.date!) ?? DateTime.now() : DateTime.now();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SessionCreateBottomSheet(
        initialDate: initialDate,
        initialSession: session,
        customConcentrations: widget.me.customConcentrations,
        onSubmit: (data) async {
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
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cambio actualizado')));
          _reload();
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

    await widget.patientController.deleteSession(sessionId: session.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cambio eliminado')));
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
      for (final key in sortedKeys) key: (grouped[key]!..sort((a, b) => (a.bag ?? 999).compareTo(b.bag ?? 999)))
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
    return sessions.fold<int>(0, (total, session) => total + (session.partial ?? 0));
  }

  String _signed(int value) => value > 0 ? '+$value' : value.toString();

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
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _HistoryErrorState(
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

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(child: Text('Historial', style: Theme.of(context).textTheme.headlineSmall)),
                  FilledButton.icon(
                    onPressed: _generatingPdf ? null : _generatePdf,
                    icon: _generatingPdf
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('PDF'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _UltrafiltrationSummaryCard(summary: summary),
              const SizedBox(height: 12),
              _MonthFilterCard(monthLabel: monthLabel, onPickMonth: _pickMonth),
              const SizedBox(height: 12),
              if (sessions.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('No hay cambios registrados para $monthLabel.'),
                  ),
                )
              else
                ...grouped.entries.map((entry) {
                  final daySessions = entry.value;
                  final total = _dayTotal(daySessions);
                  final hasObservations = daySessions.any((session) => (session.observations ?? '').trim().isNotEmpty);
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                    child: ExpansionTile(
                      initiallyExpanded: false,
                      title: Row(
                        children: [
                          Expanded(child: Text(_formatDayTitle(entry.key), style: const TextStyle(fontWeight: FontWeight.w700))),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasObservations) ...[
                                Icon(Icons.sticky_note_2_outlined, size: 18, color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 8),
                              ],
                              Text('Cambios: ${daySessions.length}', style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(width: 12),
                              Text('Total: ${_signed(total)} ml', style: const TextStyle(fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ],
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
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
                    );
                }),
              const SizedBox(height: 24),
            ],
          );
        },
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
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Filtrar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onPickMonth,
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(monthLabel),
            ),
          ),
        ]),
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
      elevation: 0,
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Icon(Icons.monitor_heart_outlined, color: scheme.onPrimaryContainer),
              const SizedBox(width: 8),
              Text(
                'Resumen del mes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onPrimaryContainer,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Cambios totales', style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                '${summary.totalChanges}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth < 560 ? 2 : 4;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  mainAxisExtent: 78,
                ),
                itemBuilder: (context, index) => _WeeklyUfTile(
                  week: index + 1,
                  value: weeklyValues[index],
                ),
              );
            },
          ),
        ]),
      ),
    );
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Semana $week', style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('$value ml/dia', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _MonthSummaryCard extends StatelessWidget {
  final SessionSummary summary;

  const _MonthSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Resumen del mes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text('Cambios: ${summary.sessionsCount}')),
              Chip(label: Text('Drenaje: ${summary.totalDrainage} ml')),
              Chip(label: Text('Infusión: ${summary.totalInfusion} ml')),
              Chip(label: Text('Balance: ${summary.totalBalance} ml')),
            ],
          ),
        ]),
      ),
    );
  }
}

class _HistoryErrorState extends StatelessWidget {
  final String message;
  final String details;
  final VoidCallback onRetry;

  const _HistoryErrorState({
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
              items: years.map((year) => DropdownMenuItem(value: year, child: Text(year.toString()))).toList(),
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
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
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
        FilledButton(
          onPressed: () => Navigator.pop(context, DateTime(selectedYear, selectedMonth)),
          child: const Text('Aceptar'),
        ),
      ],
    );
  }
}
