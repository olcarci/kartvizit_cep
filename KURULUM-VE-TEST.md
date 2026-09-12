# Kartvizit Cep v1.0.5 — İlk geliştirme sürümü

## Windows'ta uygulama
1. Çalışan `flutter run` terminalinde q tuşuna basın.
2. Mevcut C:\Users\User\kartvizit_cep klasörünüzün bir yedeğini alın.
3. ZIP içindeki kartvizit_cep klasörünün içeriğini mevcut proje klasörüne kopyalayın; dosyaları değiştirin. İç içe kartvizit_cep klasörü oluşturmayın.
4. VS Code terminalinde:

```powershell
cd C:\Users\User\kartvizit_cep
flutter pub get
flutter analyze
flutter test
flutter run -d emulator-5554
```

Her komut başarıyla bittiğinde sonraki komuta geçin. Hata durumunda çıktıyı paylaşın.
Eski pubspec.lock bilerek pakete konulmadı: flutter pub get yeni bağımlılıkları çözüp mevcut kilit dosyanızı günceller. Bu başarılı dosyayı sonraki ZIP/commit içine dahil edin.

## Emülatörde gerçek OCR testi
Bilgisayarınızdaki net bir kartvizit JPG/PNG dosyasını emülatör penceresine sürükleyin. Uygulamada Galeriden seç ile açın; sistem seçicisinde gerekirse Dosyalar/Downloads bölümüne geçin. Emülatörün sanal kamerası gerçek kartvizit göstermez; kamerayı gerçek Android telefonda ayrıca test edin.
1. Telefon, e-posta ve Türkçe isim içeren kartviziti okuyun.
2. Yanlış veya boş alanları düzeltin. Birden fazla telefon için her satıra bir numara yazın.
3. Rehbere kaydet deyip rehber izni verin. Başarı ekranından Rehberde göster ile doğrulayın.
4. Aynı kartı yeniden tarayın: mükerrer uyarısı beklenir. Vazgeç yeni kayıt oluşturmaz.
5. Mevcut kişiyi aç, sistemin kişi düzenleme ekranını açar. Yeni taranan alanlar mevcut kişiye otomatik birleştirilmez; buradan elle düzenlenir. Birden fazla eşleşmede ilk kişi açılır.
6. Kamera/galeri seçiminden vazgeçme, boş fotoğraf ve rehber iznini reddetme durumlarını deneyin.
7. Büyük sistem yazı boyutunda ekranı kaydırarak bütün alanlara erişilebildiğini kontrol edin.

## Kapsam ve sınırlamalar
Kamera/galeri, cihaz üzerinde Latin metin OCR, düzenlenebilir alanlar, çoklu telefon, izinli rehber kaydı, telefon/e-posta mükerrer kontrolü ve kayıt sonrası kişi görüntüleme eklendi. Türkçe telefonlar 0/+90/0090 biçimlerinde eşleştirilir. İsim, şirket, unvan ve adres ayırma kurallara dayalı tahmindir; her tasarımda doğru sonuç garanti edilmez. İnternetsiz OCR cihaz testi yapılmalıdır. Kartvizit arşivi, bulut eşitleme ve otomatik birleştirme bu sürümde yoktur.

Fotoğraf uygulamanın geçici alanında kalabilir; kalıcı fotoğraf arşivi tutulmaz. Rehber kaydının Google/iCloud eşitlemesi telefonun kendi hesap ayarlarına bağlıdır. iOS sınırlı rehber izninde tüm rehberde mükerrer kontrolü mümkün olmadığından bu sürüm tam erişim ister.

## iPhone
Minimum iOS 15.5; Android minimum API 24. iOS izin metinleri, deployment target ve Podfile hazırlandı. macOS/Xcode ve CocoaPods kurulu ortamda flutter pub get, ardından flutter build ios --no-codesign ile derleme kontrolü yapılmalı; gerçek telefon için Apple imzalama ayarlanmalıdır. Mevcut Swift Package Manager proje yapısı korundu; CocoaPods bağımlılıkları için Podfile eklendi. iOS derleme ve cihaz testi henüz yapılmadı.

## v1.0.1 düzeltmesi
Kullanıcının v1.0.0 çalıştırmasında beş parser testi geçti. Widget testi, küçük test ekranında henüz oluşturulmamış elle giriş düğmesini ararken başarısız oldu. Teste scrollUntilVisible eklendi; iki unnecessary_underscores bildirimi giderildi. v1.0.1 testleri teslim ortamında çalıştırılamadı.

## Doğrulama durumu
Teslim ortamında Flutter, Dart, Android SDK ve Xcode yoktur. Flutter analyze / flutter test / APK / iOS derlemesi çalıştırılamadı. Parser ve ekran testleri eklendi fakat henüz çalıştırılmadı. XML/plist/YAML ve ZIP yapısı kontrol edildi. Hazır APK veya mağaza yayını değildir.

## Dosyalar
- lib/main.dart: ana ekran, fotoğraf seçimi/OCR, kişi kontrol formu, izin/kayıt/mükerrer akışı.
- lib/models/card_data.dart: düzenlenen kişi verisi ve güvenli vCard alan kaçışları.
- lib/services/card_parser.dart: OCR satırlarından alan çıkarma ve telefon normalizasyonu.
- pubspec.yaml: sabit doğrudan paket sürümleri.
- android/app/src/main/AndroidManifest.xml: rehber izinleri ve uygulama adı.
- android/app/build.gradle.kts: minimum Android sürümü; çalışan NDK seçimi korundu.
- ios/Runner/Info.plist, ios/Runner.xcodeproj/project.pbxproj, ios/Flutter/AppFrameworkInfo.plist, ios/Podfile: izin ve minimum iOS ayarları.
- test/: parser ve temel gezinme testleri.

Paket belgeleri:
https://pub.dev/packages/image_picker/versions/1.2.3
https://pub.dev/packages/google_mlkit_text_recognition/versions/0.17.1
https://pub.dev/packages/flutter_contacts/versions/2.5.0


## v1.0.2 — Kartvizit ayrıştırma ve telefon biçimi
- Makine Müh. Nihat ... gibi aynı satırdaki unvan ve isim ayrılır.
- Yazılım şirketleri, satış müdürü gibi görevler ve harf aralıklı logo metinleri tanınır.
- Marka ve sektör ayrı satırlarda gelirse, önceki satır tek kelimelik marka olduğunda birleştirilir.
- Apt., kat, daire gibi adres satırları korunur.
- TR yerel telefonlar tarama ve kayıt sırasında +90 biçimine çevrilir; açık yabancı ülke kodları korunur.
- Bu kurallar eksik OCR harflerini geri getirmez. Şirket ve kişi adı hâlâ kullanıcı kontrolü ister.

Kullanıcının emülatör testinde önceki sürümün OCR, rehbere kayıt ve mükerrer uyarısı doğrulandı.
Bu sürümde üç yeni regresyon testi eklendi (toplam sekiz parser testi ve bir widget testi).
Kart örneği fotoğraftan elle yazılmış test girdisidir; gerçek ML Kit çıktısı veya OCR başarı ölçümü değildir.
Flutter SDK teslim ortamında bulunmadığından v1.0.2 analyze/test/derleme çalıştırılmadı.

Güncellemeden sonra flutter pub get, flutter analyze, flutter test ve flutter run -d emulator-5554 komutlarını sırayla çalıştırın.
Kendi kartvizitinizi yeniden tarayın; ad, unvan, şirket, iki adres satırı ve +90 telefonları kontrol edin.


## v1.0.3 — Gerçek OCR çıktısı ve ayrı telefon alanları
Gönderilen ekranda soyadın başındaki O harfi 0 olarak okunmuş. Eski isim filtresi rakam içerdiğinden adı reddediyordu. Harflerden oluşan isim sözcüğü içindeki sıfır artık O olarak düzeltilir. Ham OCR metni değiştirilmeden gösterilir; kişi adı kayıt öncesinde kontrol edilmelidir.

Cep telefonu, Sabit / iş telefonu ve Diğer telefonlar ayrı alanlardır. Her alana birden fazla numara satır satır girilebilir. Aynı numaranın birden fazla alana yazılması engellenir. Türkçe 05/+905 numaraları cep, 02/03/+902/+903 numaraları iş olarak ayrılır; GSM/cep gibi açık metin etiketleri de değerlendirilir. Yabancı numaranın türü bilinmiyorsa Diğer alanına gelir. Alanlar elle düzeltilebilir. Rehbere CELL, WORK veya VOICE türleri ile aktarılır.

Bu kartın OCR çıktısında logo yalnızca İRVE ve başka ürün markaları olarak okunmuştur; şirket adı bilinçli olarak tahmin edilmez. Şirket alanını Zirve Doğalgaz olarak elle doldurabilirsiniz. Gerçek isim/sabit/cep regresyon testi ve tür aktarım kontrolleri eklendi.

Doğrulama: XML/plist/YAML ve ZIP yapısı kontrol edildi. Flutter analyze, flutter test ve cihaz derlemesi bu ortamda çalıştırılamadı. Kullanıcı ortamında yeniden çalıştırılmalıdır. Eski rehber kayıtları otomatik değiştirilmez; yeni taramada mükerrer uyarısı alınabilir.


## v1.0.4 — Analiz bildirimi düzeltmesi
card_parser.dart içindeki üç if/else gövdesine süslü parantez eklendi. İşlev değişikliği yoktur. v1.0.3 kullanıcı analizinde üç info bildirimi görülmüş, derleme hatası görülmemiştir. Bu sürümde Flutter analyze/test yerel olarak çalıştırılamadı.


## v1.0.5 — Widget testi kaydırma hedefi
Kullanıcı ortamında v1.0.4 analyze temiz ve 11 parser testi başarılı. Widget testi formda birden fazla Scrollable bulduğu için başarısız oluyordu. Tüm scrollUntilVisible çağrılarında aktif ListView altındaki dış Scrollable açıkça seçildi. Cep ve sabit alanları ayrı ayrı görünür duruma getirildikten sonra doğrulanıyor. Uygulama işlevleri değişmedi. Test teslim ortamında Flutter SDK olmadığı için çalıştırılamadı. Önce flutter test, başarılıysa flutter run -d emulator-5554 ile devam edin.
