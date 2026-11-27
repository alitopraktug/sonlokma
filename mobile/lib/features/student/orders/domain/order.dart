import '../../../../core/network/cursor_page.dart';

/// Kontrat §6 — tüm katmanlarda AYNI isimler.
enum OrderStatus { PENDING_PAYMENT, PAID, PICKED_UP, EXPIRED, CANCELLED } // ignore: constant_identifier_names

/// PURCHASE: satın alma · DONATION: askıya bağış · CLAIM: askıdan ücretsiz alım.
enum OrderType { PURCHASE, DONATION, CLAIM } // ignore: constant_identifier_names

extension OrderStatusTr on OrderStatus {
  String get label => switch (this) {
        OrderStatus.PENDING_PAYMENT => 'Ödeme bekleniyor',
        OrderStatus.PAID => 'Teslim alınmayı bekliyor',
        OrderStatus.PICKED_UP => 'Teslim alındı',
        OrderStatus.EXPIRED => 'Süresi doldu',
        OrderStatus.CANCELLED => 'İptal edildi',
      };
}

class Order {
  const Order({
    required this.id,
    required this.packageId,
    this.type = OrderType.PURCHASE,
    required this.quantity,
    required this.totalPrice,
    required this.status,
    required this.reservationExpiresAt,
    required this.createdAt,
    this.pickedUpAt,
    this.packageTitle,
    this.businessName,
    this.pickupStart,
    this.pickupEnd,
  });

  final String id;
  final String packageId;
  final OrderType type;
  final int quantity;
  final int totalPrice; // kuruş
  final OrderStatus status;
  final DateTime reservationExpiresAt; // yerel
  final DateTime createdAt;
  final DateTime? pickedUpAt;

  // Liste ekranı için gömülü paket özeti (opsiyonel, bkz. order_dto.dart KONTRAT notu)
  final String? packageTitle;
  final String? businessName;
  final DateTime? pickupStart;
  final DateTime? pickupEnd;
}

class QrTicket {
  const QrTicket({required this.token, required this.shortCode, required this.expiresAt});

  /// QR'a basılan kısa ömürlü token.
  final String token;

  /// Kamera çalışmazsa işletmenin elle gireceği kısa kod (ör. K7M2Q9).
  final String shortCode;
  final DateTime expiresAt;
}

abstract class OrdersRepository {
  /// POST /orders + `Idempotency-Key`. 409 OUT_OF_STOCK → ApiError.
  Future<Order> createOrder({
    required String packageId,
    required int quantity,
    required String idempotencyKey,
  });

  Future<Order> getOrder(String id);
  Future<CursorPage<Order>> myOrders({String? cursor});

  /// POST /orders/{id}/checkout → iyzico `paymentPageUrl` (WebView).
  Future<String> startCheckout(String orderId);

  /// GET /orders/{id}/qr — yalnızca PAID siparişlerde.
  Future<QrTicket> getQr(String orderId);
}
