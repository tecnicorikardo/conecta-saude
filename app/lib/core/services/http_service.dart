import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// URL base do backend.
/// Em produção substituir pela URL real do servidor.
const String kApiBaseUrl = 'http://localhost:3000/api';

/// HttpService — cliente Dio com interceptor que injeta o
/// Firebase ID Token em todas as requisições autenticadas.
class HttpService {
  HttpService._();

  static HttpService? _instance;
  static HttpService get instance => _instance ??= HttpService._();

  late final Dio _dio;
  bool _initialized = false;

  void init() {
    if (_initialized) return;

    _dio = Dio(
      BaseOptions(
        baseUrl: kApiBaseUrl,
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // ─── Interceptor de autenticação ─────────────────────────────────────
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              // Forçar refresh apenas se o token expirou
              final token = await user.getIdToken(false);
              if (token != null) {
                options.headers['Authorization'] = 'Bearer $token';
              }
            }
          } catch (_) {
            // Sem token — a rota vai rejeitar se precisar de auth
          }
          handler.next(options);
        },

        onError: (error, handler) async {
          // Token expirado (401) — tentar renovar e repetir uma vez
          if (error.response?.statusCode == 401) {
            try {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                final newToken = await user.getIdToken(true); // força refresh
                if (newToken != null) {
                  final opts = error.requestOptions;
                  opts.headers['Authorization'] = 'Bearer $newToken';
                  final retryResponse = await _dio.fetch(opts);
                  return handler.resolve(retryResponse);
                }
              }
            } catch (_) {}
          }
          handler.next(error);
        },
      ),
    );

    // Log em desenvolvimento
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (o) {
          // ignore: avoid_print
          assert(() { print('[HTTP] $o'); return true; }());
        },
      ),
    );

    _initialized = true;
  }

  Dio get dio {
    if (!_initialized) init();
    return _dio;
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Future<Response<T>> get<T>(String path,
      {Map<String, dynamic>? queryParameters}) {
    return dio.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(String path, {dynamic data}) {
    return dio.post<T>(path, data: data);
  }

  Future<Response<T>> put<T>(String path, {dynamic data}) {
    return dio.put<T>(path, data: data);
  }

  Future<Response<T>> patch<T>(String path, {dynamic data}) {
    return dio.patch<T>(path, data: data);
  }

  Future<Response<T>> delete<T>(String path) {
    return dio.delete<T>(path);
  }
}

// ─── Provider global ─────────────────────────────────────────────────────────
final httpServiceProvider = Provider<HttpService>((ref) {
  final service = HttpService.instance;
  service.init();
  return service;
});
