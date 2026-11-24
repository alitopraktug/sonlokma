import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/formatters.dart';
import '../../discover/presentation/providers/nearby_provider.dart';
import '../../package_detail/data/package_detail_repository_impl.dart';
import 'checkout_controller.dart';
import 'payment_webview_screen.dart';
import 'reservation_countdown.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key, required this.packageId});
  final String packageId;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  CheckoutController get _ctrl => ref.read(checkoutControllerProvider(widget.packageId).notifier);

  @override
  void initState() {
    super.initState();
    // Ekran açılır açılmaz rezerve et: stok yarışında saniyeler önemli.
    WidgetsBinding.instance.addPostFrameCallback((_) => _ctrl.reserve());
  }

  Future<void> _pay() async {
    final url = await _ctrl.createPaymentUrl();
    if (url == null || !mounted) return;
    final result = await ref.read(paymentLauncherProvider)(context, url);
    if (!mounted) return;
    await _ctrl.confirmPayment(result);
  }

  @override
  Widget build(BuildContext context) {
    final provider = checkoutControllerProvider(widget.packageId);
    final state = ref.watch(provider);

    ref.listen(provider, (_, next) {
      if (next is CheckoutPaid) {
        context.go(Routes.orderQr(next.order.id)); // geri tuşu ödeme ekranına dönmesin
      }
      if (next is CheckoutSoldOut || next is CheckoutExpired) {
        // Stok değişti → harita/liste ve detay bayat.
        ref.invalidate(nearbyProvider);
        ref.invalidate(packageDetailProvider(widget.packageId));
      }
    });

    final busy = state is CheckoutReserving || state is CheckoutConfirming;
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('Satın al'), automaticallyImplyLeading: !busy),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: KeyedSubtree(key: ValueKey(state.runtimeType), child: _content(state)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(CheckoutState s) => switch (s) {
        CheckoutIdle(:final error) when error != null => _Result(
            icon: Icons.wifi_off,
            title: error.userMessage,
            primary: ('Tekrar dene', _ctrl.reserve),
          ),
        CheckoutIdle() || CheckoutReserving() =>
          const _Busy('Paket senin için ayrılıyor…'),
        CheckoutReserved(:final order, :final openingPayment, :final error) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Summary(packageId: widget.packageId, total: order.totalPrice),
              const Spacer(),
              ReservationCountdown(
                expiresAt: order.reservationExpiresAt,
                onExpired: _ctrl.markExpired,
              ),
              const Spacer(),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(error.userMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              FilledButton.icon(
                key: const Key('pay_button'),
                onPressed: openingPayment ? null : _pay,
                icon: openingPayment
                    ? const SizedBox.square(
                        dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.lock_outline),
                label: Text('Ödemeye geç · ${Fmt.kurus(order.totalPrice)}'),
              ),
            ],
          ),
        CheckoutConfirming() => const _Busy('Ödemen doğrulanıyor…\nBu birkaç saniye sürebilir.'),
        CheckoutPaid() => const _Busy('Ödeme alındı!'),
        CheckoutUnconfirmed(:final order) => _Result(
            icon: Icons.hourglass_top,
            title: 'Ödemen henüz doğrulanmadı',
            body: 'Bankadan onay gecikiyor olabilir. Ödeme tamamlandığında bildirim alacaksın; '
                'siparişini "Siparişlerim"den de takip edebilirsin.',
            primary: ('Tekrar kontrol et', () => _ctrl.confirmPayment(PaymentWebResult.completed)),
            secondary: ('Siparişlerime git', () => context.go(Routes.orderDetail(order.id))),
          ),
        CheckoutSoldOut() => _Result(
            icon: Icons.sentiment_dissatisfied_outlined,
            title: const ApiError(code: ApiErrorCode.outOfStock).userMessage,
            body: 'Yakınındaki diğer paketlere göz atabilirsin.',
            primary: ('Diğer paketler', () => context.go(Routes.home)),
          ),
        CheckoutExpired() => _Result(
            icon: Icons.timer_off_outlined,
            title: const ApiError(code: ApiErrorCode.reservationExpired).userMessage,
            primary: ('Tekrar dene', _ctrl.reserve),
            secondary: ('Vazgeç', () => context.pop()),
          ),
      };
}

class _Summary extends ConsumerWidget {
  const _Summary({required this.packageId, required this.total});
  final String packageId;
  final int total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(packageDetailProvider(packageId)).valueOrNull;
    final t = Theme.of(context);
    return Card(
      child: ListTile(
        title: Text(p?.title ?? 'Sürpriz paket'),
        subtitle: p == null
            ? null
            : Text('${p.business.name}\nTeslim: ${Fmt.timeRange(p.pickupStart, p.pickupEnd)}'),
        isThreeLine: p != null,
        trailing: Text(Fmt.kurus(total), style: t.textTheme.titleMedium),
      ),
    );
  }
}

class _Busy extends StatelessWidget {
  const _Busy(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(text, textAlign: TextAlign.center),
        ]),
      );
}

class _Result extends StatelessWidget {
  const _Result({
    required this.icon,
    required this.title,
    this.body,
    required this.primary,
    this.secondary,
  });
  final IconData icon;
  final String title;
  final String? body;
  final (String, VoidCallback) primary;
  final (String, VoidCallback)? secondary;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 64),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
          if (body != null) ...[
            const SizedBox(height: 8),
            Text(body!, textAlign: TextAlign.center),
          ],
          const SizedBox(height: 24),
          FilledButton(onPressed: primary.$2, child: Text(primary.$1)),
          if (secondary != null)
            TextButton(onPressed: secondary!.$2, child: Text(secondary!.$1)),
        ]),
      );
}
