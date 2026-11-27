import 'dart:async';

import 'package:flutter/material.dart';

/// `reservationExpiresAt`'e kadar mm:ss. Kalan süre her saniye "şimdi"den yeniden hesaplanır
/// (sayaç düşürmek yerine) → uygulama arka plana gidip gelse de kaymaz.
/// Not: cihaz saati sunucudan saparsa birkaç saniye fark olabilir; backend TTL belirleyicidir.
class ReservationCountdown extends StatefulWidget {
  const ReservationCountdown({
    super.key,
    required this.expiresAt,
    required this.onExpired,
    this.now = DateTime.now,
  });

  final DateTime expiresAt;
  final VoidCallback onExpired;
  final DateTime Function() now;

  @override
  State<ReservationCountdown> createState() => _ReservationCountdownState();
}

class _ReservationCountdownState extends State<ReservationCountdown> {
  Timer? _timer;
  late Duration _left = _compute();
  bool _fired = false;

  Duration _compute() {
    final d = widget.expiresAt.difference(widget.now());
    return d.isNegative ? Duration.zero : d;
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    WidgetsBinding.instance.addPostFrameCallback((_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    setState(() => _left = _compute());
    if (_left == Duration.zero && !_fired) {
      _fired = true;
      _timer?.cancel();
      widget.onExpired();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final mm = _left.inMinutes.toString().padLeft(2, '0');
    final ss = (_left.inSeconds % 60).toString().padLeft(2, '0');
    final urgent = _left < const Duration(minutes: 1);
    return Semantics(
      label: 'Rezervasyonun bitmesine $mm dakika $ss saniye',
      child: Column(children: [
        Text('Paketin senin için ayrıldı', style: t.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          '$mm:$ss',
          key: const Key('countdown'),
          style: t.textTheme.displayMedium?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()], // rakamlar zıplamasın
            color: urgent ? t.colorScheme.error : t.colorScheme.primary,
          ),
        ),
        Text('içinde ödemeyi tamamla', style: t.textTheme.bodyMedium),
      ]),
    );
  }
}
