import 'package:freezed_annotation/freezed_annotation.dart';

import '../../discover/data/nearby_package_dto.dart';
import '../../discover/domain/geo_point.dart';
import '../../discover/domain/nearby_package.dart' show BusinessCategory;
import '../domain/package_detail.dart';

part 'package_detail_dto.freezed.dart';
part 'package_detail_dto.g.dart';

// Kaynak: api-contract/openapi.draft.yaml → PackageDetail (NearbyPackage + detay alanları).
// `address` paket seviyesinde gelir (kontrat önerisi, x-contract-change).

@freezed
abstract class PackageDetailDto with _$PackageDetailDto {
  const factory PackageDetailDto({
    required String id,
    required String businessId,
    required String title,
    required String category,
    required int originalPrice, // kuruş
    required int price, // kuruş
    required int available,
    required int quantity,
    required String pickupStart,
    required String pickupEnd,
    String? photoUrl,
    @Default(true) bool photoIsRepresentative,
    @Default(0) int suspendedAvailable,
    @Default(<String>[]) List<String> contentHints,
    @Default(<String>[]) List<String> allergens,
    @Default(false) bool suspendable,
    required String status,
    required String address,
    required BusinessSummaryDto business,
  }) = _PackageDetailDto;

  factory PackageDetailDto.fromJson(Map<String, dynamic> json) =>
      _$PackageDetailDtoFromJson(json);
}

extension PackageDetailDtoX on PackageDetailDto {
  PackageDetail toEntity() => PackageDetail(
        id: id,
        title: title,
        description: contentHints.join(' · '),
        imageUrl: photoUrl,
        price: price,
        originalPrice: originalPrice,
        totalQuantity: quantity,
        availableQuantity: available,
        pickupStart: DateTime.parse(pickupStart).toLocal(),
        pickupEnd: DateTime.parse(pickupEnd).toLocal(),
        status: PackageStatus.values.byName(status),
        contentHints: contentHints,
        allergens: allergens,
        suspendable: suspendable,
        suspendedAvailable: suspendedAvailable,
        photoIsRepresentative: photoIsRepresentative,
        business: BusinessInfo(
          id: businessId,
          name: business.name,
          category: BusinessCategory.values.byName(category),
          address: address,
          location: GeoPoint(business.lat, business.lng),
        ),
      );
}
