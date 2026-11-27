import 'package:freezed_annotation/freezed_annotation.dart';

import '../domain/geo_point.dart';
import '../domain/nearby_package.dart';

part 'nearby_package_dto.freezed.dart';
part 'nearby_package_dto.g.dart';

// Üretmek için: dart run build_runner build
// Kaynak: api-contract/openapi.draft.yaml → BusinessSummary, NearbyPackage.

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
    required String businessId,
    required String title,
    required String category,
    required int originalPrice, // kuruş
    required int price, // kuruş
    required int available,
    required String pickupStart, // ISO 8601 UTC
    required String pickupEnd,
    String? photoUrl,
    @Default(true) bool photoIsRepresentative,
    @Default(0) int suspendedAvailable,
    int? distanceMeters, // mahalleyle aramada null
    required BusinessSummaryDto business,
  }) = _NearbyPackageDto;

  factory NearbyPackageDto.fromJson(Map<String, dynamic> json) =>
      _$NearbyPackageDtoFromJson(json);
}

extension NearbyPackageDtoX on NearbyPackageDto {
  NearbyPackage toEntity() => NearbyPackage(
        id: id,
        title: title,
        imageUrl: photoUrl,
        price: price,
        originalPrice: originalPrice,
        availableQuantity: available,
        pickupStart: DateTime.parse(pickupStart).toLocal(),
        pickupEnd: DateTime.parse(pickupEnd).toLocal(),
        distanceMeters: distanceMeters,
        photoIsRepresentative: photoIsRepresentative,
        suspendedAvailable: suspendedAvailable,
        businessId: businessId,
        businessName: business.name,
        category: BusinessCategory.values.byName(category),
        location: GeoPoint(business.lat, business.lng),
      );
}
