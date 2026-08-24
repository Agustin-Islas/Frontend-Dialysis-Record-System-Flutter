import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:frontend_dialysis_record/core/design/design.dart';
import 'package:frontend_dialysis_record/core/widgets/widgets.dart';

class CustomConcentrationsEditor extends StatefulWidget {
  final List<double> initialConcentrations;

  const CustomConcentrationsEditor({
    super.key,
    required this.initialConcentrations,
  });

  static Future<List<double>?> show(
      BuildContext context, List<double> current) {
    return showModalBottomSheet<List<double>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: CustomConcentrationsEditor(initialConcentrations: current),
      ),
    );
  }

  @override
  State<CustomConcentrationsEditor> createState() =>
      _CustomConcentrationsEditorState();
}

class _CustomConcentrationsEditorState
    extends State<CustomConcentrationsEditor> {
  final _ctrl = TextEditingController();
  late List<double> _concentrations;

  static const _fixedConcentrations = [1.5, 2.3, 3.8];

  @override
  void initState() {
    super.initState();
    _concentrations = List.from(widget.initialConcentrations);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool _contains(List<double> values, double target) {
    return values.any((v) => (v - target).abs() < 0.0001);
  }

  void _add() {
    final raw = _ctrl.text.trim().replaceAll(',', '.');
    final value = double.tryParse(raw);
    if (value == null) {
      AppSnackBar.warning(context, 'Ingresá una concentración válida.');
      return;
    }
    final rounded = double.parse(value.toStringAsFixed(1));
    if (rounded < 0.1 ||
        rounded > 10.0 ||
        ((value * 10) - (value * 10).round()).abs() > 0.0001) {
      AppSnackBar.warning(
        context,
        'La concentración debe tener un decimal y estar entre 0.1 y 10.0.',
      );
      return;
    }
    if (_contains(_fixedConcentrations, rounded) ||
        _contains(_concentrations, rounded)) {
      AppSnackBar.info(context, 'Esa concentración ya existe.');
      return;
    }
    setState(() {
      _concentrations = [..._concentrations, rounded]..sort();
      _ctrl.clear();
    });
  }

  String _format(double value) {
    return value.toStringAsFixed(1).replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gestionar concentraciones',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.primary,
                    ),
              ),
              IconButton(
                icon: const Icon(PhosphorIconsRegular.x),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Agrega las concentraciones de líquido de diálisis que utilizas habitualmente (ej. 1,5%).',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Nueva concentración',
                    hintText: 'Ej: 4,2',
                  ),
                  onSubmitted: (_) => _add(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton.icon(
                onPressed: _add,
                icon: const Icon(PhosphorIconsRegular.plus),
                label: const Text('Agregar'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Tus concentraciones personalizadas',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_concentrations.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                'No has agregado ninguna concentración personalizada.',
                style: TextStyle(
                    color: scheme.onSurfaceVariant, fontStyle: FontStyle.italic),
              ),
            )
          else
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              children: _concentrations.map((val) {
                return Chip(
                  label: Text('${_format(val)}%'),
                  backgroundColor: scheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                  deleteIcon: Icon(
                    PhosphorIconsRegular.trash,
                    size: 16,
                    color: scheme.onPrimaryContainer,
                  ),
                  onDeleted: () {
                    setState(() {
                      _concentrations.remove(val);
                    });
                  },
                );
              }).toList(),
            ),
          const SizedBox(height: AppSpacing.xxl),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(context, _concentrations);
              },
              child: const Text('Guardar cambios'),
            ),
          ),
        ],
      ),
    );
  }
}
