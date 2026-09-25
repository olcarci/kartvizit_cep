import '../models/card_data.dart';

/// Normalize TR national numbers; preserve explicit foreign country codes.
String normalizePhone(String input) {
  final value = input.trim();
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (value.startsWith('+')) return '+$digits';
  if (digits.startsWith('00')) return '+${digits.substring(2)}';
  if (digits.length == 11 && RegExp(r'^0[235]').hasMatch(digits)) {
    return '+90${digits.substring(1)}';
  }
  if (digits.length == 10 && RegExp(r'^[235]').hasMatch(digits)) return '+90$digits';
  if (digits.length == 12 && digits.startsWith('90')) return '+$digits';
  return value;
}

String phoneKey(String input) => normalizePhone(input).replaceAll(RegExp(r'\D'), '');

PhoneKind inferPhoneKind(String phone) {
  final key = phoneKey(phone);
  if (key.length == 12 && key.startsWith('905')) return PhoneKind.mobile;
  if (key.length == 12 && RegExp(r'^90[23]').hasMatch(key)) return PhoneKind.work;
  return PhoneKind.other;
}

class CardParser {
  static final emailPattern = RegExp(r'[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}');
  static final webPattern = RegExp(r'(?:https?://|www\.)[^\s,;]+', caseSensitive: false);
  static final phonePattern = RegExp(r'\+?\d[\d ()\-.]{7,}\d');
  static String fold(String s) => s.toLowerCase().replaceAll('i\u0307', 'i').replaceAll('ı', 'i').replaceAll('ş', 's').replaceAll('ğ', 'g').replaceAll('ü', 'u').replaceAll('ö', 'o').replaceAll('ç', 'c');
  static final industry = RegExp(
    r'\b(ltd|sti|a\.s|limited|sirket|dogalgaz|insaat|mekanik|teknoloji|yazilim|ticaret|sanayi|otomotiv|faktoring|teknik|servis|muhendislik|enerji|klima|isitma|sogutma)\b',
  );
  // The folded string has the same character positions for these Turkish letters.
  static final titlePattern = RegExp(
    r'\b(?:(?:makine|makina|insaat|elektrik(?:\s+elektronik)?|bilgisayar|yazilim)\s+(?:muhendisi|muhendis|muh\.?)|(?:satis|pazarlama|genel|bolge|proje|portfoy)\s+(?:muduru|yoneticisi|uzmani|danismani|yetkilisi)|muhendisi|muhendis|muduru|mudur|yonetici|danisman|uzman|yetkilisi|direktor|manager|engineer|director|ceo)(?![a-z])');
  // Only change zero inside an otherwise alphabetic name token.
  // Raw OCR remains visible for review; actual phone digits are never changed.
  static String repairName(String value) => value.split(RegExp(r'\s+')).map((token) {
    if (token.contains('0') && RegExp(r'^[A-Za-zÇĞİÖŞÜçğıöşü0]+$').hasMatch(token)
        && token.replaceAll('0', '').length >= 2) {
      return token.replaceAll('0', 'O');
    }
    return token;
  }).join(' ');

  static bool _nameLike(String s) {
    final words = s.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final normalized = fold(s);

    if (words.length < 2 || words.length > 5) return false;
    if (RegExp(r'[\d:@/]').hasMatch(s)) return false;
    if (RegExp(
      r'\b(yetkili|yetkilisi|bayi|bayii|servis|cozum|cozumleri|sube|subesi|cadde|caddesi|teknik|muhendislik|enerji|klima)\b',
    ).hasMatch(normalized)) {
      return false;
    }

    // Avoid accepting badly fragmented OCR such as "SS O" as a person's name.
    // A genuine two-word name should normally have at least two alphabetic
    // characters in each token.
    final alphaToken = RegExp(r'^[A-Za-zÇĞİÖŞÜçğıöşü]{2,}$');
    return words.every(alphaToken.hasMatch);
  }
  static bool _industryLike(String value) {
    final normalized = fold(value);
    final compact = normalized.replaceAll(RegExp(r'\s+'), '');
    return industry.hasMatch(normalized)
        || compact.contains('faktoring')
        || compact.contains('faktorin');
  }

  static bool _companyLike(String value) {
    final trimmed = value.trim();
    final normalized = fold(trimmed);

    if (_industryLike(trimmed)) return true;
    if (titlePattern.hasMatch(normalized)) return false;
    if (RegExp(r'[\d:@/]').hasMatch(trimmed)) return false;

    final words = trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty || words.length > 6) return false;

    // Common business words that OCR may read correctly even when the company
    // does not contain Ltd./A.Ş. Example: "ERSOY TEKNİK".
    if (RegExp(
      r'\b(teknik|servis|muhendislik|enerji|mekanik|dogalgaz|klima|isitma|sogutma|ticaret|sanayi|teknoloji|yazilim|insaat)\b',
    ).hasMatch(normalized)) {
      return true;
    }

    return false;
  }
  static String repairCompany(String value) {
    var repaired = value.trim();
    final parts = repaired.split(RegExp(r'\s+'));
    if (parts.length >= 4 && fold(parts.first).length == 1
        && fold(parts[1]).startsWith(fold(parts.first))) {
      repaired = parts.skip(1).join(' ');
    }
    final splitFaktoring = RegExp(
      r'\bfakto\s+r[iİıI]n[gG]?\b',
      caseSensitive: false,
    );
    if (splitFaktoring.hasMatch(repaired)) {
      final allUppercase = repaired == repaired.toUpperCase();
      repaired = repaired.replaceAll(
        splitFaktoring,
        allUppercase ? 'FAKTORİNG' : 'Faktoring',
      );
    }
    return repaired;
  }
  static String _compactLogo(String s) {
    final parts = s.split(RegExp(r'\s+'));
    return parts.length >= 3 && parts.every((p) => RegExp(r'^[A-Za-zÇĞİÖŞÜçğıöşü]$').hasMatch(p)) ? parts.join() : s;
  }

  CardData parse(String text) {
    final data = CardData();
    final lines = text.split(RegExp(r'[\r\n]+')).map((s) => _compactLogo(s.trim())).where((s) => s.isNotEmpty).toList();
    // A line repeated verbatim (logo header + body, footer, etc.) is very
    // likely the company/brand name rather than a person's name.
    final lineCounts = <String, int>{};
    for (final line in lines) {
      lineCounts.update(fold(line), (v) => v + 1, ifAbsent: () => 1);
    }
    final names = <String>[];
    final addresses = <String>[];
    final seen = <String>{};
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = fold(line);
      final mail = emailPattern.firstMatch(line);
      final web = webPattern.firstMatch(line);
      if (mail != null && data.email.isEmpty) data.email = mail.group(0)!;
      if (web != null && data.website.isEmpty) data.website = web.group(0)!.replaceAll(RegExp(r'[.)]+$'), '');
      if (RegExp(r'\b(vergi|vkn|tckn|iban|mersis|sicil)\b').hasMatch(lower)) continue;
      final isAddress = RegExp(r'\b(adres|address|mah|mahalle|mahallesi|cad|caddesi|sok|sokak|bulvari|apt|apartmani|kat|daire|no)\b').hasMatch(lower);
      if (isAddress && mail == null && web == null) { addresses.add(line); continue; }
      var hasPhone = false;
      if (mail == null && web == null) {
        for (final m in phonePattern.allMatches(line)) {
          final value = normalizePhone(m.group(0)!);
          final key = phoneKey(value);
          if (key.length >= 10 && key.length <= 15) {
            hasPhone = true;
            if (seen.add(key)) {
              data.phones.add(value);
              var kind = inferPhoneKind(value);
              if (RegExp(r'\b(gsm|cep|mobile|cell)\b').hasMatch(lower)) {
                kind = PhoneKind.mobile;
              } else if (kind == PhoneKind.other && RegExp(r'\b(tel|telefon|office|work)\b').hasMatch(lower)) {
                kind = PhoneKind.work;
              }
              data.phoneKinds[value] = kind;
            }
          }
        }
      }
      if (mail != null || web != null || hasPhone) continue;
      if (_companyLike(line) && titlePattern.firstMatch(lower) == null) {
        if (data.company.isEmpty) {
          var company = line;
          // A single-word brand followed by a separate industry line.
          if (i > 0 && RegExp(r'^(dogalgaz|yazilim|insaat|teknoloji|mekanik)$').hasMatch(lower)) {
            final previous = lines[i - 1];
            if (RegExp(r'^[A-Za-zÇĞİÖŞÜçğıöşü-]{2,30}$').hasMatch(previous)
                && titlePattern.firstMatch(fold(previous)) == null) {
              company = '$previous $line';
              names.remove(previous);
            }
          }
          data.company = repairCompany(company);
        }
        continue;
      }
      final title = titlePattern.firstMatch(lower);
      if (title != null) {
        if (data.title.isEmpty) {
          final titleText = line.substring(title.start, title.end).trim();
          data.title = titleText;
          // Only expand the known abbreviation, never guess an unreadable name.
          if (RegExp(r'^(makine|makina) muh\.?$').hasMatch(fold(data.title))) data.title = 'Makine Mühendisi';
        }
        final rest = '${line.substring(0, title.start)} ${line.substring(title.end)}'
          .replaceAll(RegExp(r'^[\s:|,;.-]+|[\s:|,;.-]+$'), '').trim();
        final repaired = repairName(rest);
        if (_nameLike(repaired)) data.name = repaired;
        continue;
      }
      if (fold(line) == fold(data.company)) continue;
      final repaired = repairName(line);
      if (!_nameLike(repaired)) continue;
      if (data.company.isEmpty && (lineCounts[lower] ?? 0) >= 2) {
        data.company = repairCompany(line);
      } else {
        names.add(repaired);
      }
    }
    if (data.name.isEmpty && names.isNotEmpty) data.name = names.first;
    data.address = addresses.join('\n');
    return data;
  }
}
