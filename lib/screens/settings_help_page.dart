import 'package:flutter/material.dart';

class SettingsHelpPage extends StatelessWidget {
  final VoidCallback onBackups;
  final VoidCallback onReminders;
  const SettingsHelpPage({
    super.key,
    required this.onBackups,
    required this.onReminders,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ayarlar ve yardım')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text('Yedekleme ve geri yükleme'),
            subtitle: const Text(
              'Kartlarınızı dosyaya kaydedin veya yedekten geri alın.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: onBackups,
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Hatırlatmalar'),
            subtitle: const Text(
              'Bekleyen ve tamamlanan takiplerinizi görüntüleyin.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: onReminders,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Kısa kullanım rehberi',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const ExpansionTile(
          title: Text('İlk kartvizitimi nasıl eklerim?'),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Ana Sayfa → Kartvizit tara ile kamerayı açın veya Fotoğraflardan seç ile mevcut fotoğrafı kullanın. Okunan bilgileri kontrol edin. Bilgileri elle gir seçeneği de bulunur. Kartvizitler bölümünde kayıtlarınıza ulaşabilirsiniz.',
              ),
            ),
          ],
        ),
        const ExpansionTile(
          title: Text('Hatırlatma nasıl eklenir?'),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Kartvizitler → bir kişi → Takip hatırlatması → Hatırlatma ekle. Başlığı, tarihi ve saati seçip kaydedin. Takipler alt menüdeki Hatırlatmalar bölümünde görünür. İzin verilmezse takip kaydı saklanır ancak bildirim gösterilmez.',
              ),
            ),
          ],
        ),
        const ExpansionTile(
          title: Text('Bildirim gelmiyorsa ne yapmalıyım?'),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Telefonun Ayarlar bölümünde Kartvizit Cep bildirim iznini kontrol edin. Sonra kişi profilinden hatırlatmayı yeniden kaydedin. Pil tasarrufu bildirimi geciktirebilir. Zamanı geçen takipler Hatırlatmalar ekranında kalır.',
              ),
            ),
          ],
        ),
        const ExpansionTile(
          title: Text('Kamera, fotoğraf ve rehber izinleri'),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Kamera tarama için, fotoğraf erişimi görsel seçmek için, rehber erişimi kişi kaydetme ve birleştirme için kullanılır. İzinleri telefonun Ayarlar bölümünden yönetebilirsiniz. Arşive kayıt ile telefon rehberine kayıt ayrı işlemlerdir.',
              ),
            ),
          ],
        ),
        const ExpansionTile(
          title: Text('Kartımı ve QR kodumu nasıl paylaşırım?'),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Alt menüden Kartım bölümünü açın, bilgilerinizi oluşturun ve paylaşma seçeneğini kullanın. QR iletişim bilgilerinizi taşır. Eski paylaşımlar bilgilerinizi değiştirdiğinizde otomatik güncellenmez.',
              ),
            ),
          ],
        ),
        const ExpansionTile(
          title: Text('Telefon değiştirirken verilerim nasıl taşınır?'),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Yedekleme ve geri yükleme bölümünden dosya oluşturun. Dosyayı yeni cihaza aktararak geri yükleyin. Yedek fotoğraf ve özel notları içerir; şifreli değildir. Otomatik bulut eşitleme yoktur. Yeni cihazda hatırlatmaları yeniden kaydedin.',
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
