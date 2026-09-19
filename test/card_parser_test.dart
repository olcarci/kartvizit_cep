import 'package:flutter_test/flutter_test.dart';
import 'package:kartvizit_cep/models/card_data.dart';
import 'package:kartvizit_cep/services/card_parser.dart';

void main() {
  test('Gerçek OCR satırındaki sıfır isim alanını boş bırakmaz', () {
    final d = CardParser().parse('İRVE\nMakine Müh. Nihat 0LCARCIYÜZ\nÇarşıbaşı Mah. Nalbanlarbaşı Cad.\nSöylemezoğlu Apt. No:13 SİVAS\nTel & Fax: 0(346) 225 10 22\nGsm :0(542) 542 87 33\nzirve-dogalgaz@hotmail.com\nELA\nE.C.A. Yetkili Bayii');
    expect(d.name, 'Nihat OLCARCIYÜZ');
    expect(d.title, 'Makine Mühendisi');
    expect(d.company, isEmpty); // Unreadable logo must not be invented.
    expect(d.phoneKinds['+905425428733'], PhoneKind.mobile);
    expect(d.phoneKinds['+903462251022'], PhoneKind.work);
    expect(d.toVCard(), contains('TEL;TYPE=CELL:+905425428733'));
    expect(d.toVCard(), contains('TEL;TYPE=WORK:+903462251022'));
  });
  test('İsim onarımı rakamları genel olarak değiştirmez', () {
    expect(CardParser.repairName('Nihat 0LCARCIYÜZ'), 'Nihat OLCARCIYÜZ');
    expect(CardParser.repairName('0542 542 87 33'), '0542 542 87 33');
    expect(CardParser.repairName('Ali 2026'), 'Ali 2026');
  });
  test('Türü bilinmeyen numara cep veya sabit olarak tahmin edilmez', () {
    expect(inferPhoneKind('+441234567890'), PhoneKind.other);
    final d = CardData(name: 'Test Kişi', phones: ['+441234567890']);
    expect(d.toVCard(), contains('TEL;TYPE=VOICE:+441234567890'));
  });

  // Manually transcribed fixture; this does not test the OCR model itself.
  test('Aynı satırdaki unvan ve isim ayrılır; iki adres satırı korunur', () {
    final d = CardParser().parse('Z İ R V E\nD O Ğ A L G A Z\nMakine Müh. Nihat OLCARCIYÜZ\nÇarşıbaşı Mah. Nalbanlarbaşı Cad.\nSöylemezoğlu Apt. No:13 SİVAS\nTel & Fax: 0(346) 225 10 22\nGsm : 0(542) 542 87 33\nzirve-dogalgaz@hotmail.com\nE.C.A. Yetkili Bayii');
    expect(d.name, 'Nihat OLCARCIYÜZ');
    expect(d.title, 'Makine Mühendisi');
    expect(d.company, 'ZİRVE DOĞALGAZ');
    expect(d.phones, ['+903462251022', '+905425428733']);
    expect(d.address, contains('Söylemezoğlu Apt. No:13 SİVAS'));
    expect(d.email, 'zirve-dogalgaz@hotmail.com');
  });
  test('Yazılım şirketi ve satış unvanı tanınır', () {
    final d = CardParser().parse('Prizma Yazılım\nOlgun Berk Ayyıldız\nSatış Müdürü');
    expect(d.company, 'Prizma Yazılım');
    expect(d.name, 'Olgun Berk Ayyıldız');
    expect(d.title, 'Satış Müdürü');
  });
  test('Faktoring kartında şirket kişi ve portföy unvanı ayrılır', () {
    final d = CardParser().parse(
      'ŞİRİNOĞLU FAKTO RIN\n'
      'Eren Çevik\n'
      'Portföy Yetkilisi\n'
      'Sivas Şubesi\n'
      'Sularbaşı Mahallesi Kızılay Sokak Gül Apt. Altı No-5/D Sivas\n'
      'T: 0346 225 2035 F: 0346 225 2038\n'
      'M: 0530 108 25 10\n'
      'eren.cevik@sirinoglu.com\n'
      'www.sirinoglu.com',
    );
    expect(d.company, 'ŞİRİNOĞLU FAKTORİNG');
    expect(d.name, 'Eren Çevik');
    expect(d.title, 'Portföy Yetkilisi');
    expect(d.phoneKinds['+905301082510'], PhoneKind.mobile);
    expect(d.phoneKinds['+903462252035'], PhoneKind.work);
    expect(d.email, 'eren.cevik@sirinoglu.com');
    expect(d.website, 'www.sirinoglu.com');
  });
  test('Şirket adındaki logo harfi ve eksik G onarılır', () {
    expect(
      CardParser.repairCompany('S ŞİRİNOĞLU FAKTO RİNG'),
      'ŞİRİNOĞLU FAKTORİNG',
    );
    expect(
      CardParser.repairCompany('ŞİRİNOĞLU FAKTO RIN'),
      'ŞİRİNOĞLU FAKTORİNG',
    );
  });
  test('Açık yabancı ülke kodları Türkiye numarasına çevrilmez', () {
    expect(normalizePhone('+32 123 45 678'), '+3212345678');
    expect(normalizePhone('0049 30 12345678'), '+493012345678');
    expect(normalizePhone('0(542) 542 87 33'), '+905425428733');
  });

  test('Türkçe kartvizitten iletişim bilgileri ayrılır', () {
    final d = CardParser().parse('Zirve Doğalgaz\nNihat Olcarcıyüz\nMakine Mühendisi\nTel: 0532 123 45 67\ninfo@example.com\nwww.example.com\nAdres: Örnek Mah. No: 12 Ankara');
    expect(d.name, 'Nihat Olcarcıyüz');
    expect(d.company, 'Zirve Doğalgaz');
    expect(d.phones, ['+905321234567']);
    expect(d.email, 'info@example.com');
  });
  test('Yerel ve uluslararası TR telefonları aynı anahtarı verir', () {
    expect(phoneKey('0532 123 45 67'), phoneKey('+90 (532) 123-45-67'));
    expect(phoneKey('0090 532 123 45 67'), phoneKey('5321234567'));
    expect(phoneKey('+49 5321234567'), isNot(phoneKey('+90 5321234567')));
  });
  test('Vergi ve adres numaraları telefona dönüşmez', () {
    final d = CardParser().parse('Vergi No: 1234567890\nAdres: 1234567890 Sokak');
    expect(d.phones, isEmpty);
  });
  test('Tekrarlanan telefonlar ayıklanır', () {
    final d = CardParser().parse('0532 123 45 67\n+90 532 123 45 67');
    expect(d.phones.length, 1);
  });
  test('vCard metni yeni alan enjekte edemez', () {
    final card = CardData(name: 'Ali\nTEL:999', company: 'A;B').toVCard();
    expect(card, contains(r'A\;B'));
    expect(card, isNot(contains('\r\nTEL:999')));
  });
  test('Logoda tekrarlanan marka adı şirket olarak tanınır', () {
    final d = CardParser().parse(
      'Sivas Cadde\n'
      'Atasun Optik\n'
      'Atasun Optik\n'
      'Örtülüpınar Mahallesi İnönü Bulvarı\n'
      'No:25B Merkez/Sivas\n'
      'T +90 541 203 31 86\n'
      'E sivascadde@atasunoptik.com.tr',
    );
    expect(d.company, 'Atasun Optik');
  });
  test('vCard ad ve soyadı rehber alanlarına ayrı yazar', () {
    final card = CardData(name: 'Eren Çevik').toVCard();
    expect(card, contains('N:Çevik;Eren;;;'));
    expect(card, contains('FN:Eren Çevik'));
  });
}
