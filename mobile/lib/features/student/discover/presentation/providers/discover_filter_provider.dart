import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/discover_repository.dart';
import '../../domain/geo_point.dart';
import '../../domain/nearby_package.dart';

class DiscoverFilter {
  const DiscoverFilter({
    this.category,
    this.radiusKm = 3,
    this.maxPrice,
    this.pickupAfter,
  });

  static const radiusOptionsKm = [1, 3, 5];

  final BusinessCategory? category;
  final int radiusKm;
  final int? maxPrice; // kuruş
  final TimeOfDay? pickupAfter; // bugün, yerel saat

  bool get isDefault =>
      category == null && radiusKm == 3 && maxPrice == null && pickupAfter == null;

  int get activeCount =>
      [category != null, radiusKm != 3, maxPrice != null, pickupAfter != null].where((b) => b).length;

  NearbyQuery toQuery(GeoPoint center, {int limit = 50}) {
    DateTime? after;
    if (pickupAfter != null) {
      final now = DateTime.now();
      after = DateTime(now.year, now.month, now.day, pickupAfter!.hour, pickupAfter!.minute);
    }
    return NearbyQuery(
      center: center,
      radiusMeters: radiusKm * 1000,
      category: category,
      maxPrice: maxPrice,
      pickupAfter: after, // repository UTC'ye çevirir
      limit: limit,
    );
  }

  // copyWith yerine açık kurucu: nullable alanları "temizle" diyebilmek için.
  DiscoverFilter _with({
    Object? category = _keep,
    int? radiusKm,
    Object? maxPrice = _keep,
    Object? pickupAfter = _keep,
  }) =>
      DiscoverFilter(
        category: identical(category, _keep) ? this.category : category as BusinessCategory?,
        radiusKm: radiusKm ?? this.radiusKm,
        maxPrice: identical(maxPrice, _keep) ? this.maxPrice : maxPrice as int?,
        pickupAfter:
            identical(pickupAfter, _keep) ? this.pickupAfter : pickupAfter as TimeOfDay?,
      );

  @override
  bool operator ==(Object other) =>
      other is DiscoverFilter &&
      other.category == category &&
      other.radiusKm == radiusKm &&
      other.maxPrice == maxPrice &&
      other.pickupAfter == pickupAfter;

  @override
  int get hashCode => Object.hash(category, radiusKm, maxPrice, pickupAfter);
}

const _keep = Object();

/// Filtre durumu Riverpod'da (rol dosyası gereği). Değişince nearbyProvider kendiliğinden
/// yeniden sorgular, çünkü build() içinde bunu watch ediyor.
class DiscoverFilterNotifier extends Notifier<DiscoverFilter> {
  @override
  DiscoverFilter build() => const DiscoverFilter();

  void setCategory(BusinessCategory? c) => state = state._with(category: c);
  void setRadiusKm(int km) => state = state._with(radiusKm: km);
  void setMaxPrice(int? kurus) => state = state._with(maxPrice: kurus);
  void setPickupAfter(TimeOfDay? t) => state = state._with(pickupAfter: t);
  void apply(DiscoverFilter f) => state = f;
  void reset() => state = const DiscoverFilter();
}

final discoverFilterProvider =
    NotifierProvider<DiscoverFilterNotifier, DiscoverFilter>(DiscoverFilterNotifier.new);
