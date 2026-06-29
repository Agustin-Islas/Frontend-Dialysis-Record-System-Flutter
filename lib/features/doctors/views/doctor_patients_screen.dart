import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:frontend_dialysis_record/core/design/design.dart';
import 'package:frontend_dialysis_record/core/providers/providers.dart';
import 'package:frontend_dialysis_record/core/router/app_router.dart';
import 'package:frontend_dialysis_record/core/widgets/widgets.dart';
import 'package:frontend_dialysis_record/core/network/app_exception.dart';
import 'package:frontend_dialysis_record/features/auth/models/me_response.dart';
import 'package:frontend_dialysis_record/features/doctors/providers/doctor_providers.dart';
import 'package:frontend_dialysis_record/features/patients/providers/patient_providers.dart';

class DoctorPatientsScreen extends ConsumerStatefulWidget {
  const DoctorPatientsScreen({super.key});

  @override
  ConsumerState<DoctorPatientsScreen> createState() => _DoctorPatientsScreenState();
}

class _DoctorPatientsScreenState extends ConsumerState<DoctorPatientsScreen> {
  Future<void> _addPatient(List<MeResponse> currentPatients) async {
    final currentIds = currentPatients.map((p) => p.id).whereType<String>().toSet();
    final id = await showDialog<String>(
      context: context,
      builder: (context) => _PatientPickerDialog(associatedIds: currentIds),
    );
    if (id == null || id.isEmpty) return;

    try {
      final ctrl = ref.read(doctorControllerProvider);
      await ctrl.addPatient(id);
      if (!mounted) return;
      AppSnackBar.success(context, 'Paciente asociado');
      ref.invalidate(doctorPatientsProvider);
    } catch (e) {
      final message = e is AppException ? e.message : 'No se pudo asociar el paciente.';
      if (mounted) AppSnackBar.error(context, message);
    }
  }

  Future<void> _removePatient(MeResponse patient) async {
    final id = patient.id;
    if (id == null) return;

    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Desasociar paciente',
      message: '¿Querés quitar a ${patient.name ?? "este paciente"} de tu lista?',
      confirmLabel: 'Quitar',
    );
    if (!confirmed) return;

    try {
      final ctrl = ref.read(doctorControllerProvider);
      await ctrl.removePatient(id);
      if (!mounted) return;
      AppSnackBar.success(context, 'Paciente desasociado');
      ref.invalidate(doctorPatientsProvider);
    } catch (e) {
      final message = e is AppException ? e.message : 'No se pudo desasociar el paciente.';
      if (mounted) AppSnackBar.error(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientsAsync = ref.watch(doctorPatientsProvider);

    return SafeArea(
      child: patientsAsync.when(
        loading: () => const AppSkeletonScreen(title: 'Pacientes', itemCount: 4),
        error: (error, _) => AppErrorCard(
          message: 'No se pudieron cargar los pacientes.',
          details: error.toString(),
          onRetry: () => ref.invalidate(doctorPatientsProvider),
        ),
        data: (patients) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Pacientes', style: Theme.of(context).textTheme.headlineSmall),
                      ),
                      FilledButton.icon(
                        onPressed: () => _addPatient(patients),
                        icon: const Icon(PhosphorIconsRegular.userPlus),
                        label: const Text('Agregar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (patients.isEmpty)
                    const AppEmptyState(
                      message: 'Todavía no tenés pacientes asociados.',
                      icon: PhosphorIconsRegular.usersThree,
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final cardWidth = constraints.maxWidth >= 760
                            ? (constraints.maxWidth - AppSpacing.md) / 2
                            : constraints.maxWidth;
                        return Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.md,
                          children: patients
                              .map(
                                (patient) => SizedBox(
                                  width: cardWidth,
                                  child: _PatientCard(
                                    patient: patient,
                                    onRemove: () => _removePatient(patient),
                                    onOpen: () {
                                      context.push(
                                        AppRoutes.doctorPatientDetail.replaceFirst(':patientId', patient.id!),
                                      );
                                    },
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      },
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

class _PatientCard extends StatelessWidget {
  final MeResponse patient;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  const _PatientCard({
    required this.patient,
    required this.onOpen,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final name = '${patient.name ?? "-"} ${patient.surname ?? ""}'.trim();
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
        title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(patient.dni != null ? 'DNI: ${patient.dni}' : patient.id ?? ''),
        trailing: IconButton(
          tooltip: 'Desasociar',
          onPressed: onRemove,
          icon: const Icon(PhosphorIconsRegular.linkBreak),
        ),
        onTap: onOpen,
      ),
    );
  }
}

class _PatientPickerDialog extends ConsumerStatefulWidget {
  final Set<String> associatedIds;

  const _PatientPickerDialog({required this.associatedIds});

  @override
  ConsumerState<_PatientPickerDialog> createState() => _PatientPickerDialogState();
}

class _PatientPickerDialogState extends ConsumerState<_PatientPickerDialog> {
  String _query = '';

  List<MeResponse> _filter(List<MeResponse> patients) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return patients;

    return patients.where((patient) {
      final haystack = [
        patient.name,
        patient.surname,
        patient.dni,
        patient.email,
      ].whereType<String>().join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final allPatientsAsync = ref.watch(allPatientsProvider);

    return AlertDialog(
      title: const Text('Agregar paciente'),
      contentPadding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
      content: SizedBox(
        width: 560,
        child: allPatientsAsync.when(
          loading: () => const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => SizedBox(
            height: 220,
            child: Center(child: Text('No se pudieron cargar los pacientes.\n$e', textAlign: TextAlign.center)),
          ),
          data: (patients) {
            final filtered = _filter(patients);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Buscar por nombre, DNI o email',
                    prefixIcon: Icon(PhosphorIconsRegular.magnifyingGlass),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: AppSpacing.md),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: filtered.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(AppSpacing.xl),
                            child: Text('No hay pacientes para mostrar.'),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final patient = filtered[index];
                            final id = patient.id;
                            final associated = id != null && widget.associatedIds.contains(id);
                            final name = '${patient.name ?? "-"} ${patient.surname ?? ""}'.trim();

                            return ListTile(
                              enabled: id != null && !associated,
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(child: Icon(PhosphorIconsRegular.user)),
                              title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text(patient.dni != null ? 'DNI: ${patient.dni}' : patient.email ?? ''),
                              trailing: associated
                                  ? const Chip(label: Text('Asociado'))
                                  : const Icon(PhosphorIconsRegular.plusCircle),
                              onTap: id == null || associated ? null : () => Navigator.pop(context, id),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
      ],
    );
  }
}
