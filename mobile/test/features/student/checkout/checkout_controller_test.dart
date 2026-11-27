import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sonlokma/core/network/api_error.dart';
import 'package:sonlokma/features/student/checkout/presentation/checkout_controller.dart';
import 'package:sonlokma/features/student/orders/data/orders_repository_impl.dart';
import 'package:sonlokma/features/student/orders/domain/order.dart';

class MockOrdersRepository extends Mock implements OrdersRepository {}

Order order(OrderStatus s) => Order(
      id: 'o1',
      packageId: 'p1',
      quantity: 1,
      totalPrice: 8990,
      status: s,
      reservationExpiresAt: DateTime.now().add(const Duration(minutes: 10)),
      createdAt: DateTime.now(),
    );

void main() {
  late MockOrdersRepository repo;
  late ProviderContainer c;
  late int keyCounter;
  late int delays;

  setUp(() {
    repo = MockOrdersRepository();
    keyCounter = 0;
    delays = 0;
    c = ProviderContainer(overrides: [
      ordersRepositoryProvider.overrideWithValue(repo),
      idempotencyKeyGeneratorProvider.overrideWithValue(() => 'key-${++keyCounter}'),
      pollConfigProvider.overrideWithValue(PollConfig(delay: (_) async => delays++)),
    ]);
    // autoDispose provider'ı test boyunca canlı tut
    c.listen(checkoutControllerProvider('p1'), (_, __) {});
  });
  tearDown(() => c.dispose());

  CheckoutController ctrl() => c.read(checkoutControllerProvider('p1').notifier);
  CheckoutState state() => c.read(checkoutControllerProvider('p1'));

  void stubCreate(Future<Order> Function() answer) => when(() => repo.createOrder(
        packageId: any(named: 'packageId'),
        quantity: any(named: 'quantity'),
        idempotencyKey: any(named: 'idempotencyKey'),
      )).thenAnswer((_) => answer());

  List<String> sentKeys() => verify(() => repo.createOrder(
        packageId: 'p1',
        quantity: 1,
        idempotencyKey: captureAny(named: 'idempotencyKey'),
      )).captured.cast<String>();

  group('Idempotency-Key', () {
    test('ağ hatasından sonra tekrar denemede AYNI key gider', () async {
      var call = 0;
      stubCreate(() async {
        if (call++ == 0) throw const ApiError(code: ApiErrorCode.timeout);
        return order(OrderStatus.PENDING_PAYMENT);
      });

      await ctrl().reserve();
      expect(state(), isA<CheckoutIdle>().having((s) => s.error?.code, 'err', ApiErrorCode.timeout));
      await ctrl().reserve();

      expect(state(), isA<CheckoutReserved>());
      expect(sentKeys(), ['key-1', 'key-1']);
    });

    test('kesin hatadan (400) sonra yeni deneme YENİ key alır', () async {
      var call = 0;
      stubCreate(() async {
        if (call++ == 0) throw const ApiError(code: ApiErrorCode.validationError, statusCode: 400);
        return order(OrderStatus.PENDING_PAYMENT);
      });

      await ctrl().reserve();
      await ctrl().reserve();
      expect(sentKeys(), ['key-1', 'key-2']);
    });

    test('süresi dolan rezervasyondan sonra tekrar dene yeni key ile gider', () async {
      stubCreate(() async => order(OrderStatus.PENDING_PAYMENT));
      await ctrl().reserve();
      ctrl().markExpired();
      expect(state(), isA<CheckoutExpired>());

      await ctrl().reserve();
      expect(sentKeys(), ['key-1', 'key-2']);
    });

    test('çift tıklama tek istek atar', () async {
      stubCreate(() async => order(OrderStatus.PENDING_PAYMENT));
      await Future.wait([ctrl().reserve(), ctrl().reserve()]);
      expect(sentKeys().length, 1);
    });
  });

  test('409 OUT_OF_STOCK → SoldOut', () async {
    stubCreate(() async => throw const ApiError(code: ApiErrorCode.outOfStock, statusCode: 409));
    await ctrl().reserve();
    expect(state(), isA<CheckoutSoldOut>());
  });

  group('ödeme doğrulama (polling)', () {
    setUp(() {
      stubCreate(() async => order(OrderStatus.PENDING_PAYMENT));
      when(() => repo.startCheckout('o1')).thenAnswer((_) async => 'https://sandbox/iyzico');
    });

    test('3. sorguda PAID → Paid, 2 kez beklendi', () async {
      var n = 0;
      when(() => repo.getOrder('o1')).thenAnswer((_) async =>
          order(++n < 3 ? OrderStatus.PENDING_PAYMENT : OrderStatus.PAID));

      await ctrl().reserve();
      expect(await ctrl().createPaymentUrl(), 'https://sandbox/iyzico');
      await ctrl().confirmPayment(PaymentWebResult.completed);

      expect(state(), isA<CheckoutPaid>());
      expect(n, 3);
      expect(delays, 2);
    });

    test('ara ağ hatası polling\'i bozmaz', () async {
      var n = 0;
      when(() => repo.getOrder('o1')).thenAnswer((_) async {
        if (++n == 1) throw const ApiError(code: ApiErrorCode.network);
        return order(OrderStatus.PAID);
      });
      await ctrl().reserve();
      await ctrl().confirmPayment(PaymentWebResult.completed);
      expect(state(), isA<CheckoutPaid>());
    });

    test('30 sn boyunca PENDING → Unconfirmed, 16 sorgu (t=0..30, 2 sn arayla)', () async {
      when(() => repo.getOrder('o1')).thenAnswer((_) async => order(OrderStatus.PENDING_PAYMENT));
      await ctrl().reserve();
      await ctrl().confirmPayment(PaymentWebResult.completed);

      expect(state(), isA<CheckoutUnconfirmed>());
      verify(() => repo.getOrder('o1')).called(16);
    });

    test('kullanıcı formu kapattı → tek bakış, PENDING ise tekrar ödemeye döner', () async {
      when(() => repo.getOrder('o1')).thenAnswer((_) async => order(OrderStatus.PENDING_PAYMENT));
      await ctrl().reserve();
      await ctrl().confirmPayment(PaymentWebResult.cancelled);

      expect(state(), isA<CheckoutReserved>());
      verify(() => repo.getOrder('o1')).called(1);
    });

    test('ödeme sırasında rezervasyon düştü → Expired', () async {
      when(() => repo.getOrder('o1')).thenAnswer((_) async => order(OrderStatus.EXPIRED));
      await ctrl().reserve();
      await ctrl().confirmPayment(PaymentWebResult.completed);
      expect(state(), isA<CheckoutExpired>());
    });

    test('checkout 409 RESERVATION_EXPIRED → Expired', () async {
      when(() => repo.startCheckout('o1')).thenThrow(
          const ApiError(code: ApiErrorCode.reservationExpired, statusCode: 409));
      await ctrl().reserve();
      expect(await ctrl().createPaymentUrl(), isNull);
      expect(state(), isA<CheckoutExpired>());
    });
  });
}
