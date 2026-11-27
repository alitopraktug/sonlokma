import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sonlokma/core/network/api_client.dart';
import 'package:sonlokma/features/student/discover/data/discover_repository_impl.dart';
import 'package:sonlokma/features/student/discover/domain/discover_repository.dart';
import 'package:sonlokma/features/student/discover/domain/geo_point.dart';
import 'package:sonlokma/features/student/discover/domain/nearby_package.dart';

class MockApiClient extends Mock implements ApiClient {}

Map<String, dynamic> itemJson(String id) => {
      'id': id,
      'title': 'Sürpriz Paket',
      'imageUrl': null,
      'price': 8990,
      'originalPrice': 25000,
      'availableQuantity': 2,
      'pickupStart': '2026-12-01T18:00:00Z',
      'pickupEnd': '2026-12-01T19:30:00Z',
      'distanceMeters': 420,
      'business': {'id': 'b1', 'name': 'Simit Sarayı', 'category': 'BAKERY', 'lat': 41.04, 'lng': 29.0},
    };

void main() {
  late MockApiClient api;
  late DiscoverRepositoryImpl repo;

  setUp(() {
    api = MockApiClient();
    repo = DiscoverRepositoryImpl(api);
  });

  test('query parametreleri kontrata göre üretilir, null filtreler gönderilmez', () {
    final q = NearbyQuery(
      center: const GeoPoint(41.0422123, 29.0094567),
      radiusMeters: 3000,
      category: BusinessCategory.CAFE,
      pickupAfter: DateTime.utc(2026, 12, 1, 17),
    );
    final map = DiscoverRepositoryImpl.toQuery(q);

    expect(map['lat'], '41.04221');
    expect(map['lng'], '29.00946');
    expect(map['radius'], 3000);
    expect(map['category'], 'CAFE');
    expect(map['maxPrice'], isNull); // ApiClient._clean null'ları atar
    expect(map['pickupAfter'], '2026-12-01T17:00:00.000Z');
  });

  test('yanıt entity\'ye çevrilir: kuruş int kalır, saat yerele döner, indirim hesaplanır', () async {
    when(() => api.get<Map<String, dynamic>>('/packages/nearby', query: any(named: 'query')))
        .thenAnswer((_) async => {'items': [itemJson('p1')], 'nextCursor': 'abc'});

    final page = await repo.nearby(const NearbyQuery(center: GeoPoint(41, 29), radiusMeters: 1000));

    expect(page.nextCursor, 'abc');
    final p = page.items.single;
    expect(p.price, 8990);
    expect(p.discountPercent, 64);
    expect(p.category, BusinessCategory.BAKERY);
    expect(p.pickupStart.isUtc, isFalse);
    expect(p.pickupStart.toUtc(), DateTime.utc(2026, 12, 1, 18));
  });

  test('nextCursor null → son sayfa', () async {
    when(() => api.get<Map<String, dynamic>>(any(), query: any(named: 'query')))
        .thenAnswer((_) async => {'items': <dynamic>[], 'nextCursor': null});

    final page = await repo.nearby(const NearbyQuery(center: GeoPoint(41, 29), radiusMeters: 1000));
    expect(page.isLast, isTrue);
    expect(page.items, isEmpty);
  });
}
