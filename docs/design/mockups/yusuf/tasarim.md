# SonLokma · İşletme ve admin ekranları

**Issue #10 · Yusuf · 26 Kasım 2026 · Tasarım incelemesine hazır**

[Tarayıcı önizlemesini aç](onizleme.html). Üstteki seçiciden 19 görünümün tamamına ulaşılır. Düğmeler örnek akışlar arasında geçiş sağlar. Form değerleri ve işlem sonuçları sabit tasarım örnekleridir. Her ekranın bağımsız PNG çıktısı [ekranlar klasöründedir](ekranlar/). Düzenlenebilir kaynak HTML içindeki adlandırılmış ekran bölümleri ve ortak CSS’tir. Yazı tipleri, lisansları ve görseller dosyada gömülüdür.

## Ekranlar ve davranış

| PNG | Amaç ve görünen alanlar | Kullanıcı akışı | Boş durum, hata ve geri dönüş |
|---|---|---|---|
| 01 · İşletme girişi | İşletme hesabını telefonla tanır. Ülke kodu ve cep telefonu alanı. | Numara girilir, SMS istenir, 02 açılır. | Eksik numarada alan altında örnek biçim gösterilir. Gönderim başarısızsa numara korunur. |
| 02 · SMS | Maskeli numara, altı haneli kod ve yeniden gönderim bilgisi. | Doğrulama sonrası ilk işletme girişi 03’e, incelemedeki başvuru 04’e, onaylı hesap 05’e gider. | OTP_INVALID için kodu düzelt. OTP_EXPIRED için yeni kod iste. OTP_RATE_LIMITED için bekle. Brifte kod 3 dakika geçerli, yeniden gönderim 60 saniye, 5 hatalı denemede kilit 15 dakika. |
| 03 · Başvuru | İşletme adı, tek kategori, açık adres. | İşletme bilgileri girilir. Gönderim onayı gelince 04 açılır. | Boş alanı işaretle. Bağlantı kesilirse formu koru. Adresi koordinata dönüştürme kararı aşağıda. |
| 04 · İnceleme | İşletme adı, kategori, ilçe ve başvuru adımları. | Durumu yenile. Onay gelirse panel açılır. | Bekleme sürerken paket yayınlama kapalıdır. Red durumunda sonuç açıklanır. Red gerekçesinin iletimi ve yeniden başvuru karar bekler. |
| 05 · Ana panel | İşletmenin paketleri, mevcut stok, eski ve yeni fiyat, teslim aralığı, tükenen paket. | Paket oluştur → 06. Askı havuzu → 17. Alt menü sipariş, QR ve özeti açar. | İlk ilanda “Henüz paketin yok” ve “Paket oluştur”. Yükleme hatasında yeniden dene. |
| 06 · Paket içeriği | Başlık, dört kategoriden biri ve “Genellikle içinde” ipuçları. | İçeriği gir, 07’ye geç. | Boş başlık veya kategori ilerlemeyi durdurur. Geri dönüşte girilen içerik korunur. |
| 07 · Alerjenler | 14 bağımsız seçim, seçili sayı ve işaretli kutular. | Birden çok alerjen seçilebilir. Örnekte gluten, yumurta, süt seçili. Devam → 08. | Seçim kaldırılabilir. Boş seçimden “alerjensiz” sonucu çıkarılmaz. Boş listenin ürün anlamı ekip kararıdır. |
| 08 · Fiyat ve teslim | Normal ve indirimli satış fiyatı, tam sayı adet, teslim başlangıcı/bitişi, askıya açık seçeneği. | Verileri gir, 09’da müşteri kartını incele. | Adet en az 1. Negatif tutar, satış fiyatının indirim göstermemesi ve ters saat aralığında ilgili alanı düzelt. Bunlar tasarım doğrulamalarıdır. |
| 09 · Önizle ve yayınla | Temsilî paket görseli, işletme, başlık, iki fiyat, stok, saat, ipuçları, alerjenler, askı tercihi. | Düzenle → 06. Yayınla → başarılı yanıt sonrası 05. | Yayın sırasında ikinci gönderimi kapat. Ağ hatasında formu koru. Sonuç belirsizse listeyi yenileyip tekrarı önle. |
| 10 · Canlı siparişler | Bekleyen ve teslim alınan sayıları, sipariş referansı, tür, durum, adet ve saat. | Ödendi durumundaki satın alma veya askıdan alım için 11 açılır. | Liste boşsa “Henüz sipariş yok”. Yenileme kesilirse son verinin saatini koru ve yeniden deneme sun. |
| 11 · QR okut | Kamera çerçevesi, teslim fişi ve tarama durumu. | Fiş çerçeveye girer, doğrulama 13–16 arasındaki uygun sonucu verir. Elle giriş → 12. | Kamera izni yoksa kısa kodla devam et. Okuma sırasında ikinci taramayı beklet. |
| 12 · Kısa kod | Teslim fişindeki kısa kod için tek alan. | Kodu doğrula → 13–16. Kameraya dön → 11. | Boş değerle gönderme. Ağ hatasında kodu koru ve durum doğrulanana dek teslimi tamamlanmış gösterme. |
| 13 · Teslim alındı | Başarılı teslim fişi, paket, adet ve teslim saati. | Sonraki kod → 11 veya siparişler → 10. | Bu ekran yalnız doğrulama başarılı olduğunda açılır. |
| 14 · Geçersiz | QR_INVALID. Kod geçerli bir teslim fişiyle eşleşmedi. | Doğru fişi kontrol et, tekrar okut veya elle gir. | Sipariş durumu korunur. |
| 15 · Süresi doldu | QR_EXPIRED. Sunulan kodun süresi doldu. | Müşterinin fişindeki güncel kodu okut veya yeni kısa kodu kullan. | Teslim aralığı da bitmişse işlemi tamamlanmış gösterme. |
| 16 · Kullanılmış | QR_ALREADY_USED. Sipariş daha önce teslim edilmiş. | Sipariş listesindeki teslim durumunu kontrol et. | İkinci teslim oluşturma. |
| 17 · Askı havuzu | Anonim bağış, askıdan teslim, bekleyen paketler ve son hareketler. | İşletme panelinden açılır. Akşam devri 18’de incelenir. | Boş havuzda sıfır adet ve “Henüz hareket yok”. Veri alınamadığında sayaçları sahte sıfırla doldurma. |
| 18 · Gün sonu | Satılan, toplam teslim edilen, askıdan verilen, yarına devreden paketler ve tahsilat fişi. | İşletme günü sonunda incele, sipariş listesine dön. | İşlemsiz gün sıfır adet ve tutarla gösterilir. Eksik raporda yeniden dene. |
| 19 · Admin onayı | Yöneticiye özel web paneli. Başvuru sayıları, kuyruk, seçili işletmenin kategori ve adresi, onay/red eylemleri. | Satırı seç → bilgileri incele → karar ver. Başarıda satırı kuyruktan kaldır ve sayaçları yenile. | Boş kuyrukta “Bekleyen başvuru yok”. Yetkisiz erişimde panel kapanır. Başka yönetici işlem yaptıysa kararı tekrar uygulamadan kaydı yenile. |

## Veri ve kontrat sınırları

Brif §6 ürün hedefini, açık [PR #2](https://github.com/alitopraktug/sonlokma/pull/2) ise önerilen OpenAPI tanımını gösterir. Aşağıdaki eşlemeler tasarım incelemesi içindir.

- **Paket.** Başlık → `title`, kategori → `category`, ipuçları → `contentHints[]`, alerjenler → `allergens[]`, fiyatlar → `originalPrice` ve `price`, adet → `quantity`, teslim aralığı → `pickupStart` ve `pickupEnd`, askıya açıklık → `suspendable`. Kategoriler sırasıyla Fırın (`BAKERY`), Kafe (`CAFE`), Restoran (`RESTAURANT`), Market (`MARKET`).
- **Alerjenler.** Ekran 07’de soldan sağa ve yukarıdan aşağıya enum sırası `GLUTEN, CRUSTACEANS, EGGS, FISH, PEANUTS, SOY, MILK, NUTS, CELERY, MUSTARD, SESAME, SULPHITES, LUPIN, MOLLUSCS`. Yer fıstığı ve sert kabuklu yemişler ayrı seçeneklerdir.
- **Teslim.** Taslakta `POST /business/orders/verify-qr` taramada `token`, elle girişte `shortCode` alır. Başarılı teslim `PICKED_UP` olur. Kısa kod ile sipariş referansı ayrı değerlerdir.
- **Askı.** Havuz işletme bazlıdır. Bağışçı anonimdir. Tek ödemede 1–10 bağış yapılabilir. Telefonu doğrulanmış kullanıcı Türkiye gününe göre günde bir askı alabilir. `CLAIMED` havuzdan ayrılmayı, siparişte `PICKED_UP` fiziksel teslimi ifade eder. Ayrılan ama teslim edilmeyen paketler bu iki sayaçta farklı değerlendirilir.
- **Örnek gün.** Ekran 18 kapanış anını gösterir. Sekiz ücretli paket ve altı askıdan teslim, toplam 14 teslim eder. On paket bağışının dördü devreder. Örnekte açılış devri ve teslim edilmemiş ayrılmış askı sıfırdır. Sekiz satış × 8.990 kuruş ve on bağış × 8.990 kuruş toplam 161.820 kuruştur. Ekranda ₺1.618,20 görünür. UTC zamanları işletmeye Türkiye yerel saatiyle gösterilir.

### Karar bekleyen konular

| Konu | Ekipten beklenen karar |
|---|---|
| Başvuru ve durum geçidi | PR #2’de `POST /business/apply` önerisi `x-contract-change: true` taşır. Ad, kategori, adres yanında önerilen `lat` ve `lng` değerlerinin nasıl edinileceği, `user.businessStatus` ve `PENDING / APPROVED / REJECTED` durumlarının nasıl okunacağı kesinleşmeli. |
| Admin | Brifte `/admin/*` kapsamı var. Listeleme, karar gönderme, karar çakışması, gerekçe ve yeniden başvuru şemaları açık. |
| İşletme sayımları | Canlı sipariş listesinin veri kaynağı, yenileme yöntemi, askı hareketleri, bağış işlem sayısı ve gün sonu toplamları için işletmeye özel yanıtlar tanımlanmalı. Sipariş referansının sunumu ve raporun kapanış zamanı da gözden geçirilmeli. |
| Paket görseli ve işletme detayı | Fotoğraf yükleme veya kategori görseli politikası açık. PR #2’de paketin gömülü işletme özeti ve adresi öneri olarak işaretli. Önizlemede mevcut temsilî fırın görseli kullanıldı. |
| Form kuralları | Fiyat ilişkisi, gece yarısını aşan teslim pencereleri, alerjen beyanı boş bırakıldığında gösterilecek metin ve varsa red gerekçesi ürün kararı gerektirir. |

## Görsel kararlar ve inceleme

Mobil tuvaller 392 × 848 px, yönetici paneli 1280 × 800 px. Fiş yüzeyi #FFFDF8, krem arka plan #F6EFE2, ana metin #3B3F22, ikincil metin #6B6E52, ana eylem #B4532A ve kraft alanlar #D9BE91. Başlıklarda Bricolage Grotesque, gövdede Inter, fiyat ve saatlerde IBM Plex Mono kullanılır. Form grupları 8 px tabanlıdır. Ana düğmeler 52 px yüksekliğinde ve 12 px köşe yarıçapındadır. Paket formu üç telefon görünümüne ayrılır. Kategori tek seçimlidir, alerjenler bağımsız seçilir.

Paket kartı ve QR kamera örneği Yusuf paketindeki onaylı panolardan alınmıştır. Fotoğrafta “Temsilî görsel” etiketi bulunur. QR beyaz zemindedir. Damgalar stok ve teslim durumunu bildirir. Yönetim paneli, kuyruk ile seçili başvuruyu aynı sayfada tutar.

Güncel üç haftalık planda bu iş 26–27 Kasım tasarım çalışmasıdır. 30 Kasım ekip incelemesi tasarım onayı içindir. İkinci ve üçüncü haftanın uygulama işleri burada yalnızca ekran akışı olarak görünür.

[Issue #10](https://github.com/alitopraktug/sonlokma/issues/10) · [Görsel kimlik ve token’lar · PR #25](https://github.com/alitopraktug/sonlokma/pull/25) · [Müşteri mockup’ları · PR #26](https://github.com/alitopraktug/sonlokma/pull/26)

