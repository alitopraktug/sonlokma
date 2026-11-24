# Katkı Rehberi

Bu repo üç kişilik bir ekip projesidir. Aşağıdaki kurallar herkesin işini kolaylaştırmak ve
geçmişi okunabilir tutmak içindir. Kurallarda değişiklik gerekirse PR ile önerilir.

## 1. Dallar (branch)
- `main` her zaman çalışır durumdadır. **`main`'e doğrudan push yapılmaz.**
- Her iş kendi dalında yapılır: `feature/<kisi>-<kisa-ad>`
  - Örnek: `feature/ben-checkout-flow`, `feature/siret-stock-lock`, `feature/yusuf-iyzico-webhook`
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
- Gizli bilgi (API key, `.env`, `google-services.json`, keystore) **asla** commit edilmez.
  Yanlışlıkla edilirse: hemen ekibe yaz, anahtarı iptal edip yenisini üret (geçmişten silmek yetmez).

## 3. Pull Request
- Başlık commit formatında: `feat(mobile): add checkout flow with idempotent retry`
- Açıklamada: **Ne değişti · Neden · Nasıl test edildi · Ekran görüntüsü (UI ise) · Açık sorular**
- En az **1 onay** olmadan merge edilmez. Kendi PR'ını kendin onaylamazsın.
- CI kırmızıysa merge edilmez.
- Merge yöntemi: **Squash and merge** (main geçmişi PR başına tek, temiz commit olur).
- İnceleme 24 saat içinde yapılır; acil ise WhatsApp'ta haber verilir.
- Yorumlar koda yapılır, kişiye değil. "Bunu şöyle yapsak?" dili kullanılır.

## 4. API kontratı
- `api-contract/openapi.yaml` **tek doğru kaynaktır**.
- Değişiklik PR'ının başlığı `[CONTRACT]` ile başlar ve **üç kişinin de onayı** gerekir.
- Kontratla uyuşmayan bir şey fark edersen kodu kendi kafana göre uydurma; issue aç veya sor.

## 5. Klasör sahipliği
Başkasının klasöründe değişiklik gerekiyorsa o kişiyi PR'a reviewer olarak ekle.

| Klasör | Sahibi |
|---|---|
| `mobile/lib/core/`, `mobile/lib/features/student/` | Ben |
| `backend/` (payments ve qr hariç), `load-tests/` | Siret |
| `mobile/lib/features/business/`, `backend/src/payments/`, `backend/src/qr/`, `admin/`, `.github/`, `docker-compose.yml` | Yusuf |

## 6. İş takibi
- Her iş GitHub Projects board'unda bir kart/issue'dur: Backlog → Sprint → In Progress → Review → Done.
- PR açıklamasına `Closes #12` yazılırsa merge olunca issue otomatik kapanır.
- "Done" = PR merge edildi + CI yeşil + kontrata uygun + temel testler var + hata durumları ele alındı.
