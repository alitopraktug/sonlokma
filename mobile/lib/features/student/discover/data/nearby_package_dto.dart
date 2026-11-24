import 'package:freezed_annotation/freezed_annotation.dart';

import '../domain/geo_point.dart';
import '../domain/nearby_package.dart';

part 'nearby_package_dto.freezed.dart';
part 'nearby_package_dto.g.dart';

// Üretmek için: dart run build_runner build --delete-conflicting-outputs
//
// ⚠️ KONTRAT: Ortak dokümanda nearby item'ının alanları tek tek yazılmamış. Aşağıdaki şekil
// Package modeli + "işletme bilgisi" + "mesafeye göre sıralı" ifadesinden türetildi.
// openapi.yaml yazılırken (Hafta 1) Siret ile birebir netleştirilmeli.

@freezed
abstract class BusinessSummaryDto with _$BusinessSummaryDto {
  const factory BusinessSummaryDto({
    required String id,
    required String name,
    required String category,
    required double lat,
    required double lng,
  }) = _BusinessSummaryDto;

  factory BusinessSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$BusinessSummaryDtoFromJson(json);
}

@freezed
abstract class NearbyPackageDto with _$NearbyPackageDto {
  const factory NearbyPackageDto({
    required String id,
    required String title,
    String? imageUrl,
    required int price,
    required int originalPrice,
    required int availableQuantity,
    required String pickupStart, // ISO 8601 UTC
    required String pickupEnd,
    required int distanceMeters,
    required BusinessSummaryDto business,
  }) = _NearbyPackageDto;

  factory NearbyPackageDto.fromJson(Map<String, dynamic> json) =>
      _$NearbyPackageDtoFromJson(json);
}

extension NearbyPackageDtoX on NearbyPackageDto {
  NearbyPackage toEntity() => NearbyPackage(
        id: id,
        title: title,
        imageUrl: imageUrl,
        price: price,
        originalPrice: originalPrice,
        availableQuantity: availableQuantity,
        pickupStart: DateTime.parse(pickupStart).toLocal(),
        pickupEnd: DateTime.parse(pickupEnd).toLocal(),
        distanceMeters: distanceMeters,
        businessId: business.id,
        businessName: business.name,
        category: BusinessCategory.values.byName(business.category),
        location: GeoPoint(business.lat, business.lng),
      );
}
