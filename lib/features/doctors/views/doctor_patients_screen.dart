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
  final _patientIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = widget.doctorController.getMyPatients();
  }

  @override
  void dispose() {
    _patientIdController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = widget.doctorController.getMyPatients();
    });
  }

  Future<void> _addPatient() async {
    _patientIdController.clear();
    final id = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Asociar paciente'),
        content: TextField(
          controller: _patientIdController,
          decoration: const InputDecoration(labelText: 'Patient ID'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, _patientIdController.text.trim()),
            child: const Text('Asociar'),
          ),
        ],
      ),
    );
    if (id == null || id.isEmpty) return;

    try {
      await widget.doctorController.addPatient(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paciente asociado')));
      _reload();
    } catch (e) {
      final message = e is AppException ? e.message : 'No se pudo asociar el paciente.';
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _removePatient(MeResponse patient) async {
    final id = patient.id;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desasociar paciente'),
        content: Text('¿Querés quitar a ${patient.name ?? "este paciente"} de tu lista?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Quitar')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await widget.doctorController.removePatient(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paciente desasociado')));
      _reload();
    } catch (e) {
      final message = e is AppException ? e.message : 'No se pudo desasociar el paciente.';
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<MeResponse>>(
        future: _future,
        builder: (context, snapshot) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Pacientes', style: Theme.of(context).textTheme.headlineSmall),
                  ),
                  IconButton(
                    onPressed: _addPatient,
                    tooltip: 'Asociar paciente',
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
              else if (snapshot.hasError)
                _StateCard(
                  title: 'No se pudieron cargar los pacientes.',
                  detail: snapshot.error.toString(),
                  onRetry: _reload,
                )
              else if ((snapshot.data ?? []).isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Todavía no tenés pacientes asociados.'),
                  ),
                )
              else
                ...(snapshot.data ?? []).map(
                  (patient) => Card(
                    child: ListTile(
                      title: Text('${patient.name ?? "-"} ${patient.surname ?? ""}'.trim()),
                      subtitle: Text(patient.dni != null ? 'DNI: ${patient.dni}' : patient.id ?? ''),
                      trailing: IconButton(
                        tooltip: 'Desasociar',
                        onPressed: () => _removePatient(patient),
                        icon: const Icon(Icons.link_off),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PatientDetailForDoctorScreen(
                              patient: patient,
                              patientController: widget.patientController,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  final String title;
  final String detail;
  final VoidCallback onRetry;

  const _StateCard({required this.title, required this.detail, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(detail, maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
        ]),
      ),
    );
  }
}
