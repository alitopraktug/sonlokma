import '../../discover/domain/geo_point.dart';
import '../../discover/domain/nearby_package.dart' show BusinessCategory;

enum PackageStatus { ACTIVE, SOLD_OUT, EXPIRED, CANCELLED } // ignore: constant_identifier_names

class BusinessInfo {
  const BusinessInfo({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.location,
  });
  final String id;
  final String name;
  final BusinessCategory category;
  final String address;
  final GeoPoint location;
}

class PackageDetail {
  const PackageDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.originalPrice,
    required this.totalQuantity,
    required this.availableQuantity,
    required this.pickupStart,
    required this.pickupEnd,
    required this.status,
    required this.business,
    this.contentHints = const [],
    this.allergens = const [],
    this.suspendable = false,
    this.suspendedAvailable = 0,
    this.photoIsRepresentative = true,
  });

  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final int price; // kuruş
  final int originalPrice;
  final int totalQuantity;
  final int availableQuantity;
  final DateTime pickupStart; // yerel
  final DateTime pickupEnd;
  final PackageStatus status;
  final BusinessInfo business;

  /// "Genellikle içinde" ipuçları.
  final List<String> contentHints;

  /// Kontrattaki 14 alerjenden işaretli olanlar (ör. GLUTEN, MILK).
  final List<String> allergens;

  /// Paket askıya bırakılabilir mi.
  final bool suspendable;

  /// İşletmenin askı havuzunda bekleyen paket sayısı.
  final int suspendedAvailable;
  final bool photoIsRepresentative;

  int get discountPercent =>
      originalPrice <= 0 ? 0 : (((originalPrice - price) / originalPrice) * 100).round();

  /// UI ön kontrolü. Asıl karar backend'de (409 OUT_OF_STOCK) — stok her an değişebilir.
  bool canBuy(DateTime now) =>
      status == PackageStatus.ACTIVE && availableQuantity > 0 && pickupEnd.isAfter(now);
}

abstract class PackageDetailRepository {
  Future<PackageDetail> getById(String id);
}
