import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonlokma/core/auth/token_storage.dart';
import 'package:sonlokma/core/network/api_client.dart';
import 'package:sonlokma/core/network/api_error.dart';

/// Sahte backend: yalnızca `Bearer fresh` geçerli; refresh `old-refresh` ile çalışır.
class FakeBackend implements HttpClientAdapter {
  int refreshCalls = 0;
  bool refreshFails = false;

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? _, Future<void>? __) async {
    await Future<void>.delayed(const Duration(milliseconds: 20)); // eşzamanlılığı zorla
    if (o.path == '/auth/refresh') {
      refreshCalls++;
      if (refreshFails) return _json(401, {'statusCode': 401, 'error': 'UNAUTHORIZED', 'message': 'x'});
      return _json(200, {'accessToken': 'fresh', 'refreshToken': 'new-refresh'});
    }
    if (o.path == '/orders') {
      return _json(409, {'statusCode': 409, 'error': 'OUT_OF_STOCK', 'message': 'Paket tükendi'});
    }
    if (o.headers['Authorization'] != 'Bearer fresh') {
      return _json(401, {'statusCode': 401, 'error': 'UNAUTHORIZED', 'message': 'expired'});
    }
    return _json(200, {'ok': true, 'path': o.path});
  }

  ResponseBody _json(int status, Object body) => ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );

  @override
  void close({bool force = false}) {}
}

void main() {
  late FakeBackend backend;
  late InMemoryTokenStorage storage;
  late int expiredCount;
  late ApiClient api;

  setUp(() {
    backend = FakeBackend();
    storage = InMemoryTokenStorage()
      ..access = 'stale'
      ..refresh = 'old-refresh';
    expiredCount = 0;
    api = ApiClient.create(
      baseUrl: 'http://test',
      storage: storage,
      onSessionExpired: () => expiredCount++,
      adapter: backend,
    );
  });

  test('aynı anda 5 adet 401 → tek refresh, hepsi başarılı', () async {
    final results = await Future.wait(
      List.generate(5, (i) => api.get<Map<String, dynamic>>('/r$i')),
    );

    expect(backend.refreshCalls, 1);
    expect(results.every((r) => r['ok'] == true), isTrue);
    expect(storage.access, 'fresh');
    expect(storage.refresh, 'new-refresh');
    expect(expiredCount, 0);
  });

  test('refresh başarısızsa token silinir ve oturum düşer', () async {
    backend.refreshFails = true;

    await expectLater(
      api.get<dynamic>('/users/me'),
      throwsA(isA<ApiError>().having((e) => e.code, 'code', ApiErrorCode.unauthorized)),
    );
    expect(storage.access, isNull);
    expect(expiredCount, 1);
  });

  test('409 OUT_OF_STOCK ApiError olarak gelir ve Türkçe mesaj üretir', () async {
    storage.access = 'fresh';
    await expectLater(
      api.post<dynamic>('/orders', data: {'packageId': 'p1', 'quantity': 1}),
      throwsA(isA<ApiError>()
          .having((e) => e.code, 'code', ApiErrorCode.outOfStock)
          .having((e) => e.statusCode, 'status', 409)
          .having((e) => e.userMessage, 'msg', 'Maalesef son paket az önce satıldı.')),
    );
    expect(backend.refreshCalls, 0);
  });

  test('skipAuth isteği 401 alırsa refresh denenmez', () async {
    await expectLater(
      api.post<dynamic>('/auth/login', data: {}, skipAuth: true),
      throwsA(isA<ApiError>()),
    );
    expect(backend.refreshCalls, 0);
  });
}
