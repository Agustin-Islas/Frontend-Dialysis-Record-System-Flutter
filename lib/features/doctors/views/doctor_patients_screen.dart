import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:frontend_dialysis_record/core/design/design.dart';
import 'package:frontend_dialysis_record/core/providers/providers.dart';
import 'package:frontend_dialysis_record/core/router/app_router.dart';
import 'package:frontend_dialysis_record/core/widgets/widgets.dart';
import 'package:frontend_dialysis_record/features/auth/models/me_response.dart';
import 'package:frontend_dialysis_record/features/doctors/providers/doctor_providers.dart';

class DoctorPatientsScreen extends ConsumerStatefulWidget {
  const DoctorPatientsScreen({super.key});

  @override
  ConsumerState<DoctorPatientsScreen> createState() =>
      _DoctorPatientsScreenState();
}

class _DoctorPatientsScreenState extends ConsumerState<DoctorPatientsScreen> {
  Future<void> _addPatient() async {
    final success = await showDialog<bool>(
      context: context,
      builder: (context) => const _PatientInviteDialog(),
    );
    if (success != true) return;

    if (!mounted) return;
    AppSnackBar.success(context, 'Invitación enviada correctamente.');
  }

  Future<void> _removePatient(MeResponse patient) async {
    final id = patient.id;
    if (id == null) return;

    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Desasociar paciente',
      message:
          '¿Querés quitar a ${patient.name ?? "este paciente"} de tu lista?',
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
      if (mounted) {
        AppSnackBar.showException(
          context,
          e,
          'No se pudo desasociar el paciente.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientsAsync = ref.watch(doctorPatientsProvider);

    return SafeArea(
      child: patientsAsync.when(
        loading: () =>
            const AppSkeletonScreen(title: 'Pacientes', itemCount: 4),
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
                        child: Text(
                          'Pacientes',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _addPatient,
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
                                        AppRoutes.doctorPatientDetail
                                            .replaceFirst(
                                              ':patientId',
                                              patient.id!,
                                            ),
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
        contentPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          patient.dni != null ? 'DNI: ${patient.dni}' : patient.id ?? '',
        ),
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

class _PatientInviteDialog extends ConsumerStatefulWidget {
  const _PatientInviteDialog();

  @override
  ConsumerState<_PatientInviteDialog> createState() =>
      _PatientInviteDialogState();
}

class _PatientInviteDialogState extends ConsumerState<_PatientInviteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _dniCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _dniCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailCtrl.text.trim();
    final dniStr = _dniCtrl.text.trim();
    final dni = dniStr.isNotEmpty ? int.tryParse(dniStr) : null;

    if (email.isEmpty && dni == null) {
      AppSnackBar.error(context, 'Debes ingresar un Email o un DNI.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final ctrl = ref.read(invitationControllerProvider);
      await ctrl.createInvitation(
        patientEmail: email.isEmpty ? null : email,
        patientDni: dni,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        AppSnackBar.showException(
          context,
          e,
          'No se pudo enviar la invitación.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Invitar paciente'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Ingresá el Email o DNI del paciente para enviarle una invitación de vinculación. El paciente deberá aceptarla desde su cuenta.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email del paciente',
                  prefixIcon: Icon(PhosphorIconsRegular.envelope),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  'O',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              TextFormField(
                controller: _dniCtrl,
                decoration: const InputDecoration(
                  labelText: 'DNI del paciente',
                  prefixIcon: Icon(PhosphorIconsRegular.identificationCard),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enviar invitación'),
        ),
      ],
    );
  }
}
