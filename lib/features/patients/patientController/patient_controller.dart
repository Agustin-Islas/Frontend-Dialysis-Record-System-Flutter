import 'package:flutter/material.dart';
import 'package:frontend_dialysis_record/features/auth/models/me_response.dart';
import 'package:frontend_dialysis_record/features/patients/api/patient_api.dart';
import 'package:frontend_dialysis_record/features/sessions/models/session_dto.dart';
import 'package:frontend_dialysis_record/features/sessions/models/session_summary.dart';

class PatientController {
  final PatientApi patientApi;

  PatientController(this.patientApi);

  Future<List<SessionDto>> getSessionsByDay({
    required String patientId,
    required DateTime day,
  }) {
    return patientApi.getSessionsByDay(patientId: patientId, day: DateUtils.dateOnly(day));
  }

  Future<SessionSummary> getSessionSummaryByDay({
    required String patientId,
    required DateTime day,
  }) {
    return patientApi.getSessionSummaryByDay(patientId: patientId, day: DateUtils.dateOnly(day));
  }

  Future<SessionDto> createSession({
    required String patientId,
    required DateTime date,
    required TimeOfDay hour,
    required int bag,
    required double concentration,
    required int infusion,
    required int drainage,
    String? observations,
  }) {
    return patientApi.createSession(
      patientId: patientId,
      body: _sessionBody(
        date: date,
        hour: hour,
        bag: bag,
        concentration: concentration,
        infusion: infusion,
        drainage: drainage,
        observations: observations,
      ),
    );
  }

  Future<SessionDto> updateSession({
    required String sessionId,
    required DateTime date,
    required TimeOfDay hour,
    required int bag,
    required double concentration,
    required int infusion,
    required int drainage,
    String? observations,
  }) {
    return patientApi.updateSession(
      sessionId: sessionId,
      body: _sessionBody(
        date: date,
        hour: hour,
        bag: bag,
        concentration: concentration,
        infusion: infusion,
        drainage: drainage,
        observations: observations,
      ),
    );
  }

  Future<void> deleteSession({required String sessionId}) {
    return patientApi.deleteSession(sessionId: sessionId);
  }

  Future<List<SessionDto>> getSessionsByDateRange({
    required String patientId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return patientApi.getSessionsByDateRange(
      patientId: patientId,
      startDate: DateUtils.dateOnly(startDate),
      endDate: DateUtils.dateOnly(endDate),
    );
  }

  Future<SessionSummary> getSessionSummaryByMonth({
    required String patientId,
    required int year,
    required int month,
  }) {
    return patientApi.getSessionSummaryByMonth(patientId: patientId, year: year, month: month);
  }

  Future<MeResponse> getPatientById(String patientId) {
    return patientApi.getPatientById(patientId);
  }

  Future<MeResponse> updatePatient({
    required String patientId,
    required String name,
    required String surname,
    required int dni,
    required DateTime dateOfBirth,
    required String address,
    required int number,
    required List<double> customConcentrations,
  }) {
    return patientApi.updatePatient(
      patientId: patientId,
      body: {
        'id': patientId,
        'name': name,
        'surname': surname,
        'dni': dni,
        'dateOfBirth': _formatDate(dateOfBirth),
        'address': address,
        'number': number,
        'customConcentrations': customConcentrations,
      },
    );
  }

  Map<String, dynamic> _sessionBody({
    required DateTime date,
    required TimeOfDay hour,
    required int bag,
    required double concentration,
    required int infusion,
    required int drainage,
    String? observations,
  }) {
    String fmtTime(TimeOfDay t) {
      final hh = t.hour.toString().padLeft(2, '0');
      final mm = t.minute.toString().padLeft(2, '0');
      return '$hh:$mm:00';
    }

    return {
      'date': _formatDate(DateUtils.dateOnly(date)),
      'hour': fmtTime(hour),
      'bag': bag,
      'concentration': concentration,
      'infusion': infusion,
      'drainage': drainage,
      'observations': observations,
    };
  }

  String _formatDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }
}
