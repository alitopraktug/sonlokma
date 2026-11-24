import 'package:freezed_annotation/freezed_annotation.dart';

import '../domain/order.dart';

part 'order_dto.freezed.dart';
part 'order_dto.g.dart';

// ⚠️ KONTRAT: Order alanları Prisma modelinden alındı. `package` özeti (başlık, işletme adı,
// teslim aralığı) kontratta yok; "Siparişlerim" listesinin okunabilir olması için opsiyonel
// olarak eklendi. openapi.yaml'da Siret ile netleştirilmeli. Gelmezse liste yine çalışır.

@freezed
class OrderPackageDto with _$OrderPackageDto {
  const factory OrderPackageDto({
    required String title,
    String? businessName,
    String? pickupStart,
    String? pickupEnd,
  }) = _OrderPackageDto;

  factory OrderPackageDto.fromJson(Map<String, dynamic> json) => _$OrderPackageDtoFromJson(json);
}

@freezed
class OrderDto with _$OrderDto {
  const factory OrderDto({
    required String id,
    required String packageId,
    @Default(1) int quantity,
    required int totalPrice,
    required String status,
    required String reservationExpiresAt,
    required String createdAt,
    String? pickedUpAt,
    OrderPackageDto? package,
  }) = _OrderDto;

  factory OrderDto.fromJson(Map<String, dynamic> json) => _$OrderDtoFromJson(json);
}

@freezed
class QrTicketDto with _$QrTicketDto {
  const factory QrTicketDto({required String qrToken, required String expiresAt}) = _QrTicketDto;

  factory QrTicketDto.fromJson(Map<String, dynamic> json) => _$QrTicketDtoFromJson(json);
}

DateTime _local(String iso) => DateTime.parse(iso).toLocal();
DateTime? _localOrNull(String? iso) => iso == null ? null : _local(iso);

extension OrderDtoX on OrderDto {
  Order toEntity() => Order(
        id: id,
        packageId: packageId,
        quantity: quantity,
        totalPrice: totalPrice,
        status: OrderStatus.values.byName(status),
        reservationExpiresAt: _local(reservationExpiresAt),
        createdAt: _local(createdAt),
        pickedUpAt: _localOrNull(pickedUpAt),
        packageTitle: package?.title,
        businessName: package?.businessName,
        pickupStart: _localOrNull(package?.pickupStart),
        pickupEnd: _localOrNull(package?.pickupEnd),
      );
}

extension QrTicketDtoX on QrTicketDto {
  QrTicket toEntity() => QrTicket(qrToken: qrToken, expiresAt: _local(expiresAt));
}
