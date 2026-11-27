import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sonlokma/core/network/cursor_page.dart';
import 'package:sonlokma/core/notifications/push_events.dart';
import 'package:sonlokma/features/student/orders/data/orders_repository_impl.dart';
import 'package:sonlokma/features/student/orders/domain/order.dart';
import 'package:sonlokma/features/student/orders/presentation/orders_providers.dart';

class MockOrdersRepository extends Mock implements OrdersRepository {}

Order order(String id, OrderStatus s) => Order(
      id: id,
      packageId: 'p',
      quantity: 1,
      totalPrice: 8990,
      status: s,
      reservationExpiresAt: DateTime(2026, 12, 1, 18, 10),
      createdAt: DateTime(2026, 12, 1, 18),
    );

void main() {
  group('PushEvent.fromData', () {
    test('kontrattaki tipler eşlenir', () {
      final e = PushEvent.fromData({'type': 'ORDER_PICKED_UP', 'orderId': 'o1'});
      expect(e.type, PushType.orderPickedUp);
      expect(e.orderId, 'o1');
      expect(e.changesOrder, isTrue);
    });

    test('bilinmeyen tip çökmez', () {
      expect(PushEvent.fromData({'type': 'SOMETHING_NEW'}).type, PushType.unknown);
      expect(PushEvent.fromData(const {}).type, PushType.unknown);
    });

    test('hatırlatma sipariş durumunu değiştirmez', () {
      expect(const PushEvent(PushType.pickupReminder, orderId: 'o1').changesOrder, isFalse);
    });
  });

  group('push ile yenileme', () {
    late MockOrdersRepository repo;
    late ProviderContainer c;
    late PushEventBus bus;

    setUp(() {
      repo = MockOrdersRepository();
      c = ProviderContainer(overrides: [ordersRepositoryProvider.overrideWithValue(repo)]);
      bus = c.read(pushEventBusProvider);
    });
    tearDown(() => c.dispose());

    test('ORDER_PICKED_UP → ilgili sipariş yeniden çekilir, diğeri çekilmez', () async {
      var calls = 0;
      when(() => repo.getOrder('o1')).thenAnswer(
          (_) async => order('o1', ++calls == 1 ? OrderStatus.PAID : OrderStatus.PICKED_UP));
      when(() => repo.getOrder('o2')).thenAnswer((_) async => order('o2', OrderStatus.PAID));

      c.listen(orderProvider('o1'), (_, __) {});
      c.listen(orderProvider('o2'), (_, __) {});
      expect((await c.read(orderProvider('o1').future)).status, OrderStatus.PAID);
      await c.read(orderProvider('o2').future);

      bus.emit(const PushEvent(PushType.orderPickedUp, orderId: 'o1'));
      await Future<void>.delayed(Duration.zero);

      expect((await c.read(orderProvider('o1').future)).status, OrderStatus.PICKED_UP);
      verify(() => repo.getOrder('o1')).called(2);
      verify(() => repo.getOrder('o2')).called(1);
    });

    test('sipariş listesi ödeme bildirimiyle yenilenir, hatırlatmayla yenilenmez', () async {
      when(() => repo.myOrders(cursor: any(named: 'cursor'))).thenAnswer(
          (_) async => CursorPage(items: [order('o1', OrderStatus.PAID)], nextCursor: null));

      c.listen(myOrdersProvider, (_, __) {});
      await c.read(myOrdersProvider.future);

      bus.emit(const PushEvent(PushType.pickupReminder, orderId: 'o1'));
      await Future<void>.delayed(Duration.zero);
      await c.read(myOrdersProvider.future);
      verify(() => repo.myOrders(cursor: any(named: 'cursor'))).called(1);

      bus.emit(const PushEvent(PushType.orderPaid, orderId: 'o1'));
      await Future<void>.delayed(Duration.zero);
      await c.read(myOrdersProvider.future);
      verify(() => repo.myOrders(cursor: any(named: 'cursor'))).called(1); // 1 yeni çağrı
    });
  });
}
