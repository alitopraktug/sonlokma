import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screen_brightness/screen_brightness.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/router/app_router.dart';
import 'orders_providers.dart';
import 'qr_controller.dart';

class QrScreen extends ConsumerStatefulWidget {
  const QrScreen({super.key, required this.orderId});
  final String orderId;

  @override
  ConsumerState<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends ConsumerState<QrScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Kasadaki okuyucu düşük parlaklıkta QR'ı zor okur.
    _setBrightness(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setBrightness(false);
    super.dispose();
  }

  Future<void> _setBrightness(bool max) async {
    try {
      max
          ? await ScreenBrightness().setScreenBrightness(1.0)
          : await ScreenBrightness().resetScreenBrightness();
    } catch (_) {/* desteklenmeyen platform / test → önemsiz */}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) {
      _setBrightness(true);
      ref.read(qrControllerProvider(widget.orderId).notifier).onResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(qrControllerProvider(widget.orderId));
    final order = ref.watch(orderProvider(widget.orderId)).valueOrNull;
    final t = Theme.of(context);
    final ticket = async.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teslim QR kodu'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          // Checkout'tan context.go ile gelindiyse geri yığını yok → siparişlere git.
          onPressed: () => context.canPop() ? context.pop() : context.go(Routes.orders),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ticket == null
              ? (async.hasError
                  ? Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(async.error is ApiError
                          ? (async.error! as ApiError).userMessage
                          : 'QR kod alınamadı.'),
                      TextButton(
                        onPressed: () => ref.invalidate(qrControllerProvider(widget.orderId)),
                        child: const Text('Tekrar dene'),
                      ),
                    ])
                  : const CircularProgressIndicator())
              : Column(mainAxisSize: MainAxisSize.min, children: [
                  if (order != null) ...[
                    Text(order.businessName ?? '', style: t.textTheme.titleMedium),
                    Text(order.packageTitle ?? '', style: t.textTheme.bodyMedium),
                    const SizedBox(height: 16),
                  ],
                  // QR her zaman beyaz zeminde: koyu temada da okunabilsin.
                  DecoratedBox(
                    decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: QrImageView(
                        key: const Key('qr_image'),
                        data: ticket.qrToken,
                        size: 260,
                        backgroundColor: Colors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Kodu işletmedeki görevliye okut.', style: t.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text('Kod güvenlik için otomatik yenilenir ve tek kullanımlıktır.',
                      textAlign: TextAlign.center, style: t.textTheme.bodySmall),
                  if (async.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text('Kod yenilenemedi, tekrar deneniyor…',
                          style: TextStyle(color: t.colorScheme.error)),
                    ),
                ]),
        ),
      ),
    );
  }
}
