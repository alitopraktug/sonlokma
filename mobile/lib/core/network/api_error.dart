import 'package:dio/dio.dart';

/// Kontrattaki `error` kodları (00_ORTAK §7) + yalnızca istemcide üretilen 3 kod.
/// İstemci kodları (network/timeout/unknown) backend'den GELMEZ, kontrata eklenmez.
enum ApiErrorCode {
  validationError('VALIDATION_ERROR'),
  unauthorized('UNAUTHORIZED'),
  forbidden('FORBIDDEN'),
  notFound('NOT_FOUND'),
  outOfStock('OUT_OF_STOCK'),
  reservationExpired('RESERVATION_EXPIRED'),
  paymentFailed('PAYMENT_FAILED'),
  qrInvalid('QR_INVALID'),
  qrAlreadyUsed('QR_ALREADY_USED'),
  rateLimited('RATE_LIMITED'),
  // --- yalnızca istemci ---
  network('NETWORK_ERROR'),
  timeout('TIMEOUT'),
  unknown('UNKNOWN');

  const ApiErrorCode(this.wire);
  final String wire;

  static ApiErrorCode fromWire(String? value) => ApiErrorCode.values.firstWhere(
        (c) => c.wire == value,
        orElse: () => ApiErrorCode.unknown,
      );
}

/// Backend hata formatı: `{ statusCode, error, message }`.
/// Repository'ler DioException yerine her zaman bunu fırlatır; UI dio'yu bilmez.
class ApiError implements Exception {
  const ApiError({required this.code, this.statusCode, this.serverMessage});

  final ApiErrorCode code;
  final int? statusCode;

  /// Backend'in döndüğü ham mesaj (log/debug için). Kullanıcıya [userMessage] gösterilir.
  final String? serverMessage;

  factory ApiError.fromDioException(DioException e) {
    if (e.error is ApiError) return e.error! as ApiError;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiError(code: ApiErrorCode.timeout);
      case DioExceptionType.connectionError:
        return const ApiError(code: ApiErrorCode.network);
      default:
        break;
    }

    final response = e.response;
    if (response == null) return const ApiError(code: ApiErrorCode.network);

    final data = response.data;
    if (data is Map) {
      return ApiError(
        code: ApiErrorCode.fromWire(data['error'] as String?),
        statusCode: (data['statusCode'] as num?)?.toInt() ?? response.statusCode,
        serverMessage: data['message']?.toString(),
      );
    }
    return ApiError(code: _fromStatus(response.statusCode), statusCode: response.statusCode);
  }

  /// Gövde kontrata uymuyorsa (ör. proxy HTML'i) en azından status'tan tahmin et.
  static ApiErrorCode _fromStatus(int? status) => switch (status) {
        400 || 422 => ApiErrorCode.validationError,
        401 => ApiErrorCode.unauthorized,
        403 => ApiErrorCode.forbidden,
        404 => ApiErrorCode.notFound,
        429 => ApiErrorCode.rateLimited,
        _ => ApiErrorCode.unknown,
      };

  String get userMessage => switch (code) {
        ApiErrorCode.validationError => 'Girdiğin bilgileri kontrol et.',
        ApiErrorCode.unauthorized => 'Oturumun sona erdi, lütfen tekrar giriş yap.',
        ApiErrorCode.forbidden => 'Bu işlem için yetkin yok.',
        ApiErrorCode.notFound => 'Aradığın içerik bulunamadı.',
        ApiErrorCode.outOfStock => 'Maalesef son paket az önce satıldı.',
        ApiErrorCode.reservationExpired => 'Rezervasyon süren doldu, paketi tekrar seçebilirsin.',
        ApiErrorCode.paymentFailed => 'Ödeme tamamlanamadı, tekrar dene.',
        ApiErrorCode.qrInvalid => 'QR kod geçersiz.',
        ApiErrorCode.qrAlreadyUsed => 'Bu QR kod daha önce kullanılmış.',
        ApiErrorCode.rateLimited => 'Çok fazla deneme yaptın, biraz bekle.',
        ApiErrorCode.network => 'İnternet bağlantını kontrol et.',
        ApiErrorCode.timeout => 'Sunucu yanıt vermedi, tekrar dene.',
        ApiErrorCode.unknown => 'Beklenmeyen bir hata oluştu.',
      };

  @override
  String toString() => 'ApiError(${code.wire}, $statusCode, $serverMessage)';
}
