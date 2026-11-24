# Harita performansı: önce / sonra (sunum + CV ölçümü)

> Sayıları **gerçek ölçümle** doldur. CV maddesi: "API çağrılarını %X azalttım".

## Kurulum
- Backend seed: 50.000 işletme (`backend/prisma/seed.ts`) veya Prism yerine gerçek backend.
- Fiziksel Android cihaz, **profile** modu (debug modu FPS'i yanıltır).

## Senaryo (her ölçümde aynı)
1. Uygulamayı aç, kampüs merkezinde zoom 14.
2. 30 saniye boyunca: 5 kez sağa-sola kaydır, 3 kez zoom in/out, 1 kez uzak bir semte kaydır.
3. Rozetteki `nearby:` sayısını ve DevTools → Performance'taki ortalama/en kötü kare süresini yaz.

## Komutlar
```powershell
# ÖNCE: clustering yok, debounce yok, 150 m eşiği yok
flutter run --profile --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1 --dart-define=BENCH_OVERLAY=true --dart-define=BENCH_NO_CLUSTER=true --dart-define=BENCH_NO_DEBOUNCE=true
```
```powershell
# SONRA: tüm optimizasyonlar açık
flutter run --profile --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1 --dart-define=BENCH_OVERLAY=true
```
Ara adımlar için yalnızca birini aç: sadece `BENCH_NO_CLUSTER` (FPS etkisi) veya sadece `BENCH_NO_DEBOUNCE` (istek etkisi).

## Sonuçlar
| Ölçüm | Önce | Sadece debounce | Sadece clustering | Sonra |
|---|---|---|---|---|
| `/packages/nearby` istek sayısı (30 sn) | | | | |
| Ortalama kare süresi (ms) | | | | |
| En kötü kare (ms) / jank kare sayısı | | | | |
| Ekrandaki marker / küme sayısı | | | | |

İstek azalması = `(önce − sonra) / önce × 100`.

## Sunumda anlatılacak
- **Debounce (400 ms):** kamera saniyede ~60 olay üretir → kullanıcı durunca 1 istek.
- **150 m eşiği:** debounce "ne zaman", eşik "gerek var mı" sorusunu çözer.
- **Clustering:** GPU/Platform view'a binlerce marker yerine onlarca küme.
- **Cursor pagination:** offset'in aksine yeni paket eklenince kayma/tekrar yok (DB tarafındaki uygulamayı Siret anlatır).
- **Yarış durumu:** filtre değişince eski isteğin cevabı Riverpod'un build iptaliyle çöpe gider.
- **409 kullanıcı tarafı:** Idempotency-Key + "son paket satıldı" ekranı + stok listesinin yenilenmesi.
