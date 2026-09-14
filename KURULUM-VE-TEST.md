# Kartvizit Cep v1.3.3 — Şirket temizleme ve ad-soyad ayrımı

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
Bilgisayarınızdaki net bir kartvizit JPG/PNG dosyasını emülatör penceresine sürükleyin. Uygulamada Fotoğraflardan seç ile açın; sistem seçicisinde gerekirse Dosyalar/Downloads bölümüne geçin. Emülatörün sanal kamerası gerçek kartvizit göstermez; kamerayı gerçek Android telefonda ayrıca test edin.
1. Telefon, e-posta ve Türkçe isim içeren kartviziti okuyun.
2. Yanlış veya boş alanları düzeltin. Birden fazla telefon için her satıra bir numara yazın.
3. Rehbere kaydet deyip rehber izni verin. Başarı ekranından Rehberde göster ile doğrulayın.
4. Aynı kartı yeniden tarayın: mükerrer uyarısı beklenir. Vazgeç yeni kayıt oluşturmaz.
5. Mükerrer uyarısında `Bilgileri mevcut kişiye ekle` seçeneğini kullanın. Mevcut ad ve dolu alanlar korunur; kartvizitteki eksik telefon, e-posta, adres, şirket, unvan ve web sitesi eklenir. Ardından sistemin kişi düzenleme ekranı açılır. `Mevcut kişiyi aç` değişiklik yapmadan kişiyi açar; `Ayrı kayıt oluştur` yeni kişi oluşturur. Birden fazla eşleşmede ilk kişi kullanılır.
6. Kamera/galeri seçiminden vazgeçme, boş fotoğraf ve rehber iznini reddetme durumlarını deneyin.
7. Büyük sistem yazı boyutunda ekranı kaydırarak bütün alanlara erişilebildiğini kontrol edin.

## Kapsam ve sınırlamalar
Kamera/telefon fotoğrafları, cihaz üzerinde Latin metin OCR, uygulama içi kartvizit galerisi, düzenlenebilir alanlar, çoklu telefon, izinli rehber kaydı, telefon/e-posta mükerrer kontrolü, mevcut kişiye eksik kartvizit bilgilerini ekleme ve kayıt sonrası kişi görüntüleme bulunur. Türkçe telefonlar 0/+90/0090 biçimlerinde eşleştirilir. İsim, şirket, unvan ve adres ayırma kurallara dayalı tahmindir; her tasarımda doğru sonuç garanti edilmez. İnternetsiz OCR cihaz testi yapılmalıdır. Bulut eşitleme yoktur.

Taranan/kırpılan kartvizit fotoğrafı uygulamanın özel belge alanındaki kalıcı galeriye kopyalanır. Rehber kaydının Google/iCloud eşitlemesi telefonun kendi hesap ayarlarına bağlıdır. iOS sınırlı rehber izninde tüm rehberde mükerrer kontrolü mümkün olmadığından bu sürüm tam erişim ister.

## iPhone
Minimum iOS 15.5; Android minimum API 24. iOS izin metinleri, deployment target ve Podfile hazırlandı. macOS/Xcode ve CocoaPods kurulu ortamda flutter pub get, ardından flutter build ios --no-codesign ile derleme kontrolü yapılmalı; gerçek telefon için Apple imzalama ayarlanmalıdır. Mevcut Swift Package Manager proje yapısı korundu; CocoaPods bağımlılıkları için Podfile eklendi. iOS derleme ve cihaz testi henüz yapılmadı.

## v1.0.1 düzeltmesi
Kullanıcının v1.0.0 çalıştırmasında beş parser testi geçti. Widget testi, küçük test ekranında henüz oluşturulmamış elle giriş düğmesini ararken başarısız oldu. Teste scrollUntilVisible eklendi; iki unnecessary_underscores bildirimi giderildi. v1.0.1 testleri teslim ortamında çalıştırılamadı.

## Doğrulama durumu
Teslim ortamında Flutter, Dart, Android SDK ve Xcode yoktur. Flutter analyze / flutter test / APK / iOS derlemesi çalıştırılamadı. Parser, galeri servisi, arama ve ekran testleri eklendi fakat henüz çalıştırılmadı. XML/plist/YAML ve ZIP yapısı kontrol edildi. Hazır APK veya mağaza yayını değildir.

## Dosyalar
- lib/main.dart: ana ekran, fotoğraf seçimi/OCR, kartvizit galerisi, arama, kişi kontrol formu, izin/kayıt/mükerrer akışı.
- lib/models/card_data.dart: düzenlenen kişi verisi ve güvenli vCard alan kaçışları.
- lib/models/archived_card.dart: galeri kaydının fotoğraf, tarih ve kişi bilgileri.
- lib/services/card_parser.dart: OCR satırlarından alan çıkarma ve telefon normalizasyonu.
- lib/services/card_archive_service.dart: kartvizit fotoğraflarını ve bilgilerini cihazda kaydetme, güncelleme ve silme.
- pubspec.yaml: sabit doğrudan paket sürümleri.
- android/app/src/main/AndroidManifest.xml: rehber izinleri ve uygulama adı.
- android/app/build.gradle.kts: minimum Android sürümü; çalışan NDK seçimi korundu.
- ios/Runner/Info.plist, ios/Runner.xcodeproj/project.pbxproj, ios/Flutter/AppFrameworkInfo.plist, ios/Podfile: izin ve minimum iOS ayarları.
- test/: parser ve temel gezinme testleri.

Paket belgeleri:
https://pub.dev/packages/image_picker/versions/1.2.3
https://pub.dev/packages/google_mlkit_text_recognition/versions/0.17.1
https://pub.dev/packages/flutter_contacts/versions/2.5.0
https://pub.dev/packages/path_provider/versions/2.1.6


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


## v1.1.0 — Okumadan önce kırpma
Kamera ve galeriden gelen fotoğraf için Kartviziti kırp ekranı açılır. Köşeleri kartvizitin kenarlarına sürükleyin, tüm metni çerçevede tutun ve Kırp ve oku düğmesine basın. Çerçeve serbest oranlıdır; fotoğraf yakınlaştırılabilir. Kırpmadan devam et orijinali okur; geri düğmesi taramayı iptal eder. Android kayıp fotoğraf kurtarma akışı da kırpma ekranına gelir.

Kırpılan görüntü kişi kontrol ekranında gösterilir. Geçici kırpma dosyası bu ekran kapanınca silinir; kaynak fotoğraf değiştirilmez. Desteklenen fotoğraflar kırpma öncesinde PNG biçimine dönüştürülür. Açılamayan biçimlerde kırpmadan devam et seçeneği sunulur. Perspektif düzeltmesi ve eksik logo harflerini tamamlama bu sürümde yoktur.

Yeni bağımlılık: crop_your_image 2.0.0 (https://pub.dev/packages/crop_your_image/versions/2.0.0). Ek native kırpma izni veya iOS URL şeması gerekmez.

Doğrulama: kırpma ekranının fotoğraf yükleme hatasında orijinalle devam etmesini kontrol eden widget testi eklendi. Flutter SDK bu ortamda bulunmadığından analyze, test ve Android/iOS derlemesi çalıştırılmadı. Kullanıcı bilgisayarında yukarıdaki komutları sırayla çalıştırın. Kendi kartvizitinizde masa arka planını dışarıda bırakıp yeniden okuyun; ad, telefonlar ve şirketi kontrol edin. Kamera akışını, galeriyi, kırpmadan devam etmeyi ve geri ile iptali deneyin. iPhone fotoğraf biçimleri ve gerçek kamera akışı cihazda ayrıca doğrulanmalıdır.

Yerel kontroller başarılı olduğunda GitHub Desktop ile değişiklikleri (güncellenen pubspec.lock dahil) commit edip Push origin yapın. Codemagic sonraki derlemede yeni sürümü alacaktır. Apple Developer onayı geldikten sonra Release imzalama ve TestFlight ayarları tamamlanacaktır.


## v1.1.1 — Kırpma testi zaman aşımı düzeltmesi
Kullanıcı testinde diğer 12 test başarılı; yeni kırpma testi yükleme göstergesi animasyonu sürerken pumpAndSettle çağırdığı için zaman aşımına uğradı. Dosya okuma sonucu testin sanal zaman ortamında bekliyordu. Test artık kontrollü bir görüntü yükleyicisi kullanır: önce yükleme göstergesini doğrular, sonra hatayı tamamlar, hata ekranını ve kırpmadan devam sonucunu kontrol eder. Gerçek dosya okuma akışı aynı kalır. Keyfi bekleme ve gerçek disk bağımlılığı kaldırıldı.

Flutter SDK burada bulunmadığından testler çalıştırılamadı. Kullanıcı bilgisayarında flutter analyze ve flutter test çalıştırılmalıdır.


## v1.1.2 — Kırpma köşelerini tutma düzeltmesi
Fotoğraf kaydırma/yakınlaştırma kapatıldı. Kırpma alanına 24 piksel kenar boşluğu eklendi; başlangıç çerçevesi fotoğrafın yüzde 75 boyutunda ortalanır. Köşe tutamakları yeşil dolgu, beyaz kenar ve sürükleme simgesiyle görünür hâle getirildi. Çerçeve serbest oranlı ve hareketlidir. Köşeleri basılı tutup sürükleyin; ortadan sürüklemek çerçeveyi taşır.

Flutter SDK burada olmadığı için cihaz etkileşimi, analyze ve test çalıştırılamadı. Kullanıcı ortamında flutter pub get, flutter analyze, flutter test ve flutter run -d emulator-5554 ile doğrulayın.


## v1.1.3 — Mevcut kişi düzenlemesinden dönüş
Mükerrer uyarısında Mevcut kişiyi aç seçilince sistem rehber editörü açılır. Dönüşte artık oluşturma formu yerine Mevcut kişi ekranı gösterilir. Rehberde göster, Kişiyi tekrar düzenle ve Yeni kartvizit tara seçenekleri sunulur. Yeniden Rehbere kaydet düğmesi veya mükerrer döngüsü oluşmaz. Sistem editörü iptal edilse de yeni kişi oluşturulmaz; kaydetme sonucu platforma göre kesin olmayabileceği için bu ekran güncellemenin kaydedildiğini iddia etmez. Düzenleme ekranı açılamazsa form korunur ve hata mesajı gösterilir. Yeni kişi kayıt akışı aynı şekilde başarı ekranına gider.

Doğrulama: Flutter SDK bu ortamda olmadığı için analyze, test ve cihaz derlemesi çalıştırılamadı. Yerelde flutter pub get, flutter analyze, flutter test ve flutter run -d emulator-5554 çalıştırın. Aynı kartı tarayıp Mevcut kişiyi aç ile düzenleyin, Save ile dönün: tekrar kayıt düğmesi çıkmamalı. İptal ederek dönüşte de yeni kayıt olmamalı. Rehberde göster ve Kişiyi tekrar düzenle seçeneklerini kontrol edin. Yeni kartvizit tara ana ekrana dönmeli.


## v1.2.0 — Renkli arayüz
Ana ekranın tanıtım kartına mor, mavi ve turkuaz geçiş eklendi. Kamera mavi, galeri mor/pembe, elle giriş turuncu/kiremit, kırpma ve rehbere kayıt yeşil geçişli butonlarla gösterilir. Butonlar gölgeli, geniş ve büyük yazılıdır. Devre dışı butonlar gri görünür. Arka plan açık lavanta, form alanları beyaz ve odak kenarları mordur. Son kontrol kartı mint rengindedir. İşlevler korunmuştur.

Doğrulama: Flutter SDK burada olmadığı için analyze, test, ekran görüntüsü ve cihaz derlemesi çalıştırılamadı. Kullanıcı ortamında flutter pub get, flutter analyze, flutter test ve flutter run -d emulator-5554 ile doğrulayın. Ana ekran, kırpma ve formu kontrol edin.

## v1.2.1 — Yayın kimliği
Apple Developer ve App Store Connect üzerinde kaydedilen `com.olcarci.kartvizitcep` kimliği iOS Runner yapılandırmasına uygulandı. Android namespace ve applicationId de aynı kalıcı kimlikle eşleştirildi. RunnerTests kimliği `com.olcarci.kartvizitcep.RunnerTests` olarak güncellendi. Sürüm 1.2.1, derleme numarası 12 oldu.

Bu kimlik değişikliği nedeniyle Android, emülatörde eski geliştirme uygulamasından ayrı bir uygulama olarak görünebilir. Flutter SDK bu ortamda bulunmadığından analyze, test ve Android/iOS derlemesi çalıştırılamadı. Yerelde `flutter pub get`, `flutter analyze`, `flutter test` ve `flutter run -d emulator-5554` komutlarını çalıştırın. Başarılı sonuçtan sonra güncellenen `pubspec.lock` dahil değişiklikleri GitHub'a gönderin; Codemagic Release iOS derlemesinde bu Bundle ID'yi kullanmalıdır.

## v1.3.0 — Kartvizit Galerisi
Kamera veya telefon fotoğraflarından seçilen kartvizit, kırpılıp başarıyla okunduktan sonra uygulamanın özel belge alanına otomatik kaydedilir. Ana ekrandaki `Kartvizit Galerisi` düğmesi fotoğrafı, ad-soyadı, şirketi ve tarama tarihini gösterir. Kartın üzerine dokunulduğunda okunan bilgiler yeniden açılır. OCR'nin eksik bıraktığı şirket gibi alanlar düzeltilip `Galeri bilgilerini güncelle` ile yalnızca uygulama galerisine kaydedilebilir; bu işlem rehbere kişi eklemez. İstenirse ayrı `Rehbere kaydet` düğmesiyle iPhone rehberine eklenir. Çöp kutusu yalnızca uygulama galerisindeki kartı siler, telefon rehberindeki kişiyi etkilemez.

Arşivin üstündeki arama alanı ad-soyad ve şirket adına göre anlık filtreleme yapar. Türkçe karakterler arama sırasında sadeleştirildiğinden `ZİRVE`, `zirve` veya benzeri girişler eşleşir. Eski `Galeriden seç` düğmesi, telefonun Fotoğraflar uygulamasını açtığını netleştirmek için `Fotoğraflardan seç` olarak yeniden adlandırıldı.

Arşiv yalnızca uygulamanın cihaz içindeki özel klasöründe tutulur; bir sunucuya yüklenmez ve telefonun Fotoğraflar albümünde yeni kopya oluşturmaz. Uygulama kaldırılırsa arşiv de silinir. Bu sürümden önce taranan kartlar geriye dönük eklenmez; gerekirse Fotoğraflardan seç ile yeniden okutulmalıdır.

iOS `ITSAppUsesNonExemptEncryption=false` bilgisi eklendi; uygulama özel veya ihracat izni gerektiren şifreleme uygulamadığı için sonraki TestFlight yüklemelerinde eksik uyumluluk sorusunun yeniden çıkması önlenir. Sürüm 1.3.0, build 13'tür.

## v1.3.1 — Mevcut kişiyi kartvizit bilgileriyle güncelleme
Mükerrer telefon veya e-posta bulunduğunda `Bilgileri mevcut kişiye ekle` seçeneği gösterilir. Uygulama mevcut kişiyi gerekli rehber alanlarıyla birlikte yeniden okur ve dolu mevcut bilgileri silmeden kartvizitteki yeni telefonları, e-postaları ve web sitelerini ekler. Mevcut adres boşsa kartvizit adresini ekler. Şirket veya unvan alanlarından eksik olanı tamamlar. Güncellemeden sonra iPhone/Android kişi düzenleme ekranı açılarak sonuç kontrol edilebilir.

`Mevcut kişiyi aç` hiçbir otomatik değişiklik yapmaz. `Ayrı kayıt oluştur` kartvizit bilgileriyle ikinci bir kişi oluşturur. Rehberdeki fotoğraf, not, özel gün ve uygulamanın istemediği diğer alanlar okunup yazılmadığı için korunur. Sürüm 1.3.1, build 14'tür.

## v1.3.2 — Faktoring kartlarında alan ayrımı
Aralıklı okunabilen `FAKTO RİNG` ifadesi şirket göstergesi olarak tanınır. `Portföy Yetkilisi` unvan olarak ayrılır ve şube satırları kişi adı adayı sayılmaz. Böylece örnek kartta `ŞİRİNOĞLU FAKTO RİNG` şirket, `Eren Çevik` ad-soyad ve `Portföy Yetkilisi` unvan alanına yerleşir. Sürüm 1.3.2, build 15'tir.

## v1.3.3 — Logo harfi temizleme ve rehber adı ayrımı
Şirket adının başında logodan gelen, şirketin ilk harfini tekrarlayan tek harflik OCR artığı temizlenir. `FAKTO RİNG` yazımı `FAKTORİNG` olarak birleştirilir. Rehbere aktarımda kişi adının son kelimesi soyad, önceki kelimeleri ad alanına yazılır; örneğin `Eren Çevik`, Android/iOS rehberinde ad `Eren`, soyad `Çevik` olur. Sürüm 1.3.3, build 16'dır.
