import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/utils/poll.dart';
import '../../orders/data/orders_repository_impl.dart';
import '../../orders/domain/order.dart';

// ─────────────────────────────── Durumlar ───────────────────────────────
//
//  Idle ──reserve()──► Reserving ──ok──► Reserved ──pay()──► (WebView) ──► Confirming
//   ▲  ▲                  │409                │ geri sayım 0                 │
//   │  └──ağ hatası───────┤                   ▼                              ├─PAID──► Paid
//   │                     ▼                Expired                           ├─EXPIRED► Expired
//   │                  SoldOut                                               └─30 sn──► Unconfirmed
//   └── retry (aynı Idempotency-Key)

sealed class CheckoutState {
  const CheckoutState();
}

class CheckoutIdle extends CheckoutState {
  const CheckoutIdle({this.error});
  final ApiError? error;
}

class CheckoutReserving extends CheckoutState {
  const CheckoutReserving();
}

class CheckoutReserved extends CheckoutState {
  const CheckoutReserved(this.order, {this.openingPayment = false, this.error});
  final Order order;
  final bool openingPayment;
  final ApiError? error;
}

class CheckoutConfirming extends CheckoutState {
  const CheckoutConfirming(this.order);
  final Order order;
}

class CheckoutPaid extends CheckoutState {
  const CheckoutPaid(this.order);
  final Order order;
}

/// 30 sn içinde PAID görülmedi. Webhook gecikmiş olabilir; ödeme "başarısız" DEMİYORUZ.
class CheckoutUnconfirmed extends CheckoutState {
  const CheckoutUnconfirmed(this.order);
  final Order order;
}

class CheckoutSoldOut extends CheckoutState {
  const CheckoutSoldOut();
}

class CheckoutExpired extends CheckoutState {
  const CheckoutExpired();
}

enum PaymentWebResult { completed, cancelled }

// ───────────────────────── Test edilebilirlik için bağımlılıklar ─────────────────────────

final idempotencyKeyGeneratorProvider = Provider<String Function()>((_) => const Uuid().v4);

class PollConfig {
  const PollConfig({
    this.interval = const Duration(seconds: 2),
    this.timeout = const Duration(seconds: 30),
    this.delay = realDelay,
  });
  final Duration interval;
  final Duration timeout;
  final Delay delay;
}

final pollConfigProvider = Provider<PollConfig>((_) => const PollConfig());

// ─────────────────────────────── Controller ───────────────────────────────

/// Paket başına bir controller (family arg = packageId). Ekrandan çıkınca dispose olur;
/// tekrar girilirse yeni bir satın alma denemesi = yeni Idempotency-Key.
class CheckoutController extends AutoDisposeFamilyNotifier<CheckoutState, String> {
  /// NEDEN?
  /// Kullanıcı "Satın Al"a bastı, istek backend'e ulaştı ve stok düştü, ama yanıt dönerken
  /// bağlantı koptu. Uygulama "tekrar dene" dediğinde YENİ key ile giderse ikinci bir sipariş
  /// açılır ve stoktan ikinci paket düşer. Aynı key ile giderse backend aynı siparişi döner.
  /// Kural: key, "kesin sonuç" (başarı ya da kalıcı hata) alana kadar korunur.
  String? _idempotencyKey;
  bool _disposed = false;

  @override
  CheckoutState build(String packageId) {
    ref.onDispose(() => _disposed = true);
    return const CheckoutIdle();
  }

  OrdersRepository get _repo => ref.read(ordersRepositoryProvider);

  /// Test ve hata ayıklama için.
  String? get currentIdempotencyKey => _idempotencyKey;

  Future<void> reserve() async {
    final s = state;
    if (s is! CheckoutIdle && s is! CheckoutExpired) return; // çift tıklama koruması

    if (s is CheckoutExpired) _idempotencyKey = null; // süresi dolan deneme bitti → yeni deneme
    _idempotencyKey ??= ref.read(idempotencyKeyGeneratorProvider)();
    state = const CheckoutReserving();

    try {
      final order = await _repo.createOrder(
        packageId: arg,
        quantity: 1,
        idempotencyKey: _idempotencyKey!,
      );
      if (_disposed) return;
      state = CheckoutReserved(order);
    } on ApiError catch (e) {
      if (_disposed) return;
      if (_isTransient(e)) {
        state = CheckoutIdle(error: e); // key KORUNUR → tekrar dene aynı key'i kullanır
        return;
      }
      _idempotencyKey = null; // kesin sonuç → bu deneme kapandı
      state = e.code == ApiErrorCode.outOfStock ? const CheckoutSoldOut() : CheckoutIdle(error: e);
    }
  }

  /// iyzico form URL'ini alır. null → hata state'e yazıldı.
  Future<String?> createPaymentUrl() async {
    final s = state;
    if (s is! CheckoutReserved || s.openingPayment) return null;
    state = CheckoutReserved(s.order, openingPayment: true);
    try {
      final url = await _repo.startCheckout(s.order.id);
      if (_disposed) return null;
      state = CheckoutReserved(s.order);
      return url;
    } on ApiError catch (e) {
      if (_disposed) return null;
      state = e.code == ApiErrorCode.reservationExpired
          ? const CheckoutExpired()
          : CheckoutReserved(s.order, error: e);
      return null;
    }
  }

  /// WebView kapandıktan sonra çağrılır. Gerçek sonuç webhook → backend → GET /orders/{id}.
  /// WebView'in "başarılı" sayfasına GÜVENMİYORUZ: kullanıcı/ağ ortada kesebilir, sahte
  /// yönlendirme olabilir. Tek doğru kaynak sunucudaki order.status.
  Future<void> confirmPayment(PaymentWebResult result) async {
    final s = state;
    final Order order;
    if (s is CheckoutReserved) {
      order = s.order;
    } else if (s is CheckoutUnconfirmed) {
      order = s.order; // "tekrar kontrol et"
    } else {
      return;
    }
    state = CheckoutConfirming(order);

    final cfg = ref.read(pollConfigProvider);
    try {
      final latest = await pollUntil<Order>(
        fetch: () => _repo.getOrder(order.id),
        isDone: (o) => o.status != OrderStatus.PENDING_PAYMENT,
        interval: cfg.interval,
        // Kullanıcı formu kapattıysa uzun bekleme yok: tek bakış yeter.
        timeout: result == PaymentWebResult.cancelled ? Duration.zero : cfg.timeout,
        delay: cfg.delay,
        isCancelled: () => _disposed,
      );
      if (_disposed) return;

      state = switch (latest?.status) {
        OrderStatus.PAID || OrderStatus.PICKED_UP => CheckoutPaid(latest!),
        OrderStatus.EXPIRED || OrderStatus.CANCELLED => const CheckoutExpired(),
        _ when result == PaymentWebResult.cancelled =>
          CheckoutReserved(order), // vazgeçti; süre dolmadıysa tekrar ödeyebilir
        _ => CheckoutUnconfirmed(order),
      };
    } on ApiError catch (e) {
      if (_disposed) return;
      state = CheckoutReserved(order, error: e);
    }
  }

  /// Geri sayım 0'a inince UI çağırır. Backend de stoku geri verir (Redis TTL).
  void markExpired() {
    final s = state;
    if (s is CheckoutReserved) state = const CheckoutExpired();
  }

  static bool _isTransient(ApiError e) =>
      e.code == ApiErrorCode.network ||
      e.code == ApiErrorCode.timeout ||
      e.code == ApiErrorCode.rateLimited ||
      (e.code == ApiErrorCode.unknown && (e.statusCode == null || e.statusCode! >= 500));
}

final checkoutControllerProvider =
    NotifierProvider.autoDispose.family<CheckoutController, CheckoutState, String>(
  CheckoutController.new,
);
