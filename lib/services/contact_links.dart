import 'card_parser.dart';

class ContactLinks {
  static String? phone(String value) {
    if (!RegExp(r'^\+?[\d\s().-]+$').hasMatch(value.trim())) return null;
    final result = normalizePhone(value.trim());
    return RegExp(r'^\+?[0-9]{10,15}$').hasMatch(result) ? result : null;
  }

  static Uri? website(String value) {
    final text = value.trim();
    if (text.isEmpty || RegExp(r'\s').hasMatch(text)) return null;
    final uri = Uri.tryParse(text.contains('://') ? text : 'https://$text');
    if (uri == null || !['https', 'http'].contains(uri.scheme) ||
        uri.host.isEmpty || !uri.host.contains('.') || uri.userInfo.isNotEmpty) {
      return null;
    }
    return uri;
  }

  static Uri? email(String value) {
    final text = value.trim();
    if (!RegExp(r'^[^\s@?&#]+@[^\s@?&#]+\.[^\s@?&#]+$').hasMatch(text)) return null;
    return Uri(scheme: 'mailto', path: text);
  }

  static Uri whatsapp(String number) => Uri.https('wa.me', '/${number.replaceAll('+', '')}');
  static Uri map(String address, {required bool apple}) => apple
      ? Uri.https('maps.apple.com', '/', {'q': address.trim()})
      : Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': address.trim()});
}
