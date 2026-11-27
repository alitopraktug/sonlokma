import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/cursor_page.dart';
import '../domain/discover_repository.dart';
import '../domain/nearby_package.dart';
import 'nearby_package_dto.dart';

/// Ayrı bir RemoteDataSource sınıfı yalnızca bir satırı sarmalayacağı için birleştirildi;
/// önbellek (ör. son sorgu) eklenirse ayrıştırılır.
class DiscoverRepositoryImpl implements DiscoverRepository {
  DiscoverRepositoryImpl(this._api);
  final ApiClient _api;

  @override
  Future<CursorPage<NearbyPackage>> nearby(NearbyQuery q) async {
    final json = await _api.get<Map<String, dynamic>>('/packages/nearby', query: toQuery(q));
    return CursorPage.fromJson(json, (e) => NearbyPackageDto.fromJson(e).toEntity());
  }

  static Map<String, dynamic> toQuery(NearbyQuery q) => {
        // 5 ondalık ≈ 1 m hassasiyet; gereksiz uzun query + cache-miss olmasın.
        'lat': q.center.lat.toStringAsFixed(5),
        'lng': q.center.lng.toStringAsFixed(5),
        'radius': q.radiusMeters,
        'category': q.category?.name,
        'maxPrice': q.maxPrice,
        'pickupAfter': q.pickupAfter?.toUtc().toIso8601String(),
        'cursor': q.cursor,
        'limit': q.limit,
      };
}

final discoverRepositoryProvider =
    Provider<DiscoverRepository>((ref) => DiscoverRepositoryImpl(ref.watch(apiClientProvider)));
