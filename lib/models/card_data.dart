enum PhoneKind { mobile, work, other }

class CardData {
  String name, company, title, email, website, address;
  List<String> phones;
  Map<String, PhoneKind> phoneKinds;
  CardData({this.name = '', this.company = '', this.title = '',
    this.email = '', this.website = '', this.address = '', List<String>? phones, Map<String, PhoneKind>? phoneKinds})
      : phones = phones ?? [], phoneKinds = phoneKinds ?? {};

  factory CardData.fromJson(Map<String, dynamic> json) {
    final phones = (json['phones'] as List<dynamic>? ?? const [])
        .map((value) => value.toString())
        .toList();
    final storedKinds = (json['phoneKinds'] as Map<String, dynamic>? ?? const {});
    final kinds = <String, PhoneKind>{};
    for (final phone in phones) {
      final name = storedKinds[phone]?.toString();
      final matchingKinds = PhoneKind.values.where((kind) => kind.name == name);
      kinds[phone] = matchingKinds.isEmpty ? PhoneKind.other : matchingKinds.first;
    }
    return CardData(
      name: json['name']?.toString() ?? '',
      company: json['company']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      website: json['website']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      phones: phones,
      phoneKinds: kinds,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'company': company,
    'title': title,
    'email': email,
    'website': website,
    'address': address,
    'phones': phones,
    'phoneKinds': {for (final entry in phoneKinds.entries) entry.key: entry.value.name},
  };

  String phoneType(String phone) => switch (phoneKinds[phone]) {
    PhoneKind.mobile => 'CELL',
    PhoneKind.work => 'WORK',
    _ => 'VOICE',
  };

  // Escape separators so scanned text cannot add unintended vCard fields.
  static String escape(String s) => s.replaceAll('\\', '\\\\')
      .replaceAll('\r', '').replaceAll('\n', r'\n')
      .replaceAll(';', r'\;').replaceAll(',', r'\,');
  String toVCard() => [
    'BEGIN:VCARD', 'VERSION:3.0',
    'N:;${escape(name.isEmpty ? company : name)};;;',
    'FN:${escape(name.isEmpty ? company : name)}',
    if (company.isNotEmpty) 'ORG:${escape(company)}',
    if (title.isNotEmpty) 'TITLE:${escape(title)}',
    for (final phone in phones) 'TEL;TYPE=${phoneType(phone)}:${escape(phone)}',
    if (email.isNotEmpty) 'EMAIL;TYPE=WORK:${escape(email)}',
    if (website.isNotEmpty) 'URL:${escape(website)}',
    if (address.isNotEmpty) 'ADR;TYPE=WORK:;;${escape(address)};;;;',
    'END:VCARD', '',
  ].join('\r\n');
}
