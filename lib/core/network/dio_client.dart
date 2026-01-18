import 'dart:async';
import 'package:dio/dio.dart';
import 'package:frontend_dialysis_record/core/auth/token_storage.dart';

class DioClient {
  final Dio dio;
  final TokenStorage tokenStorage;

  static const String baseUrl = 'http://localhost:8080';

  bool _isRefreshing = false;
  final List<_QueuedRequest> _refreshQueue = [];

  DioClient({TokenStorage? tokenStorage})
      : tokenStorage = tokenStorage ?? TokenStorage(),
        dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(milliseconds: 10000),
            receiveTimeout: const Duration(milliseconds: 7000),
            headers: const {
              'Content-Type': 'application/json',
            },
          ),
        ) {
    dio.interceptors.add(LogInterceptor(responseBody: true));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final access = await this.tokenStorage.readAccessToken();
          if (access != null && access.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $access';
          }
          handler.next(options);
        },
        onError: (e, handler) async {
          final status = e.response?.statusCode;
          final req = e.requestOptions;

          final isAuthEndpoint =
              req.path.contains('/auth/login') || req.path.contains('/auth/refresh');

          // Si es 401 en endpoints NO-auth, intentamos refresh
          if (status == 401 && !isAuthEndpoint) {
            final completer = Completer<Response<dynamic>>();
            _refreshQueue.add(_QueuedRequest(req, completer));

            // Si ya hay un refresh en curso, esperamos a que termine
            if (_isRefreshing) {
              try {
                final res = await completer.future;
                return handler.resolve(res);
              } catch (err) {
                return handler.next(e);
              }
            }

            _isRefreshing = true;

            try {
              final refreshed = await _tryRefreshToken();
              _isRefreshing = false;

              if (!refreshed) {
                // refresh falló => limpiar sesión
                await tokenStorage?.clearAll();
                // Rechazamos todo lo encolado
                for (final q in _refreshQueue) {
                  q.completer.completeError(e);
                }
                _refreshQueue.clear();
                return handler.next(e);
              }

              // refresh OK: reintentamos TODO lo encolado con el nuevo access
              final newAccess = await tokenStorage?.readAccessToken();
              for (final q in _refreshQueue) {
                try {
                  q.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
                  final cloned = await dio.fetch(q.requestOptions);
                  q.completer.complete(cloned);
                } catch (err) {
                  q.completer.completeError(err);
                }
              }
              _refreshQueue.clear();

              // resolvemos el request actual
              final res = await completer.future;
              return handler.resolve(res);
            } catch (err) {
              _isRefreshing = false;
              await tokenStorage?.clearAll();

              for (final q in _refreshQueue) {
                q.completer.completeError(err);
              }
              _refreshQueue.clear();

              return handler.next(e);
            }
          }

          handler.next(e);
        },
      ),
    );
  }

  /// POST /auth/refresh con refreshToken
  /// Espera: { "accessToken": "...", "refreshToken": "..."? }
  Future<bool> _tryRefreshToken() async {
    final refresh = await tokenStorage.readRefreshToken();
    if (refresh == null || refresh.isEmpty) return false;

    try {
      final res = await Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(milliseconds: 10000),
          receiveTimeout: const Duration(milliseconds: 7000),
          headers: const {'Content-Type': 'application/json'},
        ),
      ).post(
        '/auth/refresh',
        data: {'refreshToken': refresh},
      );

      final data = res.data;
      if (data == null || data is! Map) return false;

      final newAccess = data['accessToken'] as String?;
      final newRefresh = data['refreshToken'] as String?;

      if (newAccess == null || newAccess.isEmpty) return false;

      await tokenStorage.saveAccessToken(newAccess);
      if (newRefresh != null && newRefresh.isNotEmpty) {
        await tokenStorage.saveRefreshToken(newRefresh); // si el backend rota refresh
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}

class _QueuedRequest {
  final RequestOptions requestOptions;
  final Completer<Response<dynamic>> completer;

  _QueuedRequest(this.requestOptions, this.completer);
}
