# Geliştirme paketi 1 — Kişileri düzenleme

## Kullanım

- Ana sayfadaki genel bakış bölümünde kartvizit, favori ve etiket sayıları; favori kişiler ve son eklenen üç kart görünür.
- Kartvizit Galerisi'nden bir karta dokunarak kişi profilini açın.
- Profildeki yıldızla favoriye ekleyin veya favorilerden çıkarın.
- “Etiket ve not ekle / düzenle” ile virgülle ayrılmış etiketler ve görüşme notları girin, “Kaydet” düğmesine basın. “Vazgeç” değişiklikleri kaydetmez.
- Galeride favori ve etiket filtreleri birlikte kullanılabilir. Arama kişi, şirket, unvan, telefon, e-posta, etiket ve notları kapsar; Türkçe karakter farklarını tolere eder.
- Profilde hızlı iletişim düğmelerini kullanın. İletişim bilgilerini değiştirmek veya rehbere aktarmak için “Bilgileri düzenle / rehbere kaydet” düğmesine basın.

## Veriler

Not, etiket ve favori bilgileri cihazdaki mevcut kartvizit arşivinde tutulur; telefon rehberine aktarılmaz. Eski kayıtlarda yeni alanlar boş/favori değil kabul edilir. İletişim bilgilerini güncellemek bu alanları silmez. Yeni paket veya sunucu bağımlılığı eklenmedi.

## Doğrulama

- Flutter testleri: 33 test başarılı.
- Eski kayıt uyumluluğu, diskten yeniden açma, etiket/not temizleme, favori değiştirme, profil akışı ve birleşik filtreler test edildi.
- Gerçek Android/iOS cihazında görsel ve dokunmatik kullanım kontrolü henüz yapılmadı.

## Sonraki paket

Takip hatırlatmaları, gelişmiş filtreleme/sıralama, yedekleme/geri yükleme ve VCF/CSV paylaşımı.
