import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sonlokma/core/network/api_error.dart';
import 'package:sonlokma/core/network/cursor_page.dart';
import 'package:sonlokma/core/utils/formatters.dart';
import 'package:sonlokma/core/utils/poll.dart';
import 'package:sonlokma/features/student/auth/presentation/validators.dart';

DioException _response(int status, Object? body) {
  final req = RequestOptions(path: '/x');
  return DioException(
    requestOptions: req,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: req, statusCode: status, data: body),
  );
}

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));

  group('ApiError.fromDioException', () {
    test('kontrat gövdesi → kod, status ve sunucu mesajı', () {
      final e = ApiError.fromDioException(
          _response(409, {'statusCode': 409, 'error': 'OUT_OF_STOCK', 'message': 'Paket tükendi'}));
      expect(e.code, ApiErrorCode.outOfStock);
      expect(e.statusCode, 409);
      expect(e.serverMessage, 'Paket tükendi');
    });

    test('bilinmeyen error kodu → unknown', () {
      expect(ApiError.fromDioException(_response(418, {'error': 'TEAPOT'})).code,
          ApiErrorCode.unknown);
    });

    test('gövde kontrata uymuyorsa status\'tan tahmin', () {
      expect(ApiError.fromDioException(_response(429, '<html>')).code, ApiErrorCode.rateLimited);
      expect(ApiError.fromDioException(_response(404, null)).code, ApiErrorCode.notFound);
      expect(ApiError.fromDioException(_response(502, 'Bad gateway')).code, ApiErrorCode.unknown);
    });

    test('zaman aşımı ve bağlantı hatası', () {
      final req = RequestOptions(path: '/x');
      expect(
          ApiError.fromDioException(
                  DioException(requestOptions: req, type: DioExceptionType.receiveTimeout))
              .code,
          ApiErrorCode.timeout);
      expect(
          ApiError.fromDioException(
                  DioException(requestOptions: req, type: DioExceptionType.connectionError))
              .code,
          ApiErrorCode.network);
    });

    test('her kodun boş olmayan Türkçe mesajı var', () {
      for (final c in ApiErrorCode.values) {
        expect(ApiError(code: c).userMessage, isNotEmpty, reason: c.name);
      }
    });

    test('wire adları kontrattakiyle aynı', () {
      expect(ApiErrorCode.fromWire('RESERVATION_EXPIRED'), ApiErrorCode.reservationExpired);
      expect(ApiErrorCode.fromWire('QR_ALREADY_USED'), ApiErrorCode.qrAlreadyUsed);
      expect(ApiErrorCode.fromWire(null), ApiErrorCode.unknown);
    });
  });

  group('Fmt', () {
    test('kuruş → TL (float hesap yok, sadece gösterim)', () {
      expect(Fmt.kurus(8990), contains('89,90'));
      expect(Fmt.kurus(184000), contains('1.840,00'));
      expect(Fmt.kurus(0), contains('0,00'));
    });

    test('mesafe', () {
      expect(Fmt.distance(420), '420 m');
      expect(Fmt.distance(1250), '1,3 km');
      expect(Fmt.distance(1000), '1,0 km');
    });

    test('saat aralığı yerel saatle', () {
      expect(Fmt.timeRange(DateTime(2026, 12, 1, 19), DateTime(2026, 12, 1, 20, 30)),
          '19:00–20:30');
    });
  });

  group('AuthValidators', () {
    test('e-posta', () {
      expect(AuthValidators.email(''), isNotNull);
      expect(AuthValidators.email('ali@'), isNotNull);
      expect(AuthValidators.email(' ali@ogr.edu.tr '), isNull);
    });

    test('şifre en az 8 karakter', () {
      expect(AuthValidators.password('1234567'), isNotNull);
      expect(AuthValidators.password('12345678'), isNull);
    });

  });

  test('CursorPage: nextCursor null → son sayfa', () {
    final p = CursorPage.fromJson<int>(
        {'items': [{'v': 1}, {'v': 2}], 'nextCursor': null}, (e) => e['v'] as int);
    expect(p.items, [1, 2]);
    expect(p.isLast, isTrue);
  });

  group('pollUntil', () {
    test('kalıcı hata (404) beklemeden fırlatılır', () async {
      var calls = 0;
      await expectLater(
        pollUntil<int>(
          fetch: () async {
            calls++;
            throw const ApiError(code: ApiErrorCode.notFound);
          },
          isDone: (_) => true,
          delay: (_) async {},
        ),
        throwsA(isA<ApiError>()),
      );
      expect(calls, 1);
    });

    test('iptal edilince durur', () async {
      var calls = 0;
      final r = await pollUntil<int>(
        fetch: () async => ++calls,
        isDone: (_) => false,
        delay: (_) async {},
        isCancelled: () => calls >= 3,
      );
      expect(r, isNull);
      expect(calls, 3);
    });
  });
}
