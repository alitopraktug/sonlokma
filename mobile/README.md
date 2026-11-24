# SonLokma Mobile

## Kurulum
```powershell
cd mobile
flutter create --org com.sonlokma --project-name sonlokma .   # android/ios klasörlerini üretir, mevcut dosyaları korur
Remove-Item test/widget_test.dart                             # flutter create'in örnek testi
flutter pub get
dart run build_runner build                                   # freezed / json kodunu üretir
flutter analyze
flutter test
```
CI (`.github/workflows/mobile.yml`) aynı adımları her PR'da çalıştırır; yerelde Flutter kurulu olmadan da sonuç görülebilir.

## Çalıştırma
```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4010          # Prism mock
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1   # gerçek backend
```

## Platform ayarları
**Google Maps anahtarı (koda gömülmez):**
- `android/app/build.gradle` → `defaultConfig { manifestPlaceholders += [MAPS_API_KEY: System.getenv("GOOGLE_MAPS_API_KEY") ?: ""] }`
- `AndroidManifest.xml` → `<meta-data android:name="com.google.android.geo.API_KEY" android:value="${MAPS_API_KEY}"/>`
- Konum izni: `ACCESS_COARSE_LOCATION` + `ACCESS_FINE_LOCATION` (Android), `NSLocationWhenInUseUsageDescription` (iOS)

**Firebase (push):** `flutterfire configure` → `android/app/google-services.json`. Dosya yoksa uygulama
bildirimsiz çalışır (çökmez).

**Testler:**
```powershell
flutter test                                          # unit + widget
flutter test integration_test/purchase_flow_test.dart # emülatör açıkken
```

Kampüs merkezi: `--dart-define=CAMPUS_LAT=.. --dart-define=CAMPUS_LNG=..`

Harita benchmark'ı (sunum): bkz. [PERF.md](PERF.md). Kontrat taslağı: `../api-contract/openapi.draft.yaml`.

## Core katmanı (`lib/core/`) — Yusuf da kullanır
| Dosya | Görev |
|---|---|
| `network/api_client.dart` | Tek Dio girişi; `DioException` → `ApiError` |
| `network/auth_interceptor.dart` | Bearer ekler; 401'de **tek** refresh (QueuedInterceptor) |
| `network/api_error.dart` | Kontrat hata kodları + Türkçe mesajlar |
| `auth/` | Token saklama (secure storage), login/register, oturum durumu |
| `router/app_router.dart` | Role göre yönlendirme: STUDENT → alt menülü kabuk, BUSINESS → `/business` |
| `notifications/push_service.dart` | FCM token kaydı, bildirime tıklayınca ekrana yönlendirme |
| `notifications/push_events.dart` | Ön plandaki bildirimleri feature'lara taşıyan olay akışı (core feature'ları import etmez) |
| `network/request_metrics.dart` | Yol başına istek sayacı (harita benchmark'ı) |
| `utils/poll.dart` | Ödeme doğrulama gibi "durum değişene kadar sorgula" işleri |
| `ui/skeleton.dart` | Liste yüklenirken iskelet görünüm |

İşletme ekranlarında hata göstermek için: `try { ... } on ApiError catch (e) { e.userMessage }`.
