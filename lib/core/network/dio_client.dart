import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend_dialysis_record/core/config/app_config.dart';
import 'package:frontend_dialysis_record/core/network/app_exception.dart';

class DioClient {
  final Dio dio;

  static const String baseUrl = AppConfig.apiBaseUrl;

  DioClient()
    : dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(milliseconds: 30000),
          receiveTimeout: const Duration(milliseconds: 30000),
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
          // Obtener el token de acceso directamente de la sesión actual de Supabase
          final session = Supabase.instance.client.auth.currentSession;
          final access = session?.accessToken;

          if (access != null && access.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $access';
          }
          handler.next(options);
        },
        onError: (e, handler) {
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
}
