import 'package:flutter/material.dart';
import 'package:frontend_dialysis_record/core/network/app_exception.dart';
import 'package:frontend_dialysis_record/features/auth/models/me_response.dart';
import 'package:frontend_dialysis_record/features/doctors/doctorController/doctor_controller.dart';
import 'package:frontend_dialysis_record/features/doctors/views/patient_detail_for_doctor_screen.dart';
import 'package:frontend_dialysis_record/features/patients/patientController/patient_controller.dart';

class DoctorPatientsScreen extends StatefulWidget {
  final DoctorController doctorController;
  final PatientController patientController;

  const DoctorPatientsScreen({
    super.key,
    required this.doctorController,
    required this.patientController,
  });

  @override
  State<DoctorPatientsScreen> createState() => _DoctorPatientsScreenState();
}

class _DoctorPatientsScreenState extends State<DoctorPatientsScreen> {
  late Future<List<MeResponse>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.doctorController.getMyPatients();
  }

  void _reload() {
    setState(() {
      _future = widget.doctorController.getMyPatients();
    });
  }

  Future<void> _addPatient(List<MeResponse> currentPatients) async {
    final currentIds = currentPatients
        .map((patient) => patient.id)
        .whereType<String>()
        .toSet();
    final id = await showDialog<String>(
      context: context,
      builder: (context) => _PatientPickerDialog(
        patientsFuture: widget.patientController.getAllPatients(),
        associatedIds: currentIds,
      ),
    );
    if (id == null || id.isEmpty) return;

    try {
      await widget.doctorController.addPatient(id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Paciente asociado')));
      _reload();
    } catch (e) {
      final message = e is AppException
          ? e.message
          : 'No se pudo asociar el paciente.';
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _removePatient(MeResponse patient) async {
    final id = patient.id;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desasociar paciente'),
        content: Text(
          '¿Querés quitar a ${patient.name ?? "este paciente"} de tu lista?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await widget.doctorController.removePatient(id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Paciente desasociado')));
      _reload();
    } catch (e) {
      final message = e is AppException
          ? e.message
          : 'No se pudo desasociar el paciente.';
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<MeResponse>>(
        future: _future,
        builder: (context, snapshot) {
          final patients = snapshot.data ?? [];
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: ListView(
                padding: const EdgeInsets.all(16),
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
                        onPressed:
                            snapshot.connectionState == ConnectionState.waiting
                            ? null
                            : () => _addPatient(patients),
                        icon: const Icon(Icons.person_add_alt_1_outlined),
                        label: const Text('Agregar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (snapshot.hasError)
                    _StateCard(
                      title: 'No se pudieron cargar los pacientes.',
                      detail: snapshot.error.toString(),
                      onRetry: _reload,
                    )
                  else if (patients.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Todavía no tenés pacientes asociados.'),
                      ),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final cardWidth = constraints.maxWidth >= 760
                            ? (constraints.maxWidth - 12) / 2
                            : constraints.maxWidth;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: patients
                              .map(
                                (patient) => SizedBox(
                                  width: cardWidth,
                                  child: _PatientCard(
                                    patient: patient,
                                    onRemove: () => _removePatient(patient),
                                    onOpen: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              PatientDetailForDoctorScreen(
                                                patient: patient,
                                                patientController:
                                                    widget.patientController,
                                              ),
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
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          patient.dni != null ? 'DNI: ${patient.dni}' : patient.id ?? '',
        ),
        trailing: IconButton(
          tooltip: 'Desasociar',
          onPressed: onRemove,
          icon: const Icon(Icons.link_off),
        ),
        onTap: onOpen,
      ),
    );
  }
}

class _PatientPickerDialog extends StatefulWidget {
  final Future<List<MeResponse>> patientsFuture;
  final Set<String> associatedIds;

  const _PatientPickerDialog({
    required this.patientsFuture,
    required this.associatedIds,
  });

  @override
  State<_PatientPickerDialog> createState() => _PatientPickerDialogState();
}

class _PatientPickerDialogState extends State<_PatientPickerDialog> {
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
    return AlertDialog(
      title: const Text('Agregar paciente'),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      content: SizedBox(
        width: 560,
        child: FutureBuilder<List<MeResponse>>(
          future: widget.patientsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return SizedBox(
                height: 220,
                child: Center(
                  child: Text(
                    'No se pudieron cargar los pacientes.\n${snapshot.error}',
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final patients = _filter(snapshot.data ?? []);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Buscar por nombre, DNI o email',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: patients.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('No hay pacientes para mostrar.'),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: patients.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final patient = patients[index];
                            final id = patient.id;
                            final associated =
                                id != null && widget.associatedIds.contains(id);
                            final name =
                                '${patient.name ?? "-"} ${patient.surname ?? ""}'
                                    .trim();

                            return ListTile(
                              enabled: id != null && !associated,
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(
                                child: Icon(Icons.person_outline),
                              ),
                              title: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                patient.dni != null
                                    ? 'DNI: ${patient.dni}'
                                    : patient.email ?? '',
                              ),
                              trailing: associated
                                  ? const Chip(label: Text('Asociado'))
                                  : const Icon(Icons.add_circle_outline),
                              onTap: id == null || associated
                                  ? null
                                  : () => Navigator.pop(context, id),
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
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

class _StateCard extends StatelessWidget {
  final String title;
  final String detail;
  final VoidCallback onRetry;

  const _StateCard({
    required this.title,
    required this.detail,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(detail, maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
