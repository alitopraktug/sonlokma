import '../network/api_error.dart';

typedef Delay = Future<void> Function(Duration);

Future<void> realDelay(Duration d) => Future<void>.delayed(d);

/// [fetch]'i [interval] aralıkla en fazla [timeout] boyunca çağırır; [isDone] true olunca
/// sonucu döner, süre dolarsa null. Ara ağ hataları yutulur (bir sonraki denemede tekrar).
///
/// Deneme sayısıyla sınırlıyoruz (saat okumuyoruz) → testte [delay] anında dönebilir.
/// 2 sn / 30 sn → t=0,2,…,30 → 16 deneme.
Future<T?> pollUntil<T>({
  required Future<T> Function() fetch,
  required bool Function(T) isDone,
  Duration interval = const Duration(seconds: 2),
  Duration timeout = const Duration(seconds: 30),
  Delay delay = realDelay,
  bool Function()? isCancelled,
}) async {
  final attempts = timeout.inMilliseconds ~/ interval.inMilliseconds + 1;
  for (var i = 0; i < attempts; i++) {
    if (i > 0) await delay(interval);
    if (isCancelled?.call() ?? false) return null;
    try {
      final value = await fetch();
      if (isDone(value)) return value;
    } on ApiError catch (e) {
      // 404/403 gibi kalıcı hatalarda beklemenin anlamı yok.
      if (e.code != ApiErrorCode.network &&
          e.code != ApiErrorCode.timeout &&
          e.code != ApiErrorCode.unknown &&
          e.code != ApiErrorCode.rateLimited) {
        rethrow;
      }
    }
  }
  return null;
}
