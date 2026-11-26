# SonLokma

Mahallenin gün sonu tezgâhı: indirimli sürpriz paketler, askıda yemek ve hayırsever bağışı.

SonLokma; fırın, kafe, restoran ve marketlerin ellerinde kalan, tüketime uygun ürünleri indirimli
sürpriz paketler hâlinde sunduğu konum tabanlı bir uygulamadır. Kullanıcılar yakınlarındaki ya da
seçtikleri mahalledeki paketleri keşfeder, paketi ayırtıp öder ve işletmeden QR kodla teslim alır.
Uygulama askıda yemek geleneğini de dijitale taşır: biri paketin parasını öder, paket askıya bırakılır
ve telefonu doğrulanmış biri günde bir paketi ücretsiz alır. Amaç gıda israfını azaltmak ve herkesin
iyi yemeğe ulaşmasını sağlamak.

| Klasör | Sahibi | Teknoloji |
|---|---|---|
| `api-contract/` | Herkes (değişiklik = `[CONTRACT]` PR + 3 onay) | OpenAPI 3 |
| `mobile/lib/core`, `mobile/lib/features/customer`, `docs/design`, `web/` | Toprak | Flutter, Riverpod 2, go_router, dio, freezed |
| `mobile/lib/features/business` | Yusuf | Flutter |
| `backend/` (payments/qr hariç), `load-tests/` | Siret | Node.js, Express, PostgreSQL, Prisma, k6 |
| `backend/src/modules/payments`, `backend/src/modules/qr`, `admin/`, `.github/workflows/`, Docker | Yusuf | iyzico sandbox, GitHub Actions, Docker Compose |

Giriş telefon numarası + SMS kodu ile yapılır (JWT access + refresh rotation). Bildirimler FCM ile gönderilir.

## Çalışma kuralları
Ayrıntılar `CONTRIBUTING.md` dosyasında.
- `main` korumalı; her iş `feature/<kisi>-<kisa-ad>` dalında, PR + en az 1 onay + yeşil CI.
- Commit: Conventional Commits (`feat(orders): add reservation ttl`).
- Gizli anahtarlar repoya girmez; `.env.example` ve `--dart-define` kullanılır.

## Yol haritası
- Hafta 1 (25 Kas – 2 Ara): tasarım, API kontratı, backend iskeleti + OTP, mobilde telefonla giriş
- Hafta 2 (3 – 9 Ara): Keşfet → satın alma → QR teslim; askıda yemek + bağış
- Hafta 3 (10 – 16 Ara): landing page, Docker, deployment, mağazalar, v1.0.0
