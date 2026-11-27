import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/cursor_page.dart';
import '../domain/order.dart';
import 'order_dto.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  OrdersRepositoryImpl(this._api);
  final ApiClient _api;

  @override
  Future<Order> createOrder({
    required String packageId,
    required int quantity,
    required String idempotencyKey,
  }) async {
    final json = await _api.post<Map<String, dynamic>>(
      '/orders',
      data: {'packageId': packageId, 'quantity': quantity},
      headers: {'Idempotency-Key': idempotencyKey},
    );
    return OrderDto.fromJson(json).toEntity();
  }

  @override
  Future<Order> getOrder(String id) async =>
      OrderDto.fromJson(await _api.get<Map<String, dynamic>>('/orders/$id')).toEntity();

  @override
  Future<CursorPage<Order>> myOrders({String? cursor}) async {
    final json = await _api.get<Map<String, dynamic>>(
      '/orders/me',
      query: {'cursor': cursor, 'limit': 20},
    );
    return CursorPage.fromJson(json, (e) => OrderDto.fromJson(e).toEntity());
  }

  @override
  Future<String> startCheckout(String orderId) async {
    final json = await _api.post<Map<String, dynamic>>(
      '/orders/$orderId/checkout',
    );
    return json['paymentPageUrl'] as String;
  }

  @override
  Future<QrTicket> getQr(String orderId) async =>
      QrTicketDto.fromJson(await _api.get<Map<String, dynamic>>('/orders/$orderId/qr')).toEntity();
}

final ordersRepositoryProvider =
    Provider<OrdersRepository>((ref) => OrdersRepositoryImpl(ref.watch(apiClientProvider)));
