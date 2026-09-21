import 'package:flutter_test/flutter_test.dart';
import 'package:kartvizit_cep/services/contact_links.dart';

void main() {
  test('Telefon doğrulanır ve TR numarası normalize edilir', () {
    expect(ContactLinks.phone('0530 108 25 10'), '+905301082510');
    expect(ContactLinks.phone(''), isNull);
    expect(ContactLinks.phone('123'), isNull);
    expect(ContactLinks.phone('+905301082510;123'), isNull);
  });
  test('WhatsApp uluslararası rakamlardan bağlantı oluşturur', () {
    expect(ContactLinks.whatsapp('+905301082510').toString(), 'https://wa.me/905301082510');
  });
  test('Web yalnızca http ve https açar', () {
    expect(ContactLinks.website('www.example.com')?.scheme, 'https');
    expect(ContactLinks.website('https://example.com/path?a=1')?.host, 'example.com');
    expect(ContactLinks.website('javascript://example.com'), isNull);
    expect(ContactLinks.website('https://user@example.com'), isNull);
    expect(ContactLinks.website(''), isNull);
  });
  test('E-posta alıcısı güvenli şekilde kodlanır', () {
    expect(ContactLinks.email('eren@example.com')?.path, 'eren@example.com');
    expect(ContactLinks.email('eren@example.com?bcc=other@example.com'), isNull);
    expect(ContactLinks.email('gecersiz'), isNull);
  });
  test('Haritada Türkçe adres sorgusu korunur', () {
    const address = 'Şirinoğlu & Gül Apt. No:5 Sivas';
    expect(ContactLinks.map(address, apple: true).queryParameters['q'], address);
    expect(ContactLinks.map(address, apple: false).queryParameters['query'], address);
  });
}
