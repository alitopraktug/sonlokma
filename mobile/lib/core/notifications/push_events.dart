import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Kontrat §7: `data.type`. Bilinmeyen tip → [PushType.unknown] (yeni tip eklenirse uygulama çökmesin).
enum PushType { orderPaid, pickupReminder, orderPickedUp, newOrder, unknown }

class PushEvent {
  const PushEvent(this.type, {this.orderId});

  factory PushEvent.fromData(Map<String, dynamic> data) => PushEvent(
        switch (data['type']) {
          'ORDER_PAID' => PushType.orderPaid,
          'PICKUP_REMINDER' => PushType.pickupReminder,
          'ORDER_PICKED_UP' => PushType.orderPickedUp,
          'NEW_ORDER' => PushType.newOrder,
          _ => PushType.unknown,
        },
        orderId: data['orderId'] as String?,
      );

  final PushType type;
  final String? orderId;

  /// Sipariş durumunu değiştiren olaylar → ilgili ekranlar yenilenmeli.
  bool get changesOrder =>
      type == PushType.orderPaid || type == PushType.orderPickedUp || type == PushType.newOrder;
}

/// Push servisi (core) ile feature'lar arasında gevşek bağ: core feature'ları import etmez,
/// feature'lar bu akışı dinler.
class PushEventBus {
  final _controller = StreamController<PushEvent>.broadcast();

  Stream<PushEvent> get stream => _controller.stream;

  void emit(PushEvent e) {
    if (!_controller.isClosed) _controller.add(e);
  }

  Future<void> close() => _controller.close();
}

final pushEventBusProvider = Provider<PushEventBus>((ref) {
  final bus = PushEventBus();
  ref.onDispose(bus.close);
  return bus;
});
