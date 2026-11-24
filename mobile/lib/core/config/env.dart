/// Derleme zamanı ortam değerleri. Kodda gizli değer YOK; hepsi --dart-define ile gelir.
///
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4010
abstract final class Env {
  /// Mock (Prism): http://10.0.2.2:4010
  /// Gerçek:       http://10.0.2.2:3000/api/v1
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:4010',
  );

  /// iyzico ödeme formu bittiğinde WebView'in yönlendirildiği callback yolu (Yusuf'un backend'i).
  /// ⚠️ KONTRATTA YOK — Yusuf ile netleştirilmeli. WebView yalnızca kapanmak için kullanır;
  /// ödeme sonucunun doğruluğu her zaman GET /orders/{id} polling ile belirlenir.
  static const paymentCallbackPath = String.fromEnvironment(
    'PAYMENT_CALLBACK_PATH',
    defaultValue: '/payments/callback',
  );

  // ── Sunum benchmark'ı (önce/sonra). Prod'da hepsi false. ──
  /// Marker clustering'i kapat (her paket ayrı marker).
  static const benchNoCluster = bool.fromEnvironment('BENCH_NO_CLUSTER');

  /// Debounce + 150 m eşiğini kapat (her kamera olayı = istek).
  static const benchNoDebounce = bool.fromEnvironment('BENCH_NO_DEBOUNCE');

  /// Haritada istek sayacı rozeti göster.
  static const benchOverlay = bool.fromEnvironment('BENCH_OVERLAY');

  /// Konum izni yoksa haritanın açılacağı kampüs merkezi. Varsayılanı kendi kampüsünüzle değiştirin.
  static final campusLat =
      double.parse(const String.fromEnvironment('CAMPUS_LAT', defaultValue: '41.0422'));
  static final campusLng =
      double.parse(const String.fromEnvironment('CAMPUS_LNG', defaultValue: '29.0094'));
}
}
