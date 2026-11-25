// Çalıştırma (emülatör/cihaz açıkken):
//   flutter test integration_test/purchase_flow_test.dart
//
// Backend'e bağlanmaz: repository'ler sahte. Amaç UI akışını uçtan uca doğrulamak:
// login → liste → paket detay → satın al → ödeme → QR.
// Gerçek backend'e karşı aynı akış için override'ları kaldırıp API_BASE_URL vermek yeterli.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sonlokma/core/auth/auth_repository.dart';
import 'package:sonlokma/core/network/cursor_page.dart';
import 'package:sonlokma/core/notifications/push_service.dart';
import 'package:sonlokma/features/student/checkout/presentation/checkout_controller.dart';
import 'package:sonlokma/features/student/checkout/presentation/payment_webview_screen.dart';
import 'package:sonlokma/features/student/discover/data/discover_repository_impl.dart';
import 'package:sonlokma/features/student/discover/domain/discover_repository.dart';
import 'package:sonlokma/features/student/discover/domain/geo_point.dart';
import 'package:sonlokma/features/student/discover/domain/nearby_package.dart';
import 'package:sonlokma/features/student/discover/presentation/providers/location_provider.dart';
import 'package:sonlokma/features/student/orders/data/orders_repository_impl.dart';
import 'package:sonlokma/features/student/orders/domain/order.dart';
import 'package:sonlokma/features/student/package_detail/data/package_detail_repository_impl.dart';
import 'package:sonlokma/features/student/package_detail/domain/package_detail.dart';
import 'package:sonlokma/main.dart';

class MockAuth extends Mock implements AuthRepository {}

class NoPush implements PushService {
  @override
  Future<void> start() async {}
}

class FixedLocation implements LocationService {
  @override
  Future<LocationReading> read() async => const LocationReading.ok(GeoPoint(41.0422, 29.0094));
  @override
  Future<void> openSettings(LocationIssue issue) async {}
}

final _now = DateTime.now();
final _pickupStart = _now.add(const Duration(hours: 1));
final _pickupEnd = _now.add(const Duration(hours: 2));
const _title = 'Akşam Sürpriz Paketi';

class FakeDiscover implements DiscoverRepository {
  @override
  Future<CursorPage<NearbyPackage>> nearby(NearbyQuery q) async => CursorPage(items: [
        NearbyPackage(
          id: 'p1',
          title: _title,
          imageUrl: null,
          price: 8990,
          originalPrice: 25000,
          availableQuantity: 3,
          pickupStart: _pickupStart,
          pickupEnd: _pickupEnd,
          distanceMeters: 350,
          businessId: 'b1',
          businessName: 'Mahalle Fırını',
          category: BusinessCategory.BAKERY,
          location: const GeoPoint(41.043, 29.01),
        ),
      ], nextCursor: null);
}

class FakeDetail implements PackageDetailRepository {
  @override
  Future<PackageDetail> getById(String id) async => PackageDetail(
        id: id,
        title: _title,
        description: 'Günün taze ürünleri',
        imageUrl: null,
        price: 8990,
        originalPrice: 25000,
        totalQuantity: 5,
        availableQuantity: 3,
        pickupStart: _pickupStart,
        pickupEnd: _pickupEnd,
        status: PackageStatus.ACTIVE,
        business: const BusinessInfo(
          id: 'b1',
          name: 'Mahalle Fırını',
          category: BusinessCategory.BAKERY,
          address: 'Çarşı Cd. No:1',
          location: GeoPoint(41.043, 29.01),
        ),
      );
}

/// Mock sunucudaki PENDING_PAYMENT → PAID akışının taklidi: 2. sorguda PAID.
class FakeOrders implements OrdersRepository {
  int polls = 0;
  final keys = <String>[];

  Order _order(OrderStatus s) => Order(
        id: 'o1',
        packageId: 'p1',
        quantity: 1,
        totalPrice: 8990,
        status: s,
        reservationExpiresAt: DateTime.now().add(const Duration(minutes: 10)),
        createdAt: DateTime.now(),
        packageTitle: _title,
        businessName: 'Mahalle Fırını',
      );

  @override
  Future<Order> createOrder({
    required String packageId,
    required int quantity,
    required String idempotencyKey,
  }) async {
    keys.add(idempotencyKey);
    return _order(OrderStatus.PENDING_PAYMENT);
  }

  @override
  Future<Order> getOrder(String id) async =>
      _order(++polls >= 2 ? OrderStatus.PAID : OrderStatus.PENDING_PAYMENT);

  @override
  Future<CursorPage<Order>> myOrders({String? cursor}) async =>
      CursorPage(items: [_order(OrderStatus.PAID)], nextCursor: null);

  @override
  Future<String> startCheckout(String orderId) async => 'https://sandbox.example/checkout';

  @override
  Future<QrTicket> getQr(String orderId) async => QrTicket(
        qrToken: 'eyJvaWQiOiJvMSJ9.c2ln',
        expiresAt: DateTime.now().add(const Duration(minutes: 10)),
      );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login → paket seç → satın al → QR', (t) async {
    await initializeDateFormatting('tr_TR');
    final auth = MockAuth();
    final orders = FakeOrders();
    when(() => auth.restoreSession()).thenAnswer((_) async => null);
    when(() => auth.login(any(), any())).thenAnswer((_) async => const AppUser(
          id: 'u1',
          email: 'ali@example.com',
          name: 'Ali',
          role: UserRole.CUSTOMER,
        ));

    await t.pumpWidget(ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        pushServiceProvider.overrideWithValue(NoPush()),
        locationServiceProvider.overrideWithValue(FixedLocation()),
        discoverRepositoryProvider.overrideWithValue(FakeDiscover()),
        packageDetailRepositoryProvider.overrideWithValue(FakeDetail()),
        ordersRepositoryProvider.overrideWithValue(orders),
        pollConfigProvider.overrideWithValue(
            const PollConfig(interval: Duration(milliseconds: 100))),
        // WebView yerine: kullanıcı ödemeyi tamamladı ve callback'e dönüldü.
        paymentLauncherProvider.overrideWithValue((_, __) async => PaymentWebResult.completed),
      ],
      child: const SonLokmaApp(),
    ));
    await t.pumpAndSettle();

    // 1) Giriş
    await t.enterText(find.byKey(const Key('login_email')), 'ali@example.com');
    await t.enterText(find.byKey(const Key('login_password')), 'sifre1234');
    await t.tap(find.byKey(const Key('login_submit')));
    await t.pumpAndSettle();

    // 2) Liste görünümüne geç ve paketi seç
    await t.tap(find.text('Liste'));
    await t.pumpAndSettle();
    expect(find.text(_title), findsOneWidget);
    await t.tap(find.text(_title));
    await t.pumpAndSettle();

    // 3) Detay → Satın al
    expect(find.textContaining('%64 indirim'), findsOneWidget);
    await t.tap(find.byKey(const Key('buy_button')));
    await t.pumpAndSettle();

    // 4) Rezerve edildi, geri sayım görünüyor → ödemeye geç
    expect(find.byKey(const Key('countdown')), findsOneWidget);
    await t.tap(find.byKey(const Key('pay_button')));

    // Polling (100 ms aralık) — geri sayım Timer'ı yüzünden pumpAndSettle bitmez, adım adım pump.
    for (var i = 0; i < 20 && find.byKey(const Key('qr_image')).evaluate().isEmpty; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }

    // 5) QR ekranı
    expect(find.byKey(const Key('qr_image')), findsOneWidget);
    expect(orders.keys, hasLength(1), reason: 'tek sipariş, tek Idempotency-Key');
    expect(orders.polls, greaterThanOrEqualTo(2));
  });
}
