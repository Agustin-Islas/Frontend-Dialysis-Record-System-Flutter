import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend_dialysis_record/core/network/app_exception.dart';
import 'package:frontend_dialysis_record/features/auth/models/me_response.dart';
import 'package:frontend_dialysis_record/features/patients/patientController/patient_controller.dart';
import 'package:frontend_dialysis_record/features/patients/views/widgets/session_expansion_card.dart';
import 'package:frontend_dialysis_record/features/reports/monthly_dialysis_pdf_service.dart';
import 'package:frontend_dialysis_record/features/sessions/models/monthly_ultrafiltration_summary.dart';
import 'package:frontend_dialysis_record/features/sessions/models/session_dto.dart';

class PatientDetailForDoctorScreen extends StatefulWidget {
  final MeResponse patient;
  final PatientController patientController;

  const PatientDetailForDoctorScreen({
    super.key,
    required this.patient,
    required this.patientController,
  });

  @override
  State<PatientDetailForDoctorScreen> createState() => _PatientDetailForDoctorScreenState();
}

class _PatientDetailForDoctorScreenState extends State<PatientDetailForDoctorScreen> {
  late DateTime _selectedMonth;
  late Future<List<SessionDto>> _sessionsFuture;

  final DateFormat _monthFormat = DateFormat('MMMM yyyy', 'es');
  final DateFormat _dayFormat = DateFormat('EEEE dd/MM', 'es');
  final MonthlyDialysisPdfService _pdfService = MonthlyDialysisPdfService();
  bool _generatingPdf = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _sessionsFuture = _loadSessions();
  }

  Future<List<SessionDto>> _loadSessions() {
    final patientId = widget.patient.id;
    if (patientId == null) return Future.value([]);

    return widget.patientController.getSessionsByDateRange(
      patientId: patientId,
      startDate: DateTime(_selectedMonth.year, _selectedMonth.month, 1),
      endDate: DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0),
    );
  }

  void _reload() {
    setState(() {
      _sessionsFuture = _loadSessions();
    });
  }

  void _changeMonth(int delta) {
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + delta);
    final currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
    if (next.isAfter(currentMonth)) return;

    setState(() {
      _selectedMonth = next;
      _sessionsFuture = _loadSessions();
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
      _sessionsFuture = _loadSessions();
    });
  }

  Future<void> _generatePdf(List<SessionDto> sessions) async {
    setState(() => _generatingPdf = true);
    try {
      final summary = MonthlyUltrafiltrationCalculator.calculate(
        month: _selectedMonth,
        sessions: sessions,
      );
      final bytes = await _pdfService.buildMonthlyReport(
        patient: widget.patient,
        month: _selectedMonth,
        sessions: sessions,
        summary: summary,
      );
      final name = (widget.patient.name ?? 'paciente').replaceAll(RegExp(r'\s+'), '_').toLowerCase();
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

  Map<String, List<SessionDto>> _groupByDay(List<SessionDto> sessions) {
    final grouped = <String, List<SessionDto>>{};
    for (final session in sessions) {
      final key = session.date ?? 'Sin fecha';
      grouped.putIfAbsent(key, () => []).add(session);
    }
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    return {
      for (final key in sortedKeys) key: (grouped[key]!..sort((a, b) => (a.bag ?? 999).compareTo(b.bag ?? 999))),
    };
  }

  String _monthLabel() {
    final value = _monthFormat.format(_selectedMonth);
    return value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
  }

  String _formatDayTitle(String isoDate) {
    final parsed = DateTime.tryParse(isoDate);
    if (parsed == null) return isoDate;
    return _capitalize(_dayFormat.format(parsed));
  }

  int _dayTotal(List<SessionDto> sessions) {
    return sessions.fold<int>(0, (total, session) => total + (session.partial ?? 0));
  }

  String _signed(int value) => value > 0 ? '+$value' : value.toString();

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final patientName = '${widget.patient.name ?? "-"} ${widget.patient.surname ?? ""}'.trim();
    final currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
    final canGoForward = DateTime(_selectedMonth.year, _selectedMonth.month + 1).isBefore(currentMonth) ||
        DateTime(_selectedMonth.year, _selectedMonth.month + 1).isAtSameMomentAs(currentMonth);

    return Scaffold(
      appBar: AppBar(title: Text(patientName)),
      body: SafeArea(
        child: FutureBuilder<List<SessionDto>>(
          future: _sessionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('No se pudo cargar el paciente.', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(snapshot.error.toString(), maxLines: 4, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _reload, child: const Text('Reintentar')),
                    ]),
                  ),
                ),
              );
            }

            final sessions = snapshot.data ?? [];
            final summary = MonthlyUltrafiltrationCalculator.calculate(
              month: _selectedMonth,
              sessions: sessions,
            );
            final grouped = _groupByDay(sessions);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _PatientMonthPanel(
                  patient: widget.patient,
                  patientName: patientName,
                  summary: summary,
                  monthLabel: _monthLabel(),
                ),
                const SizedBox(height: 12),
                _MonthFilterCard(monthLabel: _monthLabel(), onPickMonth: _pickMonth),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
                            FilledButton.icon(
                              onPressed: _generatingPdf ? null : () => _generatePdf(sessions),
                              icon: _generatingPdf
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.picture_as_pdf_outlined),
                              label: const Text('PDF'),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: sessions.isEmpty
                            ? const Text('No hay cambios registrados para este mes.')
                            : Column(
                                children: grouped.entries.map((entry) {
                                  final daySessions = entry.value;
                                  final total = _dayTotal(daySessions);
                                  final hasObservations =
                                      daySessions.any((session) => (session.observations ?? '').trim().isNotEmpty);
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
                                          Expanded(
                                            child: Text(
                                              _formatDayTitle(entry.key),
                                              style: const TextStyle(fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (hasObservations) ...[
                                                Icon(
                                                  Icons.sticky_note_2_outlined,
                                                  size: 18,
                                                  color: Theme.of(context).colorScheme.primary,
                                                ),
                                                const SizedBox(width: 8),
                                              ],
                                              Text('Cambios: ${daySessions.length}',
                                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                                              const SizedBox(width: 12),
                                              Text('Total: ${_signed(total)} ml',
                                                  style: const TextStyle(fontWeight: FontWeight.w700)),
                                            ],
                                          ),
                                        ],
                                      ),
                                      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                      children: daySessions.map((session) => SessionExpansionCard(session: session)).toList(),
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
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            patientName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onPrimaryContainer,
                ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              if (patient.email != null) Text(patient.email!, style: TextStyle(color: scheme.onPrimaryContainer)),
              if (patient.dni != null) Text('DNI: ${patient.dni}', style: TextStyle(color: scheme.onPrimaryContainer)),
              Text(monthLabel, style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w700)),
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
                itemBuilder: (context, index) => _DoctorWeeklyUfTile(
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

class _DoctorWeeklyUfTile extends StatelessWidget {
  final int week;
  final int value;

  const _DoctorWeeklyUfTile({required this.week, required this.value});

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
