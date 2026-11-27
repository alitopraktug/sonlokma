import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sonlokma/features/student/checkout/presentation/checkout_controller.dart';
import 'package:sonlokma/features/student/checkout/presentation/payment_webview_screen.dart';
import 'package:sonlokma/features/student/orders/data/orders_repository_impl.dart';
import 'package:sonlokma/features/student/orders/domain/order.dart';
import 'package:sonlokma/features/student/orders/presentation/resume_payment_button.dart';

class MockOrdersRepository extends Mock implements OrdersRepository {}

final _now = DateTime(2026, 12, 1, 18, 5);

Order pending({required DateTime expires}) => Order(
      id: 'o1',
      packageId: 'p1',
      quantity: 1,
      totalPrice: 8990,
      status: OrderStatus.PENDING_PAYMENT,
      reservationExpiresAt: expires,
      createdAt: DateTime(2026, 12, 1, 18),
    );

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));

  late MockOrdersRepository repo;
  late List<String> launched;

  Widget host(Order o) => ProviderScope(
        overrides: [
          ordersRepositoryProvider.overrideWithValue(repo),
          pollConfigProvider.overrideWithValue(PollConfig(delay: (_) async {})),
          paymentLauncherProvider.overrideWithValue((_, url) async {
            launched.add(url);
            return PaymentWebResult.cancelled;
          }),
        ],
        child: MaterialApp(home: Scaffold(body: ResumePaymentButton(order: o, now: () => _now))),
      );

  setUp(() {
    repo = MockOrdersRepository();
    launched = [];
  });

  testWidgets('süre dolduysa düğme yok, açıklama var', (t) async {
    await t.pumpWidget(host(pending(expires: _now.subtract(const Duration(minutes: 1)))));
    expect(find.byKey(const Key('resume_payment')), findsNothing);
    expect(find.textContaining('Rezervasyon süresi doldu'), findsOneWidget);
  });

  testWidgets('devam et → AYNI sipariş için ödeme formu açılır, yeni sipariş açılmaz', (t) async {
    when(() => repo.startCheckout('o1')).thenAnswer((_) async => 'https://sandbox/form');
    when(() => repo.getOrder('o1'))
        .thenAnswer((_) async => pending(expires: _now.add(const Duration(minutes: 5))));

    await t.pumpWidget(host(pending(expires: _now.add(const Duration(minutes: 5)))));
    await t.tap(find.byKey(const Key('resume_payment')));
    await t.pumpAndSettle();

    expect(launched, ['https://sandbox/form']);
    verify(() => repo.startCheckout('o1')).called(1);
    verify(() => repo.getOrder('o1')).called(1); // kullanıcı kapattı → tek bakış
    verifyNever(() => repo.createOrder(
          packageId: any(named: 'packageId'),
          quantity: any(named: 'quantity'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ));
  });
}
