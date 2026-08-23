import 'package:supabase_flutter/supabase_flutter.dart';

/// Helper class to map Supabase AuthExceptions to user-friendly Spanish messages.
class AuthExceptionMapper {
  /// Translates a given exception [e] into a clear, explanatory Spanish message.
  /// If the exception is not an AuthException or the message is unknown,
  /// it returns the [fallbackMessage] or a generic error string.
  static String mapException(Object e, {String? fallbackMessage}) {
    if (e is AuthException) {
      final msg = e.message.toLowerCase();

      // Login errors
      if (msg.contains('invalid login credentials')) {
        return 'Correo electrónico o contraseña incorrectos.';
      }
      if (msg.contains('email not confirmed')) {
        return 'Debes confirmar tu correo electrónico antes de iniciar sesión.';
      }
      
      // Password Recovery & Updating errors
      if (msg.contains('user not found')) {
        return 'No existe un usuario registrado con este correo.';
      }
      if (msg.contains('same password')) {
        return 'La nueva contraseña no puede ser igual a la anterior.';
      }
      if (msg.contains('weak password')) {
        return 'La contraseña es muy débil. Usa al menos 6 caracteres.';
      }
      
      // OTP and Verification errors
      if (msg.contains('token has expired') || msg.contains('invalid token')) {
        return 'El código ingresado es inválido o ha expirado.';
      }

      // Registration errors
      if (msg.contains('user already registered')) {
        return 'Este correo ya se encuentra registrado.';
      }

      // Generic Rate Limiting
      if (msg.contains('rate limit')) {
        return 'Demasiados intentos. Espera unos minutos e intenta nuevamente.';
      }

      // If it's an AuthException we don't explicitly handle, return its original message
      return e.message;
    }

    // For any other non-auth exception
    return fallbackMessage ?? 'Ocurrió un error inesperado. Inténtalo nuevamente.';
  }
}
