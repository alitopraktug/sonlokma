import 'package:freezed_annotation/freezed_annotation.dart';

import '../../discover/domain/geo_point.dart';
import '../../discover/domain/nearby_package.dart' show BusinessCategory;
import '../domain/package_detail.dart';

part 'package_detail_dto.freezed.dart';
part 'package_detail_dto.g.dart';

// ⚠️ KONTRAT: "Detay + işletme bilgisi" ifadesinden türetildi; openapi.yaml'da netleştirilmeli.

@freezed
class BusinessDetailDto with _$BusinessDetailDto {
  const factory BusinessDetailDto({
    required String id,
    required String name,
    required String category,
    required String address,
    required double lat,
    required double lng,
  }) = _BusinessDetailDto;

  factory BusinessDetailDto.fromJson(Map<String, dynamic> json) =>
      _$BusinessDetailDtoFromJson(json);
}

@freezed
class PackageDetailDto with _$PackageDetailDto {
  const factory PackageDetailDto({
    required String id,
    required String title,
    @Default('') String description,
    String? imageUrl,
    required int price,
    required int originalPrice,
    required int totalQuantity,
    required int availableQuantity,
    required String pickupStart,
    required String pickupEnd,
    required String status,
    required BusinessDetailDto business,
  }) = _PackageDetailDto;

  factory PackageDetailDto.fromJson(Map<String, dynamic> json) =>
      _$PackageDetailDtoFromJson(json);
}

extension PackageDetailDtoX on PackageDetailDto {
  PackageDetail toEntity() => PackageDetail(
        id: id,
        title: title,
        description: description,
        imageUrl: imageUrl,
        price: price,
        originalPrice: originalPrice,
        totalQuantity: totalQuantity,
        availableQuantity: availableQuantity,
        pickupStart: DateTime.parse(pickupStart).toLocal(),
        pickupEnd: DateTime.parse(pickupEnd).toLocal(),
        status: PackageStatus.values.byName(status),
        business: BusinessInfo(
          id: business.id,
          name: business.name,
          category: BusinessCategory.values.byName(business.category),
          address: business.address,
          location: GeoPoint(business.lat, business.lng),
        ),
      );
}
