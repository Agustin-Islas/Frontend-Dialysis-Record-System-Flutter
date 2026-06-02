import 'package:dio/dio.dart';

class AppException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  final Map<String, String> fieldErrors;

  const AppException(
    this.message, {
    this.statusCode,
    this.code,
    this.fieldErrors = const {},
  });

  bool get isUnauthorized => statusCode == 401;

  factory AppException.fromDio(DioException error) {
    final status = error.response?.statusCode;
    final data = error.response?.data;

    if (data is Map) {
      final fields = <String, String>{};
      final rawFields = data['fieldErrors'];
      if (rawFields is Map) {
        rawFields.forEach((key, value) {
          fields[key.toString()] = value.toString();
        });
      }

      return AppException(
        data['message']?.toString() ?? _messageForStatus(status),
        statusCode: status,
        code: data['code']?.toString(),
        fieldErrors: fields,
      );
    }

    return AppException(_messageForStatus(status), statusCode: status);
  }

  static String _messageForStatus(int? status) {
    switch (status) {
      case 400:
        return 'Hay datos inválidos.';
      case 401:
        return 'La sesión expiró. Iniciá sesión nuevamente.';
      case 403:
        return 'No tenés permisos para realizar esta acción.';
      case 404:
        return 'No se encontró el recurso solicitado.';
      case 409:
        return 'La operación no se pudo completar por un conflicto.';
      case 500:
        return 'Ocurrió un error del servidor.';
      default:
        return 'No se pudo completar la operación.';
    }
  }

  @override
  String toString() => message;
}
