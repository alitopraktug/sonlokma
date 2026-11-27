import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/token_storage.dart';
import '../config/env.dart';
import 'api_error.dart';
import 'auth_interceptor.dart';
import 'request_metrics.dart';

/// Tek giriş noktası. Repository'ler yalnızca bunu kullanır ve sadece [ApiError] yakalar.
class ApiClient {
  ApiClient(this.dio);

  factory ApiClient.create({
    required String baseUrl,
    required TokenStorage storage,
    required void Function() onSessionExpired,
    HttpClientAdapter? adapter, // testler için
  }) {
    BaseOptions opts() => BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          contentType: Headers.jsonContentType,
        );
    final plain = Dio(opts());
    final dio = Dio(opts());
    if (adapter != null) {
      plain.httpClientAdapter = adapter;
      dio.httpClientAdapter = adapter;
    }
    dio.interceptors.add(requestMetrics);
    dio.interceptors.add(AuthInterceptor(
      storage: storage,
      plainDio: plain,
      onSessionExpired: onSessionExpired,
    ));
    return ApiClient(dio);
  }

  final Dio dio;

  Future<T> get<T>(String path, {Map<String, dynamic>? query}) =>
      _guard(() => dio.get<T>(path, queryParameters: _clean(query)));

  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, String>? headers,
    bool skipAuth = false,
  }) =>
      _guard(() => dio.post<T>(
            path,
            data: data,
            options: Options(
              headers: headers,
              extra: {AuthInterceptor.skipAuth: skipAuth},
            ),
          ));

  Future<T> patch<T>(String path, {Object? data}) => _guard(() => dio.patch<T>(path, data: data));

  Future<T> delete<T>(String path) => _guard(() => dio.delete<T>(path));

  Future<T> _guard<T>(Future<Response<T>> Function() call) async {
    try {
      return (await call()).data as T;
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  /// null filtreleri query'den at (ör. category seçilmemişse `?category=null` gitmesin).
  static Map<String, dynamic>? _clean(Map<String, dynamic>? q) =>
      q == null ? null : (Map.of(q)..removeWhere((_, v) => v == null));
}

final tokenStorageProvider = Provider<TokenStorage>((_) => SecureTokenStorage());

/// Oturum düştüğünde router'a haber vermek için; auth_controller dinler.
final sessionExpiredProvider = StateProvider<int>((_) => 0);

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient.create(
      baseUrl: Env.apiBaseUrl,
      storage: ref.watch(tokenStorageProvider),
      onSessionExpired: () => ref.read(sessionExpiredProvider.notifier).state++,
    ));
