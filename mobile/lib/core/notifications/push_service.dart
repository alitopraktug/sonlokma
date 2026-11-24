import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import '../router/app_router.dart';
import '../ui/messenger.dart';

/// Kontrat §7 push formatı: `{ data: { type, orderId } }` → hedef rota. Saf fonksiyon → test edilir.
String? routeForPush(Map<String, dynamic> data) {
  final id = data['orderId'] as String?;
  return switch (data['type']) {
    'ORDER_PAID' when id != null => Routes.orderQr(id),
    'PICKUP_REMINDER' when id != null => Routes.orderDetail(id),
    'ORDER_PICKED_UP' when id != null => Routes.orderDetail(id),
    'NEW_ORDER' => Routes.business, // işletme tarafı (Yusuf) kendi alt rotasını ekleyebilir
    _ => null,
  };
}

String _foregroundText(String? type) => switch (type) {
      'ORDER_PAID' => 'Ödemen onaylandı! QR kodun hazır.',
      'PICKUP_REMINDER' => 'Paketini teslim almayı unutma.',
      'ORDER_PICKED_UP' => 'Afiyet olsun! Paketin teslim edildi.',
      'NEW_ORDER' => 'Yeni sipariş geldi.',
      _ => 'Yeni bildirim',
    };

abstract class PushService {
  /// Giriş yapıldıktan sonra çağrılır (device-token endpoint'i auth ister).
  Future<void> start();
}

class FirebasePushService implements PushService {
  FirebasePushService(this._ref);
  final Ref _ref;
  bool _started = false;
  final _subs = <StreamSubscription<dynamic>>[];

  GoRouter get _router => _ref.read(appRouterProvider);

  @override
  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
    } catch (e) {
      // google-services.json yoksa (ör. ilk kurulum, CI) uygulama bildirimsiz çalışmaya devam eder.
      debugPrint('Firebase başlatılamadı, push kapalı: $e');
      return;
    }

    final fm = FirebaseMessaging.instance;
    await fm.requestPermission(); // Android 13+ ve iOS için

    final repo = _ref.read(authRepositoryProvider);
    Future<void> register(String? token) async {
      if (token == null) return;
      try {
        await repo.registerDeviceToken(token);
      } catch (e) {
        debugPrint('FCM token kaydedilemedi: $e'); // bir sonraki açılışta tekrar denenir
      }
    }

    await register(await fm.getToken());
    _subs.add(fm.onTokenRefresh.listen(register));

    // Uygulama kapalıyken bildirime tıklanıp açıldıysa
    final initial = await fm.getInitialMessage();
    if (initial != null) _open(initial.data);

    // Arka plandayken tıklandı
    _subs.add(FirebaseMessaging.onMessageOpenedApp.listen((m) => _open(m.data)));

    // Ön plandayken sistem bildirimi gösterilmez → snackbar
    _subs.add(FirebaseMessaging.onMessage.listen((m) {
      final route = routeForPush(m.data);
      scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
        content: Text(_foregroundText(m.data['type'] as String?)),
        action: route == null ? null : SnackBarAction(label: 'Göster', onPressed: () => _router.push(route)),
      ));
    }));
  }

  void _open(Map<String, dynamic> data) {
    final route = routeForPush(data);
    if (route != null) _router.push(route);
  }

  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
  }
}

final pushServiceProvider = Provider<PushService>((ref) {
  final s = FirebasePushService(ref);
  ref.onDispose(s.dispose);
  return s;
});

/// Kullanıcı giriş yapınca push'u başlatır. main.dart'ta watch edilir.
final pushBootstrapProvider = Provider<void>((ref) {
  ref.listen(authControllerProvider, (_, next) {
    if (next.valueOrNull != null) ref.read(pushServiceProvider).start();
  }, fireImmediately: true);
});
