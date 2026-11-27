# Katkı Rehberi

Bu repo üç kişilik bir ekip projesidir. Aşağıdaki kurallar herkesin işini kolaylaştırmak ve
geçmişi okunabilir tutmak içindir. Kurallarda değişiklik gerekirse PR ile önerilir.

## 1. Dallar (branch)
- `main` her zaman çalışır durumdadır. **`main`'e doğrudan push yapılmaz.**
- Her iş kendi dalında yapılır: `feature/<kisi>-<kisa-ad>`
  - Örnek: `feature/ben-checkout-flow`, `feature/siret-stock-lock`, `feature/yusuf-iyzico-webhook`
- Her iş bir GitHub issue'suna bağlıdır; PR açıklamasında `Closes #N` veya `Refs #N` yazılır.
- Hata düzeltmesi: `fix/<kisi>-<kisa-ad>` · Dokümantasyon: `docs/<kisi>-<kisa-ad>`
- Dal kısa ömürlüdür: birkaç gün içinde PR'a dönüşür. Uzun süren işler parçalara bölünür.
- Çalışmaya başlamadan önce `main`'i çek: `git pull --rebase origin main`

## 2. Commit mesajları — Conventional Commits
```
<tip>(<kapsam>): <ne yapıldı, emir kipinde, İngilizce, küçük harf, nokta yok>

<isteğe bağlı gövde: NEDEN yapıldı, nelere dikkat edilmeli>
```
| Tip | Ne zaman |
|---|---|
| `feat` | Yeni özellik |
| `fix` | Hata düzeltmesi |
| `test` | Sadece test ekleme/düzeltme |
| `refactor` | Davranışı değiştirmeyen kod düzenlemesi |
| `docs` | Doküman |
| `chore` | Bağımlılık, yapılandırma, araç |
| `perf` | Performans iyileştirmesi |

Kapsam örnekleri: `mobile`, `core`, `orders`, `payments`, `qr`, `admin`, `ci`, `contract`.

**İyi:** `feat(orders): add redis reservation ttl` · `fix(mobile): prevent double tap on buy button`
**Kötü:** `update`, `fix`, `son hali`, `asdf`, `düzeltmeler yapıldı`

Kurallar:
- Bir commit = bir mantıksal değişiklik. "Her şey" tek commit'te olmaz.
- Commit'ler mümkünse tek başına derlenebilir olmalı.
- Commit, PR ve dosyalarda asistan imzası, `Co-Authored-By` satırı veya "Generated with" ifadesi olmaz.
- Gizli bilgi (API key, `.env`, `google-services.json`, keystore) **asla** commit edilmez.
  Mobilde `--dart-define`, backend'de `.env` kullanılır; repoda yalnızca `.env.example` bulunur.
  Yanlışlıkla edilirse: hemen ekibe yaz, anahtarı iptal edip yenisini üret (geçmişten silmek yetmez).

## 3. Pull Request
- Başlık commit formatında: `feat(mobile): add checkout flow with idempotent retry`
- Açıklamada: **Ne değişti · Neden · Nasıl test edildi · Ekran görüntüsü (UI ise) · Açık sorular**
- En az **1 onay** olmadan merge edilmez. Kendi PR'ını kendin onaylamazsın.
- CI kırmızıysa merge edilmez.
- Merge yöntemi: tek başına PR'larda **Squash and merge**; birbirine bağlı (stacked) PR'larda squash **yapılmaz**, normal merge kullanılır (yoksa üstteki dallar bozulur).
- İnceleme 24 saat içinde yapılır; acil ise WhatsApp'ta haber verilir.
- Yorumlar koda yapılır, kişiye değil. "Bunu şöyle yapsak?" dili kullanılır.

### Merge ve review akışı
- **Sıklık:** Her gün, onay + yeşil CI gelir gelmez. Sabit merge günü yok; bekleyen PR çakışma (conflict) üretir.
- **Sabah ilk iş:** Kendi koduna geçmeden bekleyen PR'lara review at.
- **Merge'ü PR sahibi yapar**, ekibe grupta kısa bir haber vererek.
- **24 saat kuralı:** 1 günden uzun bekleyen PR için grupta hatırlatma yapılır.
- **Gün sonu:** O günün işi küçük bir PR olarak açılmış ve review istenmiş olur.
- **Küçük PR:** Bir issue = bir PR; açıklamaya `Closes #12` yazılır, merge olunca issue kapanır.

## 4. API kontratı
- `api-contract/openapi.draft.yaml` (onaydan sonra `openapi.yaml`) **tek doğru kaynaktır**; içeriği proje brifi Bölüm 6 ile birebir aynıdır.
- Para alanları tam sayı **kuruş**; tarihler ISO 8601 UTC, ekranda yerel saate çevrilir.
- Hata gövdesi `{ "code": "...", "message": "..." }`, listeler `{ items, nextCursor }`.
- Değişiklik PR'ının başlığı `[CONTRACT]` ile başlar ve **üç kişinin de onayı** gerekir.
- Kontratla uyuşmayan bir şey fark edersen kodu kendi kafana göre uydurma; issue aç veya sor.

## 5. Klasör sahipliği
Başkasının klasöründe değişiklik gerekiyorsa o kişiyi PR'a reviewer olarak ekle.

| Klasör | Sahibi |
|---|---|
| `mobile/lib/core/`, `mobile/lib/features/customer/` (eski `student/`), mobil testler, `docs/design/`, `web/` | Toprak (@alitopraktug) |
| `backend/` (payments ve qr hariç), `load-tests/`, API dokümanı (Scalar), İngilizce README | Siret (@siretulasli) |
| `mobile/lib/features/business/`, `backend/src/modules/payments/`, `backend/src/modules/qr/`, `admin/`, `.github/workflows/`, Docker, deployment | Yusuf (@RuzgarTugtek) |

Tasarım: bir ekran kodlanmadan önce mockup'ı `docs/design/` altında onaylı olmalıdır.

## 6. İş takibi
- Her iş bir issue'dur ve bir milestone'a bağlıdır: Hafta 1 (25 Kas – 2 Ara), Hafta 2 (3 – 9 Ara), Hafta 3 (10 – 16 Ara).
- PR açıklamasına `Closes #12` yazılırsa merge olunca issue otomatik kapanır.
- "Done" = PR merge edildi + CI yeşil + kontrata uygun + temel testler var + hata durumları ele alındı.
