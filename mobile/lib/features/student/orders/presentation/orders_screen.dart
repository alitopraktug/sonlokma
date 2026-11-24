import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/formatters.dart';
import '../domain/order.dart';
import 'orders_providers.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myOrdersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Siparişlerim')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(e is ApiError ? e.userMessage : 'Siparişler yüklenemedi.'),
            TextButton(
                onPressed: () => ref.invalidate(myOrdersProvider), child: const Text('Tekrar dene')),
          ]),
        ),
        data: (s) => RefreshIndicator(
          onRefresh: () => ref.refresh(myOrdersProvider.future),
          child: s.items.isEmpty
              ? ListView(children: const [
                  SizedBox(height: 160),
                  Icon(Icons.receipt_long_outlined, size: 48),
                  SizedBox(height: 12),
                  Text('Henüz siparişin yok.\nİlk paketini kurtarmaya ne dersin?',
                      textAlign: TextAlign.center),
                ])
              : NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n.metrics.extentAfter < 400) ref.read(myOrdersProvider.notifier).loadMore();
                    return false;
                  },
                  child: ListView.separated(
                    itemCount: s.items.length + (s.nextCursor != null ? 1 : 0),
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) => i == s.items.length
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()))
                        : _OrderTile(s.items[i]),
                  ),
                ),
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile(this.o);
  final Order o;

  @override
  Widget build(BuildContext context) {
    final active = o.status == OrderStatus.PAID;
    return ListTile(
      leading: StatusIcon(o.status),
      title: Text(o.packageTitle ?? 'Sürpriz paket'),
      subtitle: Text([
        if (o.businessName != null) o.businessName!,
        o.status.label,
        DateFormat('d MMM HH:mm', 'tr_TR').format(o.createdAt),
      ].join(' · ')),
      trailing: active
          ? FilledButton.tonal(
              onPressed: () => context.push(Routes.orderQr(o.id)), child: const Text('QR'))
          : Text(Fmt.kurus(o.totalPrice)),
      onTap: () => context.push(Routes.orderDetail(o.id)),
    );
  }
}

class StatusIcon extends StatelessWidget {
  const StatusIcon(this.status, {super.key});
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final (icon, color) = switch (status) {
      OrderStatus.PENDING_PAYMENT => (Icons.hourglass_top, c.tertiary),
      OrderStatus.PAID => (Icons.qr_code_2, c.primary),
      OrderStatus.PICKED_UP => (Icons.check_circle, c.primary),
      OrderStatus.EXPIRED => (Icons.timer_off_outlined, c.outline),
      OrderStatus.CANCELLED => (Icons.cancel_outlined, c.error),
    };
    return Icon(icon, color: color);
  }
}
