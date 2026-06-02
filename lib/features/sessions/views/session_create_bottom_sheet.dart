import 'package:flutter/material.dart';
import 'package:frontend_dialysis_record/features/sessions/models/session_dto.dart';

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

class SessionCreateBottomSheet extends StatefulWidget {
  final Future<void> Function(SessionCreateFormData data) onSubmit;
  final DateTime initialDate;
  final SessionDto? initialSession;
  final List<double> customConcentrations;

  const SessionCreateBottomSheet({
    super.key,
    required this.onSubmit,
    required this.initialDate,
    this.initialSession,
    this.customConcentrations = const [],
  });

  @override
  State<SessionCreateBottomSheet> createState() => _SessionCreateBottomSheetState();
}

class _SessionCreateBottomSheetState extends State<SessionCreateBottomSheet> {
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
    _ConcentrationOption(label: 'Verde', value: 2.4),
    _ConcentrationOption(label: 'Rojo', value: 3.8),
  ];

  @override
  void initState() {
    super.initState();
    final session = widget.initialSession;
    _date = session?.date != null ? DateTime.tryParse(session!.date!) ?? widget.initialDate : widget.initialDate;
    _time = _parseTime(session?.hour) ?? TimeOfDay.now();
    _bagCtrl.text = session?.bag?.toString() ?? '';
    _infusionCtrl.text = session?.infusion?.toString() ?? '';
    _drainageCtrl.text = session?.drainage?.toString() ?? '';
    _obsCtrl.text = session?.observations ?? '';
    _selectedConcentration = session?.concentration ?? 1.5;
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
      initialDate: _date.isAfter(now) ? now : _date,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );

    if (picked != null) setState(() => _date = DateUtils.dateOnly(picked));
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

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
    if (selected != null && !options.any((option) => _same(option.value, selected))) {
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

    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: bottom + 16),
      child: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Editar cambio' : 'Nuevo cambio',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _loading ? null : _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Fecha'),
                    child: Row(
                      children: [
                        Expanded(child: Text(_formatDate(_date))),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _loading ? null : _pickTime,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Hora'),
                    child: Row(
                      children: [
                        Expanded(child: Text(_time.format(context))),
                        const Icon(Icons.schedule),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _bagCtrl,
                        enabled: !_loading,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Bolsa'),
                        validator: (v) => _requiredInt(v, 'Bolsa'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<double>(
                        initialValue: _selectedConcentration,
                        decoration: const InputDecoration(labelText: 'Concentracion'),
                        items: _concentrationOptions()
                            .map(
                              (option) => DropdownMenuItem(
                                value: option.value,
                                child: Text('${option.label} (${_formatConcentration(option.value)}%)'),
                              ),
                            )
                            .toList(),
                        onChanged: _loading ? null : (value) => setState(() => _selectedConcentration = value),
                        validator: (value) => value == null ? 'Selecciona una opcion' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _infusionCtrl,
                        enabled: !_loading,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Infusion (ml)'),
                        validator: (v) => _requiredInt(v, 'Infusion'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _drainageCtrl,
                        enabled: !_loading,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Drenaje (ml)'),
                        validator: (v) => _requiredInt(v, 'Drenaje'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _obsCtrl,
                  enabled: !_loading,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Observaciones'),
                  validator: (v) => (v ?? '').length > 500 ? 'Maximo 500 caracteres' : null,
                ),
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
                    label: Text(_loading ? 'Guardando...' : (_isEditing ? 'Guardar cambios' : 'Crear cambio')),
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
