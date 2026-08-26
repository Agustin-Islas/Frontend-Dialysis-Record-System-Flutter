import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_dialysis_record/core/providers/providers.dart';
import 'package:frontend_dialysis_record/features/auth/providers/auth_providers.dart';
import 'package:frontend_dialysis_record/features/sessions/models/session_dto.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class SessionCreateFormData {
  final DateTime date;
  final TimeOfDay hour;
  final int bag;
  final double concentration;
  final int infusion;
  final int drainage;
  final String? observations;

  SessionCreateFormData({
    required this.date,
    required this.hour,
    required this.bag,
    required this.concentration,
    required this.infusion,
    required this.drainage,
    this.observations,
  });
}

class SessionCreateBottomSheet extends ConsumerStatefulWidget {
  final Future<void> Function(SessionCreateFormData data) onSubmit;
  final DateTime initialDate;
  final SessionDto? initialSession;
  final List<double> customConcentrations;
  final List<SessionDto> existingSessions;

  const SessionCreateBottomSheet({
    super.key,
    required this.onSubmit,
    required this.initialDate,
    this.initialSession,
    this.customConcentrations = const [],
    this.existingSessions = const [],
  });

  @override
  ConsumerState<SessionCreateBottomSheet> createState() =>
      _SessionCreateBottomSheetState();
}

class _SessionCreateBottomSheetState
    extends ConsumerState<SessionCreateBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _date;
  late TimeOfDay _time;

  final _bagCtrl = TextEditingController();
  final _infusionCtrl = TextEditingController();
  final _drainageCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();

  double? _selectedConcentration = 1.5;
  bool _loading = false;

  bool get _isEditing => widget.initialSession != null;
  static const _fixedConcentrations = [
    _ConcentrationOption(label: 'Amarillo', value: 1.5),
    _ConcentrationOption(label: 'Verde', value: 2.3),
    _ConcentrationOption(label: 'Rojo', value: 3.8),
  ];

  bool _isSameDay(String? dateStr, DateTime target) {
    if (dateStr == null || dateStr.isEmpty) return false;
    final isoStr = DateUtils.dateOnly(
      target,
    ).toIso8601String().substring(0, 10);
    if (dateStr.startsWith(isoStr)) return true;
    final parsed = DateTime.tryParse(dateStr);
    if (parsed != null) {
      return parsed.year == target.year &&
          parsed.month == target.month &&
          parsed.day == target.day;
    }
    final dayStr = target.day.toString().padLeft(2, '0');
    final monthStr = target.month.toString().padLeft(2, '0');
    final yearStr = target.year.toString();
    if (dateStr.startsWith('$dayStr/$monthStr/$yearStr') ||
        dateStr.startsWith('$dayStr-$monthStr-$yearStr')) {
      return true;
    }
    return false;
  }

  DateTime _computeClinicalDate(DateTime calendarDate, TimeOfDay timeOfDay) {
    if (timeOfDay.hour < 5) {
      return DateUtils.dateOnly(calendarDate.subtract(const Duration(days: 1)));
    }
    return DateUtils.dateOnly(calendarDate);
  }

  int _calculateSuggestedBag() {
    final targetClinical = _computeClinicalDate(_date, _time);
    final targetIso = targetClinical.toIso8601String().substring(0, 10);
    int count = 0;
    for (final s in widget.existingSessions) {
      if (s.effectiveDate != null && s.effectiveDate!.startsWith(targetIso)) {
        count++;
      } else if (_isSameDay(s.date, targetClinical)) {
        count++;
      }
    }
    return count + 1;
  }

  Future<void> _fetchSuggestedBag() async {
    if (_isEditing) return;
    try {
      final me = ref.read(authStateProvider).valueOrNull;
      final patientId = me?.id;
      if (patientId == null) return;
      final targetClinical = _computeClinicalDate(_date, _time);
      final patientCtrl = ref.read(patientControllerProvider);
      final sessions = await patientCtrl.getSessionsByDay(
        patientId: patientId,
        day: targetClinical,
      );
      if (mounted &&
          _computeClinicalDate(_date, _time) == targetClinical &&
          !_isEditing) {
        setState(() {
          _bagCtrl.text = (sessions.length + 1).toString();
        });
      }
    } catch (_) {
      // Ignorar fallo de red y mantener valor local
    }
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    final iso = DateTime.tryParse(dateStr);
    if (iso != null) return iso;
    final parts = dateStr.split(RegExp(r'[/.-]'));
    if (parts.length == 3) {
      final d = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final y = int.tryParse(parts[2]);
      if (d != null && m != null && y != null) {
        if (y > 1000 && m >= 1 && m <= 12 && d >= 1 && d <= 31) {
          return DateTime(y, m, d);
        }
        if (d > 1000 && m >= 1 && m <= 12 && y >= 1 && y <= 31) {
          return DateTime(d, m, y);
        }
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final session = widget.initialSession;
    _date = _parseDate(session?.date) ?? widget.initialDate;
    _time = _parseTime(session?.hour) ?? TimeOfDay.now();
    if (session != null && session.bag != null) {
      _bagCtrl.text = session.bag!.toString();
    } else {
      _bagCtrl.text = _calculateSuggestedBag().toString();
      _fetchSuggestedBag();
    }
    _infusionCtrl.text = session?.infusion?.toString() ?? '';
    _drainageCtrl.text = session?.drainage?.toString() ?? '';
    _obsCtrl.text = session?.observations ?? '';
    _selectedConcentration = session?.concentration;
  }

  @override
  void dispose() {
    _bagCtrl.dispose();
    _infusionCtrl.dispose();
    _drainageCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  TimeOfDay? _parseTime(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  int? _parseInt(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    final v = int.tryParse(t);
    if (v == null || v < 0) return null;
    return v;
  }

  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$day/$m/$y';
  }

  Future<void> _pickDate() async {
    final now = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('es', 'ES'),
      initialDate: _date.isAfter(now) ? now : _date,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );

    if (picked != null) {
      setState(() {
        _date = DateUtils.dateOnly(picked);
        if (!_isEditing) {
          _bagCtrl.text = _calculateSuggestedBag().toString();
        }
      });
      if (!_isEditing) {
        _fetchSuggestedBag();
      }
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _time = picked;
        if (!_isEditing) {
          _bagCtrl.text = _calculateSuggestedBag().toString();
        }
      });
      if (!_isEditing) {
        _fetchSuggestedBag();
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedConcentration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una concentración')),
      );
      return;
    }

    final data = SessionCreateFormData(
      date: _date,
      hour: _time,
      bag: _parseInt(_bagCtrl.text)!,
      concentration: _selectedConcentration!,
      infusion: _parseInt(_infusionCtrl.text)!,
      drainage: _parseInt(_drainageCtrl.text)!,
      observations: _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
    );

    setState(() => _loading = true);
    try {
      await widget.onSubmit(data);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _requiredInt(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label requerido';
    if (_parseInt(value) == null) return 'Numero invalido';
    return null;
  }

  List<_ConcentrationOption> _concentrationOptions() {
    final options = [..._fixedConcentrations];
    final custom = [...widget.customConcentrations]..sort();
    for (final value in custom) {
      if (!options.any((option) => _same(option.value, value))) {
        options.add(_ConcentrationOption(label: 'Personalizada', value: value));
      }
    }
    final selected = _selectedConcentration;
    if (selected != null &&
        !options.any((option) => _same(option.value, selected))) {
      options.add(_ConcentrationOption(label: 'Actual', value: selected));
    }
    return options;
  }

  bool _same(double a, double b) => (a - b).abs() < 0.0001;

  String _formatConcentration(double value) {
    return value.toStringAsFixed(1).replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: bottom + 16,
      ),
      child: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: scheme.outlineVariant.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _isEditing ? 'Editar cambio' : 'Nuevo cambio',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface,
                          ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Bolsa N° ${_bagCtrl.text.isEmpty ? "-" : _bagCtrl.text}',
                        style: TextStyle(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Date and Time Row
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _loading ? null : _pickDate,
                        borderRadius: BorderRadius.circular(8),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Fecha',
                            prefixIcon: Icon(PhosphorIconsRegular.calendarBlank, size: 20),
                          ),
                          child: Text(_formatDate(_date), style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _loading ? null : _pickTime,
                        borderRadius: BorderRadius.circular(8),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Hora',
                            prefixIcon: Icon(PhosphorIconsRegular.clock, size: 20),
                          ),
                          child: Text(
                            '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Concentration
                Text(
                  'Concentración',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _concentrationOptions().map((option) {
                    final isSelected = _same(_selectedConcentration ?? -1.0, option.value);
                    return ChoiceChip(
                      label: Text('${option.label} (${_formatConcentration(option.value)}%)'),
                      labelStyle: TextStyle(
                        color: isSelected ? scheme.onPrimary : scheme.onSurface,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      selectedColor: scheme.primary,
                      backgroundColor: scheme.surface,
                      side: BorderSide(
                        color: isSelected ? scheme.primary : scheme.outlineVariant,
                      ),
                      showCheckmark: false,
                      selected: isSelected,
                      onSelected: _loading ? null : (selected) {
                        if (selected) {
                          setState(() => _selectedConcentration = option.value);
                        }
                      },
                    );
                  }).toList(),
                ),
                if (_selectedConcentration == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      'Requerido',
                      style: TextStyle(color: scheme.error, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 20),

                // Fluids
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _infusionCtrl,
                        enabled: !_loading,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Infusión (ml)',
                          prefixIcon: Icon(PhosphorIconsRegular.drop, size: 20),
                        ),
                        validator: (v) => _requiredInt(v, 'Infusión'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _drainageCtrl,
                        enabled: !_loading,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Drenaje (ml)',
                          prefixIcon: Icon(PhosphorIconsRegular.dropHalfBottom, size: 20),
                        ),
                        validator: (v) => _requiredInt(v, 'Drenaje'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Observations
                TextFormField(
                  controller: _obsCtrl,
                  enabled: !_loading,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Observaciones'),
                  validator: (v) => (v ?? '').length > 500 ? 'Máximo 500 caracteres' : null,
                ),
                if (_time.hour < 5) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.amber.shade700,
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.nightlight_round,
                          color: Colors.amber.shade800,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Turno trasnoche: Al ser antes de las 05:00 AM, este recambio se asociará al historial médico del día anterior (${_formatDate(_computeClinicalDate(_date, _time))}).',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.amber.shade900,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _submit,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      _loading
                          ? 'Guardando...'
                          : (_isEditing ? 'Guardar cambios' : 'Crear cambio'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConcentrationOption {
  final String label;
  final double value;

  const _ConcentrationOption({required this.label, required this.value});
}
