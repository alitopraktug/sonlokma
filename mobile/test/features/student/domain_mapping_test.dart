import 'package:flutter_test/flutter_test.dart';
import 'package:sonlokma/features/student/discover/domain/geo_point.dart';
import 'package:sonlokma/features/student/discover/domain/nearby_package.dart';
import 'package:sonlokma/features/student/discover/presentation/providers/discover_filter_provider.dart';
import 'package:sonlokma/features/student/discover/presentation/providers/location_provider.dart';
import 'package:sonlokma/features/student/orders/data/order_dto.dart';
import 'package:sonlokma/features/student/orders/domain/order.dart';
import 'package:sonlokma/features/student/package_detail/data/package_detail_dto.dart';
import 'package:sonlokma/features/student/package_detail/domain/package_detail.dart';
import 'package:sonlokma/features/student/profile/domain/profile.dart';

Map<String, dynamic> detailJson({String status = 'ACTIVE', int available = 3}) => {
      'id': 'p1',
      'title': 'Akşam Paketi',
      'price': 8990,
      'originalPrice': 25000,
      'totalQuantity': 5,
      'availableQuantity': available,
      'pickupStart': '2026-12-01T18:00:00Z',
      'pickupEnd': '2026-12-01T19:00:00Z',
      'status': status,
      'business': {
        'id': 'b1',
        'name': 'Kampüs Fırını',
        'category': 'BAKERY',
        'address': 'Kampüs Cd. No:1',
        'lat': 41.0,
        'lng': 29.0,
      },
    };

void main() {
  group('PackageDetail', () {
    final beforeEnd = DateTime.utc(2026, 12, 1, 18, 30);

    test('DTO → entity: description yoksa boş, kategori ve konum eşlenir', () {
      final p = PackageDetailDto.fromJson(detailJson()).toEntity();
      expect(p.description, '');
      expect(p.business.category, BusinessCategory.BAKERY);
      expect(p.business.location, const GeoPoint(41, 29));
      expect(p.discountPercent, 64);
    });

    test('canBuy: aktif + stok var + teslim bitmemiş', () {
      expect(PackageDetailDto.fromJson(detailJson()).toEntity().canBuy(beforeEnd), isTrue);
    });

    test('canBuy false: tükendi, iptal, stok 0 veya teslim saati geçti', () {
      expect(PackageDetailDto.fromJson(detailJson(status: 'SOLD_OUT')).toEntity().canBuy(beforeEnd),
          isFalse);
      expect(PackageDetailDto.fromJson(detailJson(available: 0)).toEntity().canBuy(beforeEnd),
          isFalse);
      expect(
          PackageDetailDto.fromJson(detailJson()).toEntity().canBuy(DateTime.utc(2026, 12, 1, 19, 1)),
          isFalse);
    });
  });

  group('Order DTO', () {
    test('status adları kontratla birebir, tarih UTC → yerel', () {
      final o = OrderDto.fromJson({
        'id': 'o1',
        'packageId': 'p1',
        'totalPrice': 8990,
        'status': 'PENDING_PAYMENT',
        'reservationExpiresAt': '2026-12-01T18:10:00Z',
        'createdAt': '2026-12-01T18:00:00Z',
      }).toEntity();
      expect(o.status, OrderStatus.PENDING_PAYMENT);
      expect(o.quantity, 1); // varsayılan
      expect(o.reservationExpiresAt.isUtc, isFalse);
      expect(o.reservationExpiresAt.toUtc(), DateTime.utc(2026, 12, 1, 18, 10));
      expect(o.packageTitle, isNull); // gömülü özet opsiyonel
    });

    test('her OrderStatus için Türkçe etiket var', () {
      for (final s in OrderStatus.values) {
        expect(s.label, isNotEmpty);
      }
    });
  });

  test('Impact: eksik alanlar 0, kg ondalıklı, CO2 tahmini', () {
    final i = Impact.fromJson({'packagesSaved': 3, 'kgSaved': 2});
    expect(i.packagesSaved, 3);
    expect(i.kgSaved, 2.0);
    expect(i.moneySaved, 0);
    expect(i.co2Kg, 5.0);
  });

  group('DiscoverFilter', () {
    test('varsayılan 3 km, aktif filtre sayısı', () {
      const f = DiscoverFilter();
      expect(f.isDefault, isTrue);
      expect(f.toQuery(const GeoPoint(41, 29)).radiusMeters, 3000);
      const g = DiscoverFilter(category: BusinessCategory.CAFE, radiusKm: 5, maxPrice: 10000);
      expect(g.activeCount, 3);
      expect(g.toQuery(const GeoPoint(41, 29)).maxPrice, 10000);
    });

    test('eşitlik değere göre (gereksiz yeniden sorgu olmasın)', () {
      expect(const DiscoverFilter(radiusKm: 5), const DiscoverFilter(radiusKm: 5));
    });
  });

  test('GeoPoint.distanceTo ~ haversine', () {
    // 0.01° enlem ≈ 1.11 km
    final d = const GeoPoint(41, 29).distanceTo(const GeoPoint(41.01, 29));
    expect(d, closeTo(1112, 5));
  });

  test('her konum sorunu için açıklama ve düğme metni var', () {
    for (final i in LocationIssue.values) {
      final c = locationIssueCopy(i);
      expect(c.message, isNotEmpty);
      expect(c.action, isNotEmpty);
    }
    expect(locationIssueCopy(LocationIssue.deniedForever).action, 'Ayarları aç');
  });
}
