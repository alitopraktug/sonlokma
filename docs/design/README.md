# SonLokma — Görsel kimlik ve tasarım token'ları

Fikir: **"mahallenin gün sonu tezgâhı"** — kraft kese, fırın fişi, esnaf damgası.
Kaynak: proje brifi Bölüm 7. Ekranlar bu token'larla birebir uygulanır.

| Dosya | İçerik |
|---|---|
| `01-gorsel-kimlik.png` | Logo, kullanım ve yanlış kullanım örnekleri |
| `02-stil-rehberi.png` | Renk, yazı, buton, damga, kart, alt menü |
| `03-uygulama-ikonu.png` | Uygulama ikonu (Android / iOS) |

## Renkler

| Token | Açık tema | Koyu tema | Kullanım |
|---|---|---|---|
| `cream` (krem zemin) | `#F6EFE2` | `#1E1C16` | Sayfa arka planı |
| `olive` (zeytin yazı) | `#3B3F22` | `#ECE4D2` | Metin, ikon |
| `brick` (kiremit) | `#B4532A` | `#D9714A` | Ana düğme, damga |
| `kraft` | `#D9BE91` | `#5A4A30` | Görsel yer tutucu |
| `receipt` (fiş kâğıdı) | `#FFFDF8` | `#2A2820` | Kart, fiş yüzeyi |
| `oliveMuted` (soluk zeytin) | `#6B6E52` | `#B7AE98` | İkincil metin |

QR kodu her temada **beyaz zeminde** gösterilir.

## Yazı karakterleri

| Rol | Font | Nerede |
|---|---|---|
| Başlık | Bricolage Grotesque | Ekran başlıkları, işletme adı |
| Gövde | Inter | Metin, düğme etiketi |
| Mono | IBM Plex Mono | Fiyat, saat, damga, Teslim Fişi |

## Ölçüler

- 8 px ızgara (boşluklar 8'in katları)
- Düğme yüksekliği 52 px, köşe yarıçapı 12 px
- Alt menü: Keşfet · Askıda · Siparişlerim · Profil

## Damgalar

Yalnızca durum bildirir: "Son N paket", "Tükendi", "Askıda N", "Teslim alındı".
Her paket fotoğrafında "Temsilî görsel" notu bulunur.

## Sonraki adım

Bu token'lar 1 Aralık'ta `mobile/lib/core/theme` altına koda aktarılacak.
Müşteri ekranı mockup'ları issue #9 kapsamında bu klasöre eklenecek.
