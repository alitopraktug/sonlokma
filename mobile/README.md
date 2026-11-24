# SonLokma Mobile

## Kurulum
```powershell
cd mobile
flutter create --org com.sonlokma --project-name sonlokma .   # android/ios klasörlerini üretir, mevcut dosyaları korur
flutter pub get
flutter test
```

## Çalıştırma
```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4010          # Prism mock
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1   # gerçek backend
```

## İlk kurulumdan sonra
```powershell
dart run build_runner build   # freezed DTO'ları üretir
```
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
| `router/app_router.dart` | Role göre yönlendirme: STUDENT → `/home`, BUSINESS → `/business` |
