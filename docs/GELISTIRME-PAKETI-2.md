# Geliştirme paketi 2 — Takip, yedekleme ve paylaşım

## Deneme

Yeni Android/iOS eklentileri eklendiği için hot reload yeterli değildir. Çalışan uygulamayı durdurun; proje kökünde `flutter pub get` ve `flutter run` çalıştırın.

### Hatırlatmalar

1. Kartvizit Galerisi'nden bir kişi profili açın, “Hatırlatma ekle” düğmesine basın.
2. Yapılacak işi ve gelecekteki tarih/saati seçin. İlk kayıtta telefon bildirim izni ister.
3. İzin verilirse bildirim planlanır. İzin reddedilirse takip kaydı korunur; bildirim kurulmadığı açıklanır.
4. “Tamamlandı” veya “Hatırlatmayı kaldır” bekleyen bildirimi iptal eder. Yeni tarih kaydetmek eskisini değiştirir. Kart silmek de bildirimi iptal eder.
5. Ana sayfada takip bekleyenler tarih sırasıyla görünür. Bildirime dokunmak ilgili kişi profilini açar.

Kişi başına bir takip tutulur. En fazla 60 bildirim planlanır. Tarih/saat cihazın yerel saatinden sabit bir zamana dönüştürülür; başka saat dilimine geçildiğinde gösterilen yerel saat değişebilir. Android'de yaklaşık zamanlı bildirim kullanılır: pil tasarrufu ve üretici kısıtları gecikmeye neden olabilir. İzin ayarları sonradan kapatılırsa uygulama bildirim gösteremez.

### Gelişmiş filtreleme

Galeride “Filtrele ve sırala”: şirket, eklenme tarihi aralığı, takip bekleyen/zamanı geçen/tamamlanan hatırlatma durumu; en yeni, en eski, ad ve şirket sıralaması. Mevcut favori ve etiket filtreleriyle birlikte çalışır. “Sıfırla” bu penceredeki filtreleri ve sıralamayı sıfırlar.

### Yedekleme

Ana sayfanın sağ üstündeki yedekleme simgesini kullanın.

- “Yedek oluştur ve kaydet”: Fotoğraf, kişi bilgileri, OCR metni, not, etiket, favori ve hatırlatma verilerini tek JSON dosyasına yazar. Telefonun dosya kaydetme ekranından konum seçilir.
- Yedek şifreli değildir; notlar dahil kişisel bilgiler içerir. Kullanıcıya bu kapsam ekranda açıklanır.
- Sınırlar: toplam 64 MB, en fazla 2000 kart ve fotoğraf başına 12 MB. Eksik fotoğraf varsa devam etmeden önce kullanıcıya bildirilir; metin bilgileri korunur.
- “Dosyadan geri yükle”: Dosya önce doğrulanır, eklenecek ve atlanacak kayıt sayıları gösterilir, ardından kullanıcı onayıyla birleştirilir.
- Aynı kayıt kimliği zaten mevcutsa mevcut sürümü korunur. Başka kimliklerle ayrı ayrı taranmış aynı kişiler otomatik birleştirilmez.
- Geri yükleme kart silmez ve mevcut notları ezmez. Hatırlatma bilgileri taşınır; yeni cihazda bildirimleri kişi profilinden yeniden kaydetmek gerekir.

### Paylaşım ve dışa aktarma

Kişi profilinin paylaşım simgesi tek kartı; galeride “Dışa aktar” mevcut filtreye uyan kartları açar. Bu ekranda kart seçimi daraltılabilir.

- VCF: Rehbere aktarılabilir kişi bilgileri. Özel not, etiket, hatırlatma ve fotoğraf eklenmez.
- CSV: UTF-8 BOM ve standart virgül ayırıcı kullanır. Türkçe Excel ayarlarında gerekirse **Veri → Metinden/CSV'den** yoluyla UTF-8/virgül seçilerek açılır. Formül olarak çalışabilecek değerler metne çevrilir.
- CSV'de özel not ve etiketler varsayılan olarak kapalıdır; kullanıcı açıkça seçebilir.
- “Dosyaya kaydet” konum seçtirir. “Paylaş” sistem paylaşım menüsünü açar; uygulama kendiliğinden kimseye mesaj göndermez.
- Paylaşım için oluşturulan geçici dosyalar, alıcı okuyabilsin diye hemen silinmez; bir sonraki paylaşımda bir günden eski olanlar temizlenir.

## Doğrulama

- `flutter test`: 48 test geçti.
- `flutter analyze`: sorun yok.
- `flutter build apk --debug`: başarılı. Android deneme APK'sı: `build/app/outputs/flutter-apk/app-debug.apk` (22.09.2026).
- Testler fotoğraflı yedek taşıma, tekrar geri yükleme, bozuk dosyayı reddetme, güvenli dosya yolları, eşzamanlı arşiv güncellemeleri, CSV/VCF kaçışları ve Türkçe sıralamayı kapsar.
- Bildirim izin reddi, planlama hatası, 60 bildirim sınırı, değiştirme/tamamlama/silme, disk hatası ve yarım kalan işlemi açılışta düzeltme test edildi.
- Gerçek cihazda bildirim teslimi, dosya seçici, paylaşım menüsü ve iOS derlemesi ayrıca doğrulanmalıdır. Windows ortamında iOS/TestFlight derlemesi veya yüklemesi yapılmadı.

## Teknik kaynaklar

- [Yerel bildirim paketi ve platform kurulumu](https://pub.dev/packages/flutter_local_notifications)
- [Dosya seçme/kaydetme API'si](https://pub.dev/packages/file_picker)
- [Sistem paylaşım menüsü](https://pub.dev/packages/share_plus)

Yeni bağımlılıklar `pubspec.yaml` ve `pubspec.lock` içinde kaydedildi. Android bildirim izinleri, açılış alıcıları, bildirim simgesi ve desugaring; iOS bildirim delegesi eklendi. Arşiv yazıları sıraya alınır ve geçici dosya tamamlandıktan sonra ana dosyayla değiştirilir. Bozuk arşivler boş kabul edilip üzerine yazılmaz.
