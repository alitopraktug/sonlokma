import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonlokma/core/network/api_error.dart';
import 'package:sonlokma/core/network/cursor_page.dart';
import 'package:sonlokma/core/utils/debouncer.dart';
import 'package:sonlokma/features/student/discover/data/discover_repository_impl.dart';
import 'package:sonlokma/features/student/discover/domain/discover_repository.dart';
import 'package:sonlokma/features/student/discover/domain/geo_point.dart';
import 'package:sonlokma/features/student/discover/domain/nearby_package.dart';
import 'package:sonlokma/features/student/discover/presentation/providers/discover_filter_provider.dart';
import 'package:sonlokma/features/student/discover/presentation/providers/location_provider.dart';
import 'package:sonlokma/features/student/discover/presentation/providers/nearby_provider.dart';

NearbyPackage pkg(String id) => NearbyPackage(
      id: id,
      title: 't',
      imageUrl: null,
      price: 5000,
      originalPrice: 10000,
      availableQuantity: 3,
      pickupStart: DateTime(2026, 12, 1, 18),
      pickupEnd: DateTime(2026, 12, 1, 19),
      distanceMeters: 100,
      businessId: 'b',
      businessName: 'B',
      category: BusinessCategory.CAFE,
      location: const GeoPoint(41, 29),
    );

/// Sayfa 1: p1,p2 (cursor c2) · Sayfa 2: p3 (son). Tüm sorguları kaydeder.
class FakeRepo implements DiscoverRepository {
  final queries = <NearbyQuery>[];
  bool failPage2 = false;

  @override
  Future<CursorPage<NearbyPackage>> nearby(NearbyQuery q) async {
    queries.add(q);
    if (q.cursor == null) return CursorPage(items: [pkg('p1'), pkg('p2')], nextCursor: 'c2');
    if (failPage2) throw const ApiError(code: ApiErrorCode.network);
    return CursorPage(items: [pkg('p3')], nextCursor: null);
  }
}

class FakeLocation implements LocationService {
  FakeLocation(this.point);
  final GeoPoint? point;
  @override
  Future<LocationReading> read() async => point == null
      ? const LocationReading.failed(LocationIssue.denied)
      : LocationReading.ok(point!);
  @override
  Future<void> openSettings(LocationIssue issue) async {}
}

void main() {
  late FakeRepo repo;

  ProviderContainer make({GeoPoint? location = const GeoPoint(41, 29)}) {
    final c = ProviderContainer(overrides: [
      discoverRepositoryProvider.overrideWithValue(repo),
      locationServiceProvider.overrideWithValue(FakeLocation(location)),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  setUp(() => repo = FakeRepo());

  test('ilk sayfa + loadMore listeyi birleştirir, son sayfadan sonra istek atmaz', () async {
    final c = make();
    final s1 = await c.read(nearbyProvider.future);
    expect(s1.items.map((e) => e.id), ['p1', 'p2']);

    await c.read(nearbyProvider.notifier).loadMore();
    final s2 = c.read(nearbyProvider).requireValue;
    expect(s2.items.map((e) => e.id), ['p1', 'p2', 'p3']);
    expect(s2.hasMore, isFalse);

    await c.read(nearbyProvider.notifier).loadMore();
    expect(repo.queries.length, 2);
    expect(repo.queries[1].cursor, 'c2');
  });

  test('aynı anda iki loadMore → tek istek', () async {
    final c = make();
    await c.read(nearbyProvider.future);
    final n = c.read(nearbyProvider.notifier);
    await Future.wait([n.loadMore(), n.loadMore()]);
    expect(repo.queries.where((q) => q.cursor != null).length, 1);
  });

  test('sayfa 2 hatası mevcut listeyi silmez', () async {
    repo.failPage2 = true;
    final c = make();
    await c.read(nearbyProvider.future);
    await c.read(nearbyProvider.notifier).loadMore();

    final s = c.read(nearbyProvider).requireValue;
    expect(s.items.length, 2);
    expect(s.loadMoreError?.code, ApiErrorCode.network);
    expect(s.hasMore, isTrue);
  });

  test('filtre değişince ilk sayfadan yeniden sorgulanır', () async {
    final c = make();
    final sub = c.listen(nearbyProvider, (_, __) {}); // provider canlı kalsın
    await c.read(nearbyProvider.future);

    c.read(discoverFilterProvider.notifier).setRadiusKm(5);
    await c.read(nearbyProvider.future);

    expect(repo.queries.last.radiusMeters, 5000);
    expect(repo.queries.last.cursor, isNull);
    sub.close();
  });

  test('konum izni yoksa kampüs merkezi kullanılır', () async {
    final c = make(location: null);
    await c.read(nearbyProvider.future);
    expect(repo.queries.single.center, campusCenter);
    expect(c.read(userLocationProvider).requireValue.isFallback, isTrue);
  });

  test('150 m altındaki kaydırma yeni merkez üretmez', () {
    final c = make();
    final n = c.read(queryCenterProvider.notifier);
    n.moveTo(const GeoPoint(41.0, 29.0));
    n.moveTo(const GeoPoint(41.0005, 29.0)); // ~55 m
    expect(c.read(queryCenterProvider), const GeoPoint(41.0, 29.0));
    n.moveTo(const GeoPoint(41.003, 29.0)); // ~330 m
    expect(c.read(queryCenterProvider), const GeoPoint(41.003, 29.0));
  });

  test('debouncer: 400 ms içindeki çağrılardan yalnızca sonuncusu çalışır', () {
    fakeAsync((fa) {
      final d = Debouncer(const Duration(milliseconds: 400));
      var calls = 0;
      for (var i = 0; i < 10; i++) {
        d.run(() => calls++);
        fa.elapse(const Duration(milliseconds: 50));
      }
      expect(calls, 0);
      fa.elapse(const Duration(milliseconds: 400));
      expect(calls, 1);
    });
  });
}
