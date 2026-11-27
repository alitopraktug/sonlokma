import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/formatters.dart';
import '../domain/order.dart';
import 'orders_providers.dart';
import 'orders_screen.dart' show StatusIcon;
import 'resume_payment_button.dart';

/// PICKUP_REMINDER bildirimi buraya açılır.
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(orderProvider(orderId));
    final df = DateFormat('d MMMM HH:mm', 'tr_TR');
    return Scaffold(
      appBar: AppBar(title: const Text('Sipariş')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(orderProvider(orderId)),
            child: Text('${e is ApiError ? e.userMessage : 'Yüklenemedi.'} Tekrar dene'),
          ),
        ),
        data: (o) => RefreshIndicator(
          onRefresh: () => ref.refresh(orderProvider(orderId).future),
          child: ListView(padding: const EdgeInsets.all(16), children: [
            ListTile(
              leading: StatusIcon(o.status),
              title: Text(o.status.label, style: Theme.of(context).textTheme.titleMedium),
            ),
            ListTile(title: const Text('Paket'), subtitle: Text(o.packageTitle ?? '—')),
            if (o.businessName != null)
              ListTile(title: const Text('İşletme'), subtitle: Text(o.businessName!)),
            if (o.pickupStart != null && o.pickupEnd != null)
              ListTile(
                  title: const Text('Teslim aralığı'),
                  subtitle: Text(Fmt.timeRange(o.pickupStart!, o.pickupEnd!))),
            ListTile(title: const Text('Tutar'), subtitle: Text(Fmt.kurus(o.totalPrice))),
            ListTile(title: const Text('Sipariş tarihi'), subtitle: Text(df.format(o.createdAt))),
            if (o.pickedUpAt != null)
              ListTile(title: const Text('Teslim alındı'), subtitle: Text(df.format(o.pickedUpAt!))),
            const SizedBox(height: 16),
            if (o.status == OrderStatus.PAID)
              FilledButton.icon(
                onPressed: () => context.push(Routes.orderQr(o.id)),
                icon: const Icon(Icons.qr_code_2),
                label: const Text('Teslim QR kodunu göster'),
              ),
            if (o.status == OrderStatus.PENDING_PAYMENT) ResumePaymentButton(order: o),
          ]),
        ),
      ),
    );
  }
}
