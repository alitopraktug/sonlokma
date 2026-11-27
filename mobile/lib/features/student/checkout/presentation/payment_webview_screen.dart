import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/config/env.dart';
import 'checkout_controller.dart';

/// Ödeme ekranını açan fonksiyon. Integration testte gerçek WebView yerine sahtesi verilir.
typedef PaymentLauncher = Future<PaymentWebResult> Function(BuildContext context, String url);

final paymentLauncherProvider = Provider<PaymentLauncher>(
  (_) => (context, url) async =>
      await Navigator.of(context).push<PaymentWebResult>(
        MaterialPageRoute(fullscreenDialog: true, builder: (_) => PaymentWebViewScreen(url: url)),
      ) ??
      PaymentWebResult.cancelled,
);

class PaymentWebViewScreen extends StatefulWidget {
  const PaymentWebViewScreen({super.key, required this.url});
  final String url;

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _web;
  int _progress = 0;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // iyzico formu JS gerektirir
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (p) => mounted ? setState(() => _progress = p) : null,
        onNavigationRequest: (req) {
          if (Uri.tryParse(req.url)?.path.endsWith(Env.paymentCallbackPath) ?? false) {
            Navigator.of(context).pop(PaymentWebResult.completed);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
        onWebResourceError: (e) {
          if (e.isForMainFrame ?? true) setState(() => _failed = true);
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<bool> _confirmClose() async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Ödemeden çıkılsın mı?'),
          content: const Text('Paketin rezervasyon süresi boyunca senin için ayrılmaya devam eder.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Devam et')),
            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Çık')),
          ],
        ),
      ) ??
      false;

  Future<void> _close() async {
    if (await _confirmClose() && mounted) Navigator.of(context).pop(PaymentWebResult.cancelled);
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _close();
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Güvenli ödeme'),
            leading: IconButton(icon: const Icon(Icons.close), onPressed: _close),
            bottom: _progress < 100
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(2),
                    child: LinearProgressIndicator(value: _progress / 100),
                  )
                : null,
          ),
          body: _failed
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('Ödeme sayfası açılamadı.'),
                    TextButton(
                      onPressed: () {
                        setState(() => _failed = false);
                        _web.reload();
                      },
                      child: const Text('Tekrar dene'),
                    ),
                  ]),
                )
              : WebViewWidget(controller: _web),
        ),
      );
}
