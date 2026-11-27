import 'package:flutter_test/flutter_test.dart';
import 'package:sonlokma/core/notifications/push_service.dart';
import 'package:sonlokma/core/router/app_router.dart';
import 'package:sonlokma/features/student/orders/presentation/qr_controller.dart';

void main() {
  group('qrRefreshDelay', () {
    final now = DateTime(2026, 12, 1, 18);

    test('10 dk geçerli token → 9 dk sonra yenile', () {
      expect(qrRefreshDelay(now.add(const Duration(minutes: 10)), now), const Duration(minutes: 9));
    });

    test('süresi dolmak üzere/dolmuş → 5 sn alt sınır (sonsuz döngü yok)', () {
      expect(qrRefreshDelay(now.add(const Duration(seconds: 30)), now), const Duration(seconds: 5));
      expect(qrRefreshDelay(now.subtract(const Duration(minutes: 1)), now),
          const Duration(seconds: 5));
    });
  });

  group('routeForPush', () {
    test('ORDER_PAID → QR ekranı', () {
      expect(routeForPush({'type': 'ORDER_PAID', 'orderId': 'o1'}), Routes.orderQr('o1'));
    });
    test('PICKUP_REMINDER → sipariş detayı', () {
      expect(routeForPush({'type': 'PICKUP_REMINDER', 'orderId': 'o1'}), Routes.orderDetail('o1'));
    });
    test('orderId yoksa / bilinmeyen tip → null', () {
      expect(routeForPush({'type': 'ORDER_PAID'}), isNull);
      expect(routeForPush({'type': 'WHATEVER', 'orderId': 'o1'}), isNull);
    });
  });
}
