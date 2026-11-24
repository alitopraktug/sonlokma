import 'package:dio/dio.dart';

import '../auth/token_storage.dart';

/// `extra: {AuthInterceptor.skipAuth: true}` → header eklenmez, 401'de refresh denenmez
/// (login, register, refresh gibi uçlar).
///
/// NEDEN QueuedInterceptor?
/// Aynı anda 5 istek 401 alırsa düz Interceptor 5 ayrı `/auth/refresh` atar. Refresh token
/// rotation kullandığımız için ilk refresh eski token'ı geçersiz kılar, kalan 4'ü başarısız
/// olur ve kullanıcı haksız yere çıkış yapar. QueuedInterceptor onError çağrılarını SIRAYLA
/// işler: ilki refresh yapar, sonrakiler sıraları geldiğinde depodaki token'ın isteklerindeki
/// token'dan farklı olduğunu görür ve refresh yapmadan yeni token'la tekrar dener.
/// Sonuç: N eşzamanlı 401 → tam olarak 1 refresh.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required TokenStorage storage,
    required Dio plainDio,
    required void Function() onSessionExpired,
  })  : _storage = storage,
        _plainDio = plainDio,
        _onSessionExpired = onSessionExpired;

  static const skipAuth = 'skipAuth';
  static const _retried = 'authRetried';

  final TokenStorage _storage;

  /// Interceptor'sız ayrı Dio. Refresh ve tekrar denemeler bununla yapılır; ana Dio'yu
  /// kullanmak hata kuyruğunda kilitlenmeye (deadlock) ve sonsuz döngüye yol açar.
  final Dio _plainDio;
  final void Function() _onSessionExpired;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.extra[skipAuth] != true) {
      final token = await _storage.readAccessToken();
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    if (err.response?.statusCode != 401 ||
        options.extra[skipAuth] == true ||
        options.extra[_retried] == true) {
      return handler.next(err);
    }

    final sentToken = _bearer(options.headers['Authorization']);
    final current = await _storage.readAccessToken();

    // Biz kuyrukta beklerken başka bir istek zaten yenilemiş.
    if (current != null && current != sentToken) {
      return _retry(options, current, handler, err);
    }

    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null) return _expire(handler, err);

    try {
      final res = await _plainDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final pair = TokenPair.fromJson(res.data!);
      await _storage.save(pair);
      return _retry(options, pair.accessToken, handler, err);
    } on DioException {
      return _expire(handler, err);
    }
  }

  Future<void> _retry(
    RequestOptions options,
    String token,
    ErrorInterceptorHandler handler,
    DioException original,
  ) async {
    options.headers['Authorization'] = 'Bearer $token';
    options.extra[_retried] = true;
    try {
      handler.resolve(await _plainDio.fetch<dynamic>(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<void> _expire(ErrorInterceptorHandler handler, DioException err) async {
    await _storage.clear();
    _onSessionExpired();
    handler.next(err);
  }

  static String? _bearer(Object? header) {
    final s = header?.toString();
    return (s != null && s.startsWith('Bearer ')) ? s.substring(7) : null;
  }
}
