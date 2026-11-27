import 'dart:async';

/// Son çağrıdan [delay] kadar sessizlik olunca çalışır. Harita kamerası saniyede ~60 kez
/// hareket olayı üretir; debounce olmadan her kare bir API isteği olurdu.
class Debouncer {
  Debouncer(this.delay);
  final Duration delay;
  Timer? _timer;

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() => _timer?.cancel();
  void dispose() => cancel();
}
