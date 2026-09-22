# Paket 4 — Kullanım kolaylığı

Ana ekranda sürekli görünen alt menü: **Ana Sayfa, Kartvizitler, Hatırlatmalar, Kartım, Ayarlar**. Tarama ve toplu tarama Ana Sayfa üzerinden açılır. Android geri hareketi başka bir ana bölümdeyken Ana Sayfa'ya döner. Kişi düzenleme gibi ayrı ekranlardan önce ilgili bölüme dönülür.

## Hatırlatmalar

Hiç kayıt olmasa da alt menüden açılır. Bekleyenler tarih sırasıyla listelenir; zamanı geçenler ve bildirimi kurulmamış olanlar açıkça belirtilir. Tamamlananlar ayrı seçimle görünür. Bir satıra dokununca kişi profili açılır; dönüşte liste yenilenir.

**Hatırlatma için kişi seç** düğmesi kartvizit arşivini açar. Bir kişiyi açıp **Takip hatırlatması → Hatırlatma ekle** yoluyla takip oluşturun. Boş arşivde önce bir kart ekleyin. Ana sayfadaki “Tüm takipleri gör” bağlantısı da yeni Hatırlatmalar ekranına gider.

## Ayarlar ve yardım

Yedekleme/geri yükleme ve Hatırlatmalar bağlantıları; ilk kart ekleme, takip oluşturma, bildirim sorunları, izinler, QR paylaşımı ve telefon değiştirme hakkında açılır açıklamalar eklendi. Telefon izinleri işletim sisteminin Ayarlar uygulamasından yönetilir. Bu ekran yeni bir tema tercihi veya bulut eşitleme ayarı eklemez.

## Kontroller

- `flutter test`: 62 test başarılı.
- `flutter analyze`: sorun bulunmadı.

Yeni ekran testleri boş durum yönlendirmesini, arşive geçişi, yardım açılmasını, takip sıralamasını, tamamlananların ayrılmasını, kişi profilinden dönüşte yenilemeyi ve 320 piksel genişlikte 1,5 kat yazı boyutunu kapsar. Dar ekranlarda ana sayfa rozetinin metin taşması giderildi.

Gerçek Android/iOS cihazında dokunmatik kullanım ve bildirim teslimi ayrıca denenmelidir. TestFlight yüklemesi yapılmadı.
