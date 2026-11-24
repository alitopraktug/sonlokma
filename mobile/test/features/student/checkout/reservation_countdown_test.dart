import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonlokma/features/student/checkout/presentation/reservation_countdown.dart';

void main() {
  testWidgets('mm:ss gösterir ve 0\'da bir kez onExpired çağırır', (t) async {
    var now = DateTime(2026, 12, 1, 18, 0, 0);
    final expires = now.add(const Duration(seconds: 3));
    var expired = 0;

    await t.pumpWidget(MaterialApp(
      home: ReservationCountdown(expiresAt: expires, onExpired: () => expired++, now: () => now),
    ));
    expect(find.text('00:03'), findsOneWidget);

    now = now.add(const Duration(seconds: 2));
    await t.pump(const Duration(seconds: 1));
    expect(find.text('00:01'), findsOneWidget);

    now = now.add(const Duration(seconds: 5)); // arka plandan dönüş gibi büyük sıçrama
    await t.pump(const Duration(seconds: 1));
    await t.pump(const Duration(seconds: 1));
    expect(find.text('00:00'), findsOneWidget);
    expect(expired, 1);
  });
}
