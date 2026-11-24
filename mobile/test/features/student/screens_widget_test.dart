import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sonlokma/core/auth/auth_repository.dart';
import 'package:sonlokma/core/network/api_error.dart';
import 'package:sonlokma/core/network/cursor_page.dart';
import 'package:sonlokma/features/student/checkout/presentation/checkout_controller.dart';
import 'package:sonlokma/features/student/checkout/presentation/checkout_screen.dart';
import 'package:sonlokma/features/student/discover/data/discover_repository_impl.dart';
import 'package:sonlokma/features/student/discover/domain/discover_repository.dart';
import 'package:sonlokma/features/student/discover/domain/geo_point.dart';
import 'package:sonlokma/features/student/discover/domain/nearby_package.dart';
import 'package:sonlokma/features/student/discover/presentation/providers/location_provider.dart';
import 'package:sonlokma/features/student/discover/presentation/widgets/package_list_view.dart';
import 'package:sonlokma/features/student/orders/data/orders_repository_impl.dart';
import 'package:sonlokma/features/student/orders/domain/order.dart';
import 'package:sonlokma/features/student/package_detail/data/package_detail_repository_impl.dart';
import 'package:sonlokma/features/student/package_detail/domain/package_detail.dart';
import 'package:sonlokma/features/student/profile/data/profile_repository_impl.dart';
import 'package:sonlokma/features/student/profile/domain/profile.dart';
import 'package:sonlokma/features/student/profile/presentation/profile_screen.dart';

class MockDiscover extends Mock implements DiscoverRepository {}

class MockOrders extends Mock implements OrdersRepository {}

class MockDetail extends Mock implements PackageDetailRepository {}

class MockProfile extends Mock implements ProfileRepository {}

class FixedLocation implements LocationService {
  @override
  Future<LocationReading> read() async => const LocationReading.ok(GeoPoint(41, 29));
  @override
  Future<void> openSettings(LocationIssue issue) async {}
}

NearbyPackage pkg(String id, String title) => NearbyPackage(
      id: id,
      title: title,
      imageUrl: null,
      price: 8990,
      originalPrice: 25000,
      availableQuantity: 1,
      pickupStart: DateTime(2026, 12, 1, 19),
      pickupEnd: DateTime(2026, 12, 1, 20),
      distanceMeters: 1250,
      businessId: 'b',
      businessName: 'Kampüs Fırını',
      category: BusinessCategory.BAKERY,
      location: const GeoPoint(41, 29),
    );

Widget app(List<Override> overrides, Widget child) =>
    ProviderScope(overrides: overrides, child: MaterialApp(home: Scaffold(body: child)));

void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr_TR');
    registerFallbackValue(const NearbyQuery(center: GeoPoint(0, 0), radiusMeters: 1000));
  });

  group('PackageListView', () {
    late MockDiscover repo;
    List<Override> o() => [
          discoverRepositoryProvider.overrideWithValue(repo),
          locationServiceProvider.overrideWithValue(FixedLocation()),
        ];
    setUp(() => repo = MockDiscover());

    testWidgets('paketleri fiyat, mesafe ve "Son 1!" uyarısıyla listeler', (t) async {
      when(() => repo.nearby(any())).thenAnswer(
          (_) async => CursorPage(items: [pkg('p1', 'Akşam Paketi')], nextCursor: null));
      await t.pumpWidget(app(o(), const PackageListView()));
      await t.pumpAndSettle();

      expect(find.text('Akşam Paketi'), findsOneWidget);
      expect(find.textContaining('1,3 km'), findsOneWidget);
      expect(find.text('Son 1!'), findsOneWidget);
    });

    testWidgets('boş sonuç → açıklayıcı boş durum', (t) async {
      when(() => repo.nearby(any()))
          .thenAnswer((_) async => const CursorPage<NearbyPackage>(items: [], nextCursor: null));
      await t.pumpWidget(app(o(), const PackageListView()));
      await t.pumpAndSettle();
      expect(find.textContaining('Yakınında şu an paket yok'), findsOneWidget);
    });

    testWidgets('ağ hatası → Türkçe mesaj + tekrar dene', (t) async {
      when(() => repo.nearby(any())).thenThrow(const ApiError(code: ApiErrorCode.network));
      await t.pumpWidget(app(o(), const PackageListView()));
      await t.pumpAndSettle();
      expect(find.text('İnternet bağlantını kontrol et.'), findsOneWidget);
      expect(find.text('Tekrar dene'), findsOneWidget);
    });
  });

  group('CheckoutScreen', () {
    late MockOrders orders;
    late MockDetail detail;
    List<Override> o() => [
          ordersRepositoryProvider.overrideWithValue(orders),
          packageDetailRepositoryProvider.overrideWithValue(detail),
          idempotencyKeyGeneratorProvider.overrideWithValue(() => 'k'),
        ];

    setUp(() {
      orders = MockOrders();
      detail = MockDetail();
      when(() => detail.getById(any())).thenThrow(const ApiError(code: ApiErrorCode.notFound));
    });

    void stubCreate(Future<Order> Function() f) => when(() => orders.createOrder(
          packageId: any(named: 'packageId'),
          quantity: any(named: 'quantity'),
          idempotencyKey: any(named: 'idempotencyKey'),
        )).thenAnswer((_) => f());

    testWidgets('409 OUT_OF_STOCK → "Maalesef son paket az önce satıldı."', (t) async {
      stubCreate(() async => throw const ApiError(code: ApiErrorCode.outOfStock, statusCode: 409));
      await t.pumpWidget(app(o(), const CheckoutScreen(packageId: 'p1')));
      await t.pumpAndSettle();
      expect(find.text('Maalesef son paket az önce satıldı.'), findsOneWidget);
    });

    testWidgets('rezerve edilince geri sayım ve ödeme düğmesi görünür', (t) async {
      stubCreate(() async => Order(
            id: 'o1',
            packageId: 'p1',
            quantity: 1,
            totalPrice: 8990,
            status: OrderStatus.PENDING_PAYMENT,
            reservationExpiresAt: DateTime.now().add(const Duration(minutes: 10)),
            createdAt: DateTime.now(),
          ));
      await t.pumpWidget(app(o(), const CheckoutScreen(packageId: 'p1')));
      await t.pump(); // post-frame reserve
      await t.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('countdown')), findsOneWidget);
      expect(find.textContaining(RegExp(r'^(10:00|09:5\d)$')), findsOneWidget);
      expect(find.byKey(const Key('pay_button')), findsOneWidget);
      await t.pumpWidget(const SizedBox()); // Timer'ları kapat
    });
  });

  testWidgets('Profil: sosyal etki animasyonla hedef değere ulaşır', (t) async {
    final repo = MockProfile();
    when(repo.me).thenAnswer((_) async => const Profile(
          user: AppUser(
              id: 'u1', email: 'ali@ogr.edu.tr', name: 'Ali', role: UserRole.STUDENT, isStudentVerified: true),
          impact: Impact(packagesSaved: 12, kgSaved: 9.6, moneySaved: 184000),
        ));
    await t.pumpWidget(app([profileRepositoryProvider.overrideWithValue(repo)], const ProfileScreen()));
    await t.pumpAndSettle();

    expect(find.text('12'), findsOneWidget);
    expect(find.text('9,6 kg'), findsOneWidget);
    expect(find.text('Öğrenci'), findsOneWidget);
  });
}
