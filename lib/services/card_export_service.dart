import 'dart:convert';
import 'dart:typed_data';

import '../models/archived_card.dart';

enum CardExportFormat { vcf, csv }

class CardExportService {
  static Uint8List export(
    List<ArchivedCard> cards,
    CardExportFormat format, {
    bool includeNotes = false,
  }) => Uint8List.fromList(
    utf8.encode(
      format == CardExportFormat.csv
          ? csv(cards, includeNotes: includeNotes)
          : cards.map((card) => _fold(card.data.toVCard())).join(),
    ),
  );

  static String csv(List<ArchivedCard> cards, {bool includeNotes = false}) {
    final rows = <List<String>>[
      [
        'Ad soyad',
        'Şirket',
        'Unvan',
        'Telefonlar',
        'E-posta',
        'Web sitesi',
        'Adres',
        if (includeNotes) ...['Etiketler', 'Notlar'],
      ],
      for (final card in cards)
        [
          card.data.name,
          card.data.company,
          card.data.title,
          card.data.phones.join(' | '),
          card.data.email,
          card.data.website,
          card.data.address,
          if (includeNotes) ...[card.tags.join(' | '), card.notes],
        ],
    ];
    return '\uFEFF${rows.map((row) => row.map(_cell).join(',')).join('\r\n')}\r\n';
  }

  static String _cell(String value) {
    final safe = RegExp(r'^[\s\x00-\x1f]*[=+@-]').hasMatch(value)
        ? "'$value"
        : value;
    return '"${safe.replaceAll('"', '""')}"';
  }

  static String _fold(String vcard) {
    final result = <String>[];
    for (final line in vcard.split('\r\n')) {
      var part = '';
      var bytes = 0;
      for (final rune in line.runes) {
        final char = String.fromCharCode(rune);
        final length = utf8.encode(char).length;
        if (bytes + length > 75) {
          result.add(part);
          part = ' ';
          bytes = 1;
        }
        part += char;
        bytes += length;
      }
      result.add(part);
    }
    return result.join('\r\n');
  }
}
