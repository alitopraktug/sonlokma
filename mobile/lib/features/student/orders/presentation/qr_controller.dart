import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_error.dart';
import '../data/orders_repository_impl.dart';
import '../domain/order.dart';

/// Kontrat: token 10 dk geçerli, mobil süre dolmadan 1 dk önce yeniler.
/// Alt sınır 5 sn: sunucu saati ileride/geride olsa bile yenileme döngüsüne girmeyelim.
Duration qrRefreshDelay(DateTime expiresAt, DateTime now) {
  final d = expiresAt.difference(now) - const Duration(minutes: 1);
  return d < const Duration(seconds: 5) ? const Duration(seconds: 5) : d;
}

class QrController extends AutoDisposeFamilyAsyncNotifier<QrTicket, String> {
  Timer? _timer;

  @override
  Future<QrTicket> build(String orderId) async {
    ref.onDispose(() => _timer?.cancel());
    final ticket = await ref.read(ordersRepositoryProvider).getQr(orderId);
    _schedule(qrRefreshDelay(ticket.expiresAt, DateTime.now()));
    return ticket;
  }

  void _schedule(Duration d) {
    _timer?.cancel();
    _timer = Timer(d, refresh);
  }

  /// Hata olursa eski QR ekranda kalır (hâlâ geçerli olabilir), 10 sn sonra tekrar denenir.
  Future<void> refresh() async {
    try {
      final t = await ref.read(ordersRepositoryProvider).getQr(arg);
      state = AsyncData(t);
      _schedule(qrRefreshDelay(t.expiresAt, DateTime.now()));
    } on ApiError catch (e, st) {
      state = AsyncError<QrTicket>(e, st).copyWithPrevious(state);
      _schedule(const Duration(seconds: 10));
    }
  }

  /// Uygulama arka plandan dönünce: Timer arka planda çalışmamış olabilir.
  void onResumed() {
    final t = state.valueOrNull;
    if (t == null || t.expiresAt.difference(DateTime.now()) < const Duration(minutes: 1)) {
      refresh();
    }
  }
}

final qrControllerProvider =
    AsyncNotifierProvider.autoDispose.family<QrController, QrTicket, String>(QrController.new);
