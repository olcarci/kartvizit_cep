# Fildişi ve zümrüt tasarım

Yüzey ve 3D düğmelerde altın parlama: 5 saniye duraklamanın ardından 1,8 saniyelik çapraz ışık geçişi. Dokunmaları engellemez; hareket azaltma açıkken, ekran devre dışıyken veya uygulama arka plandayken durur. Özel çizimle yalnızca efekt katmanı yeniden boyanır. Mevcut 63 test ve yeni animasyon/erişilebilirlik testi geçti.

Ana ekran ve ortak panel/tema bileşenleri açık fildişi, zümrüt ve altın renklerine geçirildi. Lora başlık ve Manrope metin yazı tipleri lisanslarıyla birlikte fonts klasörüne eklendi; ağdan yazı tipi indirilmez.

Dört işlem kutusu ve alt gezinme düğmeleri IvoryButton bileşenini kullanır. Fareyle üzerine gelme ve klavye odağında yükselme; basılı durumda çökme etkisi vardır. Geçiş 180 ms sürer. Hareket azaltma ayarında dönüşüm ve animasyon kapatılır. Devre dışı düğmeler işlem başlatmaz. Dar ekran/büyük yazıda işlem kutuları tek sütuna geçer; alt menü gerektiğinde yatay kaydırılır.

63 test geçti. Son menü etiketi düzeltmesinden sonra ilgili dört test ve ek görsel çıktı testi tekrar geçti. Flutter analizi sorunsuz, Android debug derlemesi başarılı. Gerçek cihazda dokunma hissi ayrıca denenmelidir. TestFlight yüklemesi yapılmadı.

Görsel kontrol: build/ivory-home.png. APK: build/app/outputs/flutter-apk/app-debug.apk.

## Tüm menülerde ortak görünüm

Fildişi yüzeyler, zümrüt metin ve altın sınırlar; açılır menü, alt panel, onay penceresi, tarih/saat seçici, filtreler, formlar, kartlar ve bildirim çubukları için ortak temada tanımlandı. Form düğmeleri aynı renk, yuvarlatma ve gölge düzenini kullanır. Galerinin fotoğraf zemini ve kırpma kontrolleri de palete uyarlandı. Kişi düzenleme ekranındaki açık renk açıklama yazısı okunabilir zümrüt renge çevrildi.

63 test tekrar geçti. Telefonun kendi fotoğraf/dosya seçicisi ve sistem paylaşım ekranı işletim sisteminin görünümünü kullanır. QR önizlemesindeki beyaz alan ve kişisel kartın kullanıcının seçtiği renkleri korunur.
