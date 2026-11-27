import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/poll.dart';
import '../../checkout/presentation/checkout_controller.dart'
    show PaymentWebResult, pollConfigProvider;
import '../../checkout/presentation/payment_webview_screen.dart';
import '../data/orders_repository_impl.dart';
import '../domain/order.dart';
import 'orders_providers.dart';

/// Ödeme sırasında uygulama kapandıysa sipariş PENDING_PAYMENT'ta kalır.
/// Rezervasyon süresi dolmadıysa kullanıcı aynı siparişin ödemesine buradan devam eder
/// (yeni sipariş açılmaz → stoktan ikinci paket düşmez).
class ResumePaymentButton extends ConsumerStatefulWidget {
  const ResumePaymentButton({super.key, required this.order, this.now = DateTime.now});
  final Order order;
  final DateTime Function() now;

  @override
  ConsumerState<ResumePaymentButton> createState() => _ResumePaymentButtonState();
}

class _ResumePaymentButtonState extends ConsumerState<ResumePaymentButton> {
  bool _busy = false;

  bool get _stillReserved => widget.order.reservationExpiresAt.isAfter(widget.now());

  Future<void> _resume() async {
    if (_busy) return;
    setState(() => _busy = true);
    final repo = ref.read(ordersRepositoryProvider);
    final id = widget.order.id;
    try {
      final url = await repo.startCheckout(id);
      if (!mounted) return;
      final result = await ref.read(paymentLauncherProvider)(context, url);
      if (!mounted) return;

      final cfg = ref.read(pollConfigProvider);
      final latest = await pollUntil<Order>(
        fetch: () => repo.getOrder(id),
        isDone: (o) => o.status != OrderStatus.PENDING_PAYMENT,
        interval: cfg.interval,
        timeout: result == PaymentWebResult.cancelled ? Duration.zero : cfg.timeout,
        delay: cfg.delay,
        isCancelled: () => !mounted,
      );
      if (!mounted) return;
      ref.invalidate(orderProvider(id));
      ref.invalidate(myOrdersProvider);
      if (latest?.status == OrderStatus.PAID) context.go(Routes.orderQr(id));
    } on ApiError catch (e) {
      if (!mounted) return;
      ref.invalidate(orderProvider(id)); // ör. RESERVATION_EXPIRED → durum EXPIRED görünsün
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.userMessage)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_stillReserved) {
      return const Text(
        'Rezervasyon süresi doldu; paket serbest kaldı ve ücret alınmadı.',
        textAlign: TextAlign.center,
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      FilledButton.icon(
        key: const Key('resume_payment'),
        onPressed: _busy ? null : _resume,
        icon: _busy
            ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.lock_outline),
        label: Text('Ödemeye devam et · ${Fmt.kurus(widget.order.totalPrice)}'),
      ),
      const SizedBox(height: 8),
      const Text(
        'Ödemeyi daha önce tamamladıysan birkaç saniye içinde onaylanır; tekrar ödeme yapma.',
        textAlign: TextAlign.center,
      ),
    ]);
  }
}
