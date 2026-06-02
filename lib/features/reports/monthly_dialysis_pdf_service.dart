import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:universal_html/html.dart' as html;
import 'package:frontend_dialysis_record/features/auth/models/me_response.dart';
import 'package:frontend_dialysis_record/features/sessions/models/monthly_ultrafiltration_summary.dart';
import 'package:frontend_dialysis_record/features/sessions/models/session_dto.dart';

class MonthlyDialysisPdfService {
  final DateFormat _monthFormat = DateFormat('MMMM yyyy', 'es');
  final DateFormat _dateFormat = DateFormat('dd/MM');
  static const PdfColor _primary = PdfColor.fromInt(0xFF256D85);
  static const PdfColor _primaryLight = PdfColor.fromInt(0xFFE7F3F7);

  Future<Uint8List> buildMonthlyReport({
    required MeResponse patient,
    required DateTime month,
    required List<SessionDto> sessions,
    required MonthlyUltrafiltrationSummary summary,
  }) async {
    final document = pw.Document();
    final sorted = [...sessions]..sort((a, b) {
        final dateCompare = (a.date ?? '').compareTo(b.date ?? '');
        if (dateCompare != 0) return dateCompare;
        return (a.hour ?? '').compareTo(b.hour ?? '');
      });

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _header(patient, _capitalize(_monthFormat.format(month))),
          pw.SizedBox(height: 12),
          _summary(summary),
          pw.SizedBox(height: 12),
          _recordsTable(_groupByDate(sorted)),
          pw.SizedBox(height: 10),
          pw.Text(
            'Reporte generado digitalmente desde Dialysis Record App.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ],
      ),
    );

    return document.save();
  }

  void download(Uint8List bytes, String filename) {
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = filename
      ..style.display = 'none';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }

  pw.Widget _header(MeResponse patient, String monthLabel) {
    final fullName = '${patient.name ?? "-"} ${patient.surname ?? ""}'.trim();
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _primaryLight,
        border: pw.Border.all(color: _primary, width: 0.8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Registro mensual de diálisis peritoneal',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _primary),
                ),
                pw.SizedBox(height: 4),
                pw.Text('Paciente: $fullName', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                if (patient.dni != null) pw.Text('DNI: ${patient.dni}', style: const pw.TextStyle(fontSize: 10)),
                if (patient.doctorName != null) pw.Text('Médico: ${patient.doctorName}', style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              border: pw.Border.all(color: _primary, width: 0.7),
            ),
            child: pw.Text(monthLabel, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  pw.Widget _summary(MonthlyUltrafiltrationSummary summary) {
    pw.Widget item(String label, String value) {
      return pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(7),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400, width: 0.5)),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
              pw.SizedBox(height: 2),
              pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    return pw.Row(
      children: [
        item('Total de cambios', summary.totalChanges.toString()),
        item('UF semana 1', '${summary.weeklyUltrafiltration[0]} ml/dia'),
        item('UF semana 2', '${summary.weeklyUltrafiltration[1]} ml/dia'),
        item('UF semana 3', '${summary.weeklyUltrafiltration[2]} ml/dia'),
        item('UF semana 4', '${summary.weeklyUltrafiltration[3]} ml/dia'),
      ],
    );
  }

  pw.Widget _recordsTable(Map<String, List<SessionDto>> grouped) {
    const rowHeight = 22.0;
    if (grouped.isEmpty) {
      return pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.45),
        children: [
          pw.TableRow(children: [_bodyCell('Sin registros para el mes seleccionado', colspanStyle: true)]),
        ],
      );
    }

    final blocks = <pw.Widget>[_tableHeader()];
    grouped.forEach((date, sessions) {
      final ordered = [...sessions]..sort((a, b) => (a.bag ?? 999).compareTo(b.bag ?? 999));
      blocks.add(_dayBlock(date: date, sessions: ordered, rowHeight: rowHeight));
    });
    return pw.Column(children: blocks);
  }

  pw.Widget _tableHeader() {
    return pw.Row(
      children: [
        _headerBox('Fecha', width: 58),
        _headerBox('Hora', width: 40),
        _headerBox('Bolsa', width: 42),
        _headerBox('Concentración', width: 74),
        _headerBox('Infusión', width: 58),
        _headerBox('Drenaje', width: 58),
        _headerBox('Parcial', width: 52),
        _headerBox('Total', width: 54),
        _headerBox('Observación', flex: 1),
      ],
    );
  }

  pw.Widget _dayBlock({
    required String date,
    required List<SessionDto> sessions,
    required double rowHeight,
  }) {
    final total = sessions.fold<int>(0, (acc, s) => acc + (s.partial ?? 0));
    final blockHeight = rowHeight * sessions.length;

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _mergedCell(_formatDate(date), width: 58, height: blockHeight),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.45),
          columnWidths: const {
            0: pw.FixedColumnWidth(40),
            1: pw.FixedColumnWidth(42),
            2: pw.FixedColumnWidth(74),
            3: pw.FixedColumnWidth(58),
            4: pw.FixedColumnWidth(58),
            5: pw.FixedColumnWidth(52),
          },
          children: sessions.map((session) {
            return pw.TableRow(
              children: [
                _bodyCell(_formatHour(session.hour), height: rowHeight),
                _bodyCell(session.bag?.toString() ?? '', alignRight: true, height: rowHeight),
                _bodyCell(_formatConcentration(session.concentration), alignRight: true, height: rowHeight),
                _bodyCell(session.infusion?.toString() ?? '', alignRight: true, height: rowHeight),
                _bodyCell(session.drainage?.toString() ?? '', alignRight: true, height: rowHeight),
                _bodyCell(_signed(session.partial), alignRight: true, height: rowHeight),
              ],
            );
          }).toList(),
        ),
        _mergedCell(_signed(total), width: 54, height: blockHeight, alignRight: true),
        pw.Expanded(
          child: pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.45),
            columnWidths: const {0: pw.FlexColumnWidth()},
            children: sessions.map((session) {
              return pw.TableRow(
                children: [
                  _bodyCell(session.observations ?? '', height: rowHeight),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  pw.Widget _headerBox(String text, {double? width, int? flex}) {
    final child = pw.Container(
      height: 22,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        border: pw.Border.all(color: PdfColors.grey600, width: 0.45),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 4),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
    );

    if (width != null) return pw.SizedBox(width: width, child: child);
    return pw.Expanded(flex: flex ?? 1, child: child);
  }

  pw.Widget _mergedCell(String text, {required double width, required double height, bool alignRight = false}) {
    return pw.Container(
      width: width,
      height: height,
      alignment: alignRight ? pw.Alignment.centerRight : pw.Alignment.center,
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey600, width: 0.45)),
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _bodyCell(String text, {bool alignRight = false, bool colspanStyle = false, double height = 18}) {
    return pw.Container(
      height: height,
      alignment: alignRight ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Text(
        text,
        maxLines: 2,
        overflow: pw.TextOverflow.clip,
        style: pw.TextStyle(fontSize: colspanStyle ? 9 : 8),
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
      ),
    );
  }

  Map<String, List<SessionDto>> _groupByDate(List<SessionDto> sessions) {
    final grouped = <String, List<SessionDto>>{};
    for (final session in sessions) {
      final key = session.date ?? 'Sin fecha';
      grouped.putIfAbsent(key, () => []).add(session);
    }
    return grouped;
  }

  String _formatDate(String value) {
    final parsed = DateTime.tryParse(value);
    return parsed == null ? value : _dateFormat.format(parsed);
  }

  String _formatHour(String? value) {
    if (value == null || value.isEmpty) return '';
    return value.length >= 5 ? value.substring(0, 5) : value;
  }

  String _formatConcentration(double? value) {
    if (value == null) return '';
    return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1).replaceAll('.', ',');
  }

  String _signed(int? value) {
    if (value == null) return '';
    return value > 0 ? '+$value' : value.toString();
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
