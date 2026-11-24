# SonLokma

Kampüs çevresindeki fırın, kafe ve restoranların gün sonu ürünlerini öğrencilere indirimli
**sürpriz paket** olarak sunan, konum tabanlı mobil pazar yeri.

| Klasör | Sahibi | Teknoloji |
|---|---|---|
| `api-contract/` | Herkes (değişiklik = `[CONTRACT]` PR + 3 onay) | OpenAPI 3 |
| `mobile/lib/core`, `mobile/lib/features/student` | Ben | Flutter, Riverpod |
| `mobile/lib/features/business` | Yusuf | Flutter |
| `backend/` (payments/qr hariç) | Siret | NestJS, Prisma, PostGIS |
| `backend/src/payments`, `backend/src/qr`, `admin/`, `.github/`, `docker-compose.yml` | Yusuf | NestJS, Next.js, Docker |

## Çalışma kuralları
- `main` korumalı; her iş `feature/<kisi>-<kisa-ad>` dalında, PR + en az 1 onay + yeşil CI.
- Commit: Conventional Commits (`feat(orders): add reservation TTL`).
- Gizli anahtarlar repoya girmez; `.env.example` kullanılır.
