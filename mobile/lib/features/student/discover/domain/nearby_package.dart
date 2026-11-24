import 'geo_point.dart';

enum BusinessCategory { BAKERY, CAFE, RESTAURANT } // ignore: constant_identifier_names

extension BusinessCategoryTr on BusinessCategory {
  String get label => switch (this) {
        BusinessCategory.BAKERY => 'Fırın',
        BusinessCategory.CAFE => 'Kafe',
        BusinessCategory.RESTAURANT => 'Restoran',
      };
}

class NearbyPackage {
  const NearbyPackage({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.originalPrice,
    required this.availableQuantity,
    required this.pickupStart,
    required this.pickupEnd,
    required this.distanceMeters,
    required this.businessId,
    required this.businessName,
    required this.category,
    required this.location,
  });

  final String id;
  final String title;
  final String? imageUrl;

  /// Kuruş (8990 = 89,90 TL). Kontrat gereği int.
  final int price;
  final int originalPrice;
  final int availableQuantity;

  /// Yerel saate çevrilmiş halde tutulur (DTO → entity dönüşümünde).
  final DateTime pickupStart;
  final DateTime pickupEnd;
  final int distanceMeters;
  final String businessId;
  final String businessName;
  final BusinessCategory category;
  final GeoPoint location;

  int get discountPercent =>
      originalPrice <= 0 ? 0 : (((originalPrice - price) / originalPrice) * 100).round();
}
