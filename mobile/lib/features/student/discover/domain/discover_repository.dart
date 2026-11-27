import '../../../../core/network/cursor_page.dart';
import 'geo_point.dart';
import 'nearby_package.dart';

/// `GET /packages/nearby` parametreleri.
class NearbyQuery {
  const NearbyQuery({
    required this.center,
    required this.radiusMeters,
    this.category,
    this.maxPrice,
    this.pickupAfter,
    this.cursor,
    this.limit = 20,
  }) : assert(radiusMeters <= 10000, 'Kontrat: radius max 10000 m');

  final GeoPoint center;
  final int radiusMeters;
  final BusinessCategory? category;
  final int? maxPrice; // kuruş
  final DateTime? pickupAfter;
  final String? cursor;
  final int limit;

  NearbyQuery withCursor(String? c) => NearbyQuery(
        center: center,
        radiusMeters: radiusMeters,
        category: category,
        maxPrice: maxPrice,
        pickupAfter: pickupAfter,
        cursor: c,
        limit: limit,
      );
}

abstract class DiscoverRepository {
  Future<CursorPage<NearbyPackage>> nearby(NearbyQuery query);
}
