# Geliştirme paketi 3

## Çift taraflı kartvizit

Arşivde kartın ayrıntısını açın, arka yüz ekleme düğmesinden kamera veya galeriyi seçin. Okunan bilgileri inceleyip kaydedin. Ön ve arka yüz arasında geçiş yapabilir, arka yüzü değiştirebilir veya kaldırabilirsiniz.

Arka yüz, mevcut dolu alanları koruyarak boş alanları tamamlar ve yeni telefonları ekler. Düzenleme ekranındaki açık değişiklikler kaydedilir. Yalnızca logo içeren, metinsiz arka yüz de saklanabilir. Arka yüzü kaldırmak, daha önce kişi bilgilerine eklenen değerleri silmez.

## Toplu tarama

Ana ekranda **Toplu kartvizit tara** ile galeriden en fazla 20 fotoğraf seçin. Her fotoğraf ayrı bir kart taslağıdır. Okuma sırayla yapılır; bir fotoğrafın hatası diğerlerini durdurmaz.

Taslakları inceleyebilir, düzenleyebilir, kırpıp yeniden okutabilir, atlayabilir ve tek tek kaydedebilirsiniz. Otomatik arşiv veya telefon rehberi kaydı yapılmaz. Okumayı durdurup aynı ekran içinde sürdürebilirsiniz. Kaydedilmemiş taslaklarla çıkışta onay istenir; kuyruk uygulama yeniden açıldığında devam etmez. Aynı taslağı tekrar kaydetmek ikinci bir kart oluşturmaz.

## Kişisel dijital kart ve QR

Ana ekranda **Kartvizitim ve QR kodum** bölümünden iletişim bilgilerinizi girin. İsteğe bağlı fotoğraf/logo ve üç renk teması kullanılabilir. Kartı PNG görseli olarak paylaşabilir veya kaydedebilir; kişi bilgilerini VCF olarak paylaşabilirsiniz. QR kod büyütülebilir.

QR doğrudan vCard kişi bilgilerini taşır ve sunucu gerektirmez. Fotoğraf/logo görsel kartta bulunur, QR veya VCF içine eklenmez. Bilgiler değiştiğinde yeni QR oluşur; önceden paylaşılan görseller kendiliğinden güncellenmez.

## Yedekleme

Sürüm 2 yedekler ön/arka fotoğrafları ve kişisel kartı/logoyu içerir. Sürüm 1 yedekler okunabilir; eski uygulama sürümleri yeni sürüm 2 yedeği okuyamaz. Geri yükleme mevcut kart kimliklerini atlar ve var olan kişisel kartın üzerine yazmaz. Kişisel kartın geri yüklenmesinde hata olursa sonuç ekranında ayrıca belirtilir.

## Teknik notlar ve doğrulama

- Düzenleme ekranı `lib/screens/edit_page.dart` dosyasına taşındı; mevcut akışlar korundu.
- QR üretimi `qr_flutter` ile yerel yapılır; ek yerel platform eklentisi gerektirmez.
- 59 otomatik test geçti. Son yazı tipi düzenlemesinden sonra ilgili üç ekran testi tekrar geçti. Ek görsel üretim testiyle örnek kartın Türkçe yazıları ve QR yerleşimi incelendi.
- `flutter analyze`: sorun bulunmadı.
- Android debug APK: `build/app/outputs/flutter-apk/app-debug.apk`.
- Gerçek cihazda kamera/OCR, başka bir telefonla QR okuma ve platform paylaşım akışları ayrıca denenmelidir; otomatik testlerde OCR okuyucusu taklit edilir.
- iOS derlemesi ve TestFlight yüklemesi yapılmadı. Bulut eşitleme bu pakete dahil değildir; hesap ve sunucu tercihi gerektirir.

Kaynak: [qr_flutter paket dokümantasyonu](https://pub.dev/packages/qr_flutter).
