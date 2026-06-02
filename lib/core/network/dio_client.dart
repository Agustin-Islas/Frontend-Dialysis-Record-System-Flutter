import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:frontend_dialysis_record/core/auth/token_storage.dart';
import 'package:frontend_dialysis_record/core/config/app_config.dart';
import 'package:frontend_dialysis_record/core/network/app_exception.dart';

class DioClient {
  final Dio dio;
  final TokenStorage tokenStorage;

  static const String baseUrl = AppConfig.apiBaseUrl;

  bool _isRefreshing = false;
  final List<_QueuedRequest> _refreshQueue = [];

  DioClient({TokenStorage? tokenStorage})
      : tokenStorage = tokenStorage ?? TokenStorage(),
        dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(milliseconds: 10000),
            receiveTimeout: const Duration(milliseconds: 7000),
            headers: const {'Content-Type': 'application/json'},
          ),
        ) {
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
        ),
      );
    }

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

          if (status == 401 && !isAuthEndpoint) {
            final completer = Completer<Response<dynamic>>();
            _refreshQueue.add(_QueuedRequest(req, completer));

            if (_isRefreshing) {
              try {
                return handler.resolve(await completer.future);
              } catch (_) {
                return handler.next(e);
              }
            }

            _isRefreshing = true;
            try {
              final refreshed = await _tryRefreshToken();
              _isRefreshing = false;

              if (!refreshed) {
                await this.tokenStorage.clearAll();
                for (final q in _refreshQueue) {
                  q.completer.completeError(e);
                }
                _refreshQueue.clear();
                return handler.next(e);
              }

              final newAccess = await this.tokenStorage.readAccessToken();
              for (final q in _refreshQueue) {
                try {
                  q.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
                  q.completer.complete(await dio.fetch(q.requestOptions));
                } catch (err) {
                  q.completer.completeError(err);
                }
              }
              _refreshQueue.clear();
              return handler.resolve(await completer.future);
            } catch (err) {
              _isRefreshing = false;
              await this.tokenStorage.clearAll();
              for (final q in _refreshQueue) {
                q.completer.completeError(err);
              }
              _refreshQueue.clear();
              return handler.next(e);
            }
          }

          handler.reject(
            DioException(
              requestOptions: e.requestOptions,
              response: e.response,
              type: e.type,
              error: AppException.fromDio(e),
              stackTrace: e.stackTrace,
              message: e.message,
            ),
          );
        },
      ),
    );
  }

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
      ).post('/auth/refresh', data: {'refreshToken': refresh});

      final data = res.data;
      if (data is! Map) return false;

      final newAccess = data['accessToken'] as String?;
      final newRefresh = data['refreshToken'] as String?;
      if (newAccess == null || newAccess.isEmpty) return false;

      await tokenStorage.saveAccessToken(newAccess);
      if (newRefresh != null && newRefresh.isNotEmpty) {
        await tokenStorage.saveRefreshToken(newRefresh);
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
