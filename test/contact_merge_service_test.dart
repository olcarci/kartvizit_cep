import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kartvizit_cep/services/contact_merge_service.dart';

void main() {
  test('Kartvizit bilgileri mevcut kişi korunarak birleştirilir', () {
    const existing = Contact(
      id: '42',
      displayName: 'Ali Şahin',
      name: Name(first: 'Ali', last: 'Şahin'),
      phones: [Phone(number: '+90 539 636 13 41')],
      emails: [Email(address: 'eski@example.com')],
      organizations: [Organization(name: 'Eski Şirket')],
    );
    const scanned = Contact(
      name: Name(first: 'Ali', last: 'Şahin'),
      phones: [
        Phone(number: '05396361341'),
        Phone(number: '+90 352 970 09 93'),
      ],
      emails: [Email(address: 'ali.sahin@eremgroup.net')],
      addresses: [Address(street: 'Anbar Mah. Melikgazi / Kayseri')],
      organizations: [
        Organization(name: 'Eren Group', jobTitle: 'Satış Temsilcisi'),
      ],
      websites: [Website(url: 'https://eremgroup.net')],
    );

    final merged = mergeContactKeepingExisting(existing, scanned);

    expect(merged.id, '42');
    expect(merged.displayName, 'Ali Şahin');
    expect(merged.phones, hasLength(2));
    expect(merged.emails.map((email) => email.address), containsAll([
      'eski@example.com',
      'ali.sahin@eremgroup.net',
    ]));
    expect(merged.addresses.single.street, contains('Kayseri'));
    expect(merged.organizations.single.name, 'Eski Şirket');
    expect(merged.organizations.single.jobTitle, 'Satış Temsilcisi');
    expect(merged.websites.single.url, 'https://eremgroup.net');
  });

  test('Mevcut adres varsa kartvizit adresi üzerine yazılmaz', () {
    const existing = Contact(
      id: '7',
      displayName: 'Ayşe Kaya',
      addresses: [Address(street: 'Mevcut adres')],
    );
    const scanned = Contact(
      addresses: [Address(street: 'Kartvizit adresi')],
    );

    final merged = mergeContactKeepingExisting(existing, scanned);

    expect(merged.addresses.single.street, 'Mevcut adres');
  });
}
