import 'package:intl/intl.dart';

abstract final class Fmt {
  static final _money = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);
  static final _time = DateFormat.Hm('tr_TR');

  /// 8990 → "₺89,90". Hesap int kuruşla yapılır, yalnızca gösterimde bölünür.
  static String kurus(int value) => _money.format(value / 100);

  static String timeRange(DateTime start, DateTime end) =>
      '${_time.format(start.toLocal())}–${_time.format(end.toLocal())}';

  static String distance(int meters) =>
      meters < 1000 ? '$meters m' : '${(meters / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
}
