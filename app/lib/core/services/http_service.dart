import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../errors/failures.dart';

/// Provedor global do HttpService
final httpServiceProvider = Provider<HttpService>((ref) {
  return HttpService();
});

/// Cliente HTTP baseado em Dio com interceptors para Firebase Auth e tratamento de erros.
class HttpService {
  late final Dio _dio;

  HttpService({String? baseUrl, Dio? dio}) {
    _dio = dio ??
        Dio(
          BaseOptions(
            baseUrl: baseUrl ?? _resolveBaseUrl(),
            connectTimeout: const Duration(milliseconds: AppConstants.connectTimeoutMs),
            receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeoutMs),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

    _dio.interceptors.addAll([
      _AuthInterceptor(),
      if (kDebugMode)
        LogInterceptor(
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
        ),
    ]);
  }

  Dio get client => _dio;

  /// Determina o baseUrl adequado para o ambiente (Android emulator x localhost x desktop)
  static String _resolveBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AppConstants.apiBaseUrlDev;
    }
    return 'http://localhost:3000/api';
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }

  Failure _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkFailure('Falha na conexão com o servidor. Verifique sua internet.');

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;
        String message = 'Ocorreu um erro no servidor.';

        if (responseData is Map<String, dynamic>) {
          if (responseData['error'] is String) {
            message = responseData['error'] as String;
          } else if (responseData['message'] is String) {
            message = responseData['message'] as String;
          }
        }

        if (statusCode == 401) {
          return AuthFailure(message.isNotEmpty ? message : 'Sessão expirada. Faça login novamente.');
        } else if (statusCode == 403) {
          if (message.toLowerCase().contains('inativo') ||
              message.toLowerCase().contains('desativado')) {
            return const UserInactiveFailure();
          }
          return const UnauthorizedFailure();
        } else if (statusCode == 404) {
          return const UserNotFoundFailure();
        } else if (statusCode == 400 || statusCode == 422) {
          return ValidationFailure(message);
        }
        return ServerFailure(message, statusCode: statusCode);

      case DioExceptionType.cancel:
        return const UnknownFailure('A requisição foi cancelada.');

      default:
        return UnknownFailure(error.message ?? 'Erro de comunicação desconhecido.');
    }
  }
}

/// Interceptor que anexa o Bearer token do Firebase Auth às requisições
class _AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!options.headers.containsKey('Authorization')) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final token = await user.getIdToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (_) {
          // Prossegue sem token caso ocorra erro ao obtê-lo
        }
      }
    }
    return handler.next(options);
  }
}
