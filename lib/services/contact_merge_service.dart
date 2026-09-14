import 'package:flutter_contacts/flutter_contacts.dart';

String _phoneKey(String value) {
  var digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('0090')) digits = digits.substring(4);
  if (digits.startsWith('90') && digits.length == 12) digits = digits.substring(2);
  if (digits.startsWith('0') && digits.length == 11) digits = digits.substring(1);
  return digits;
}

String _textKey(String value) => value.trim().toLowerCase();

List<Phone> _mergePhones(List<Phone> existing, List<Phone> scanned) {
  final result = [...existing];
  final keys = existing.map((phone) => _phoneKey(phone.number)).toSet();
  for (final phone in scanned) {
    if (keys.add(_phoneKey(phone.number))) result.add(phone);
  }
  return result;
}

List<Email> _mergeEmails(List<Email> existing, List<Email> scanned) {
  final result = [...existing];
  final keys = existing.map((email) => _textKey(email.address)).toSet();
  for (final email in scanned) {
    if (keys.add(_textKey(email.address))) result.add(email);
  }
  return result;
}

List<Website> _mergeWebsites(List<Website> existing, List<Website> scanned) {
  final result = [...existing];
  final keys = existing.map((website) => _textKey(website.url)).toSet();
  for (final website in scanned) {
    if (keys.add(_textKey(website.url))) result.add(website);
  }
  return result;
}

bool _hasAddress(Address address) => [
  address.formatted,
  address.street,
  address.city,
  address.state,
  address.postalCode,
  address.country,
].any((value) => value?.trim().isNotEmpty == true);

List<Address> _mergeAddresses(
  List<Address> existing,
  List<Address> scanned,
) => existing.any(_hasAddress) ? existing : scanned;

List<Organization> _mergeOrganizations(
  List<Organization> existing,
  List<Organization> scanned,
) {
  if (scanned.isEmpty) return existing;
  if (existing.isEmpty) return scanned;

  final current = existing.first;
  final incoming = scanned.first;
  final merged = current.copyWith(
    name: current.name?.trim().isNotEmpty == true ? current.name : incoming.name,
    jobTitle: current.jobTitle?.trim().isNotEmpty == true
        ? current.jobTitle
        : incoming.jobTitle,
  );
  return [merged, ...existing.skip(1)];
}

/// Kartvizit verilerini mevcut rehber kaydına eklerken dolu alanları korur.
/// Telefon, e-posta ve web sitesi listelerine yalnızca yeni değerler eklenir.
Contact mergeContactKeepingExisting(Contact existing, Contact scanned) {
  final existingName = existing.displayName?.trim() ?? '';
  return existing.copyWith(
    name: existingName.isEmpty ? scanned.name : existing.name,
    phones: _mergePhones(existing.phones, scanned.phones),
    emails: _mergeEmails(existing.emails, scanned.emails),
    addresses: _mergeAddresses(existing.addresses, scanned.addresses),
    organizations: _mergeOrganizations(
      existing.organizations,
      scanned.organizations,
    ),
    websites: _mergeWebsites(existing.websites, scanned.websites),
  );
}
