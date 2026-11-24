import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sonlokma/core/network/api_error.dart';
import 'package:sonlokma/core/network/cursor_page.dart';
import 'package:sonlokma/features/student/orders/data/orders_repository_impl.dart';
import 'package:sonlokma/features/student/orders/domain/order.dart';
import 'package:sonlokma/features/student/orders/presentation/orders_providers.dart';

class MockOrdersRepository extends Mock implements OrdersRepository {}

Order order(String id) => Order(
      id: id,
      packageId: 'p',
      quantity: 1,
      totalPrice: 8990,
      status: OrderStatus.PAID,
      reservationExpiresAt: DateTime(2026, 12, 1, 18, 10),
      createdAt: DateTime(2026, 12, 1, 18),
    );

void main() {
  late MockOrdersRepository repo;
  late ProviderContainer c;

  setUp(() {
    repo = MockOrdersRepository();
    c = ProviderContainer(overrides: [ordersRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(c.dispose);
  });

  test('loadMore sonraki sayfayı imleçle ekler; son sayfada istek atmaz', () async {
    when(() => repo.myOrders()).thenAnswer(
        (_) async => CursorPage(items: [order('o1')], nextCursor: 'c1'));
    when(() => repo.myOrders(cursor: 'c1')).thenAnswer(
        (_) async => CursorPage(items: [order('o2')], nextCursor: null));

    await c.read(myOrdersProvider.future);
    await c.read(myOrdersProvider.notifier).loadMore();
    expect(c.read(myOrdersProvider).value!.items.map((o) => o.id), ['o1', 'o2']);

    await c.read(myOrdersProvider.notifier).loadMore();
    verify(() => repo.myOrders(cursor: 'c1')).called(1);
  });

  test('loadMore hatasında mevcut liste korunur, imleç kaybolmaz', () async {
    when(() => repo.myOrders()).thenAnswer(
        (_) async => CursorPage(items: [order('o1')], nextCursor: 'c1'));
    when(() => repo.myOrders(cursor: 'c1')).thenThrow(const ApiError(code: ApiErrorCode.network));

    await c.read(myOrdersProvider.future);
    await c.read(myOrdersProvider.notifier).loadMore();
    final s = c.read(myOrdersProvider).value!;
    expect(s.items.map((o) => o.id), ['o1']);
    expect(s.nextCursor, 'c1');
    expect(s.error?.code, ApiErrorCode.network);
  });
}
