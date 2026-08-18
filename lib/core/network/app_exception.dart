import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    if (error.error is AppException) {
      return error.error as AppException;
    }

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

      final rawMsg = data['message']?.toString();
      final code = data['code']?.toString();

      return AppException(
        _translateMessage(rawMsg, status, code),
        statusCode: status,
        code: code,
        fieldErrors: fields,
      );
    }

    return AppException(_messageForStatus(status), statusCode: status);
  }

  static String getMessage(
    dynamic e, [
    String defaultMsg = 'No se pudo completar la operación.',
  ]) {
    if (e is AppException) return e.message;
    if (e is AuthException) {
      return _translateMessage(e.message, null, null);
    }
    if (e is DioException) {
      if (e.error is AppException) {
        return (e.error as AppException).message;
      }
      return AppException.fromDio(e).message;
    }
    return defaultMsg;
  }

  static String _translateMessage(String? rawMsg, int? status, String? code) {
    if (rawMsg == null || rawMsg.isEmpty) return _messageForStatus(status);
    final lower = rawMsg.toLowerCase();
    if (lower.contains('invalid credentials') ||
        lower.contains('bad credentials') ||
        code == 'UNAUTHORIZED' ||
        status == 401) {
      return 'Correo electrónico o contraseña incorrectos. Por favor, verificá tus datos.';
    }
    if (lower.contains('user not found') || lower.contains('not found')) {
      return 'No se encontró una cuenta con ese correo electrónico.';
    }
    if (lower.contains('disabled') || lower.contains('locked')) {
      return 'Esta cuenta ha sido deshabilitada o bloqueada.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Debes confirmar tu correo electrónico antes de poder ingresar.';
    }
    if (lower.contains('rate limit') || lower.contains('too many requests')) {
      return 'Demasiados intentos. Por favor, espera un momento y vuelve a intentar.';
    }
    if (lower.contains('already exists') || lower.contains('duplicate')) {
      return 'Ya existe un registro o cuenta con esos datos.';
    }
    return rawMsg;
  }

  static String _messageForStatus(int? status) {
    switch (status) {
      case 400:
        return 'Hay datos inválidos.';
      case 401:
        return 'Correo electrónico o contraseña incorrectos.';
      case 403:
        return 'No tenés permisos para realizar esta acción.';
      case 404:
        return 'No se encontró el recurso solicitado.';
      case 409:
        return 'La operación no se pudo completar por un conflicto de datos.';
      case 500:
        return 'Ocurrió un error del servidor.';
      default:
        return 'No se pudo completar la operación.';
    }
  }

  @override
  String toString() => message;
}
