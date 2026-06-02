import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:universal_html/html.dart' as html;

class TokenStorage {
  // Mobile secure storage
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const _accessKey = 'accessToken';
  static const _refreshKey = 'refreshToken';

  Future<void> saveAccessToken(String token) async {
    if (kIsWeb) {
      html.window.localStorage[_accessKey] = token;
      return;
    }
    await _secureStorage.write(key: _accessKey, value: token);
  }

  Future<String?> readAccessToken() async {
    if (kIsWeb) {
      return html.window.localStorage[_accessKey];
    }
    return _secureStorage.read(key: _accessKey);
  }

  Future<void> saveRefreshToken(String token) async {
    if (kIsWeb) {
      html.window.localStorage[_refreshKey] = token;
      return;
    }
    await _secureStorage.write(key: _refreshKey, value: token);
  }

  Future<String?> readRefreshToken() async {
    if (kIsWeb) {
      return html.window.localStorage[_refreshKey];
    }

    return await _secureStorage.read(key: _refreshKey);
  }

  Future<void> clearAll() async {
    if (kIsWeb) {
      html.window.localStorage.remove(_accessKey);
      html.window.localStorage.remove(_refreshKey);
      return;
    }
    await _secureStorage.deleteAll();
  }

  // Opcional: helpers por si querés borrar solo uno
  Future<void> clearAccessToken() async {
    if (kIsWeb) {
      html.window.localStorage.remove(_accessKey);
      return;
    }
    await _secureStorage.delete(key: _accessKey);
  }

  Future<void> clearRefreshToken() async {
    if (kIsWeb) {
      html.window.localStorage.remove(_refreshKey);
      return;
    }
    await _secureStorage.delete(key: _refreshKey);
  }
}
