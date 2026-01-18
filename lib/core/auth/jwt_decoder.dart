import 'dart:convert';

class JwtDecoder {
  static Map<String, dynamic>? _decodePayload(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return null;

      final payloadBase64 = parts[1];

      // Base64URL normalize (pad + replace url-safe chars)
      String normalized = payloadBase64.replaceAll('-', '+').replaceAll('_', '/');
      switch (normalized.length % 4) {
        case 0:
          break;
        case 2:
          normalized += '==';
          break;
        case 3:
          normalized += '=';
          break;
        default:
          return null;
      }

      final payloadBytes = base64Decode(normalized);
      final payloadString = utf8.decode(payloadBytes);

      final jsonMap = jsonDecode(payloadString);
      if (jsonMap is Map<String, dynamic>) return jsonMap;

      return null;
    } catch (_) {
      return null;
    }
  }

  static String? getRole(String jwt) {
    final payload = _decodePayload(jwt);
    final role = payload?['role'];
    return role is String ? role : null;
  }

  static String? getSubject(String jwt) {
    final payload = _decodePayload(jwt);
    final sub = payload?['sub'];
    return sub is String ? sub : null;
  }
}
