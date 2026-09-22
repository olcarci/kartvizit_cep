import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/card_data.dart';
import 'card_parser.dart';

abstract class CardTextReader {
  Future<String> read(String path);
  Future<void> close();
}

class MlKitCardTextReader implements CardTextReader {
  final _reader = TextRecognizer(script: TextRecognitionScript.latin);
  @override
  Future<String> read(String path) async =>
      (await _reader.processImage(InputImage.fromFilePath(path))).text;
  @override
  Future<void> close() => _reader.close();
}

class ScanDraft {
  final String imagePath;
  final String rawText;
  final CardData data;
  ScanDraft(this.imagePath, this.rawText, this.data);
}

class CardScanService {
  final CardTextReader reader;
  CardScanService(this.reader);
  Future<ScanDraft> scan(String path, {bool allowEmpty = false}) async {
    final raw = await reader.read(path);
    if (raw.trim().isEmpty && !allowEmpty) {
      throw const FormatException(
        'Yazı bulunamadı. Fotoğrafı kırpıp yeniden deneyin.',
      );
    }
    return ScanDraft(path, raw, CardParser().parse(raw));
  }

  // Keep corrected/front-side fields; only fill gaps and add new phone numbers.
  static CardData supplement(CardData front, CardData back) {
    final phones = [...front.phones];
    final kinds = {...front.phoneKinds};
    final keys = front.phones.map(phoneKey).toSet();
    for (final phone in back.phones) {
      if (keys.add(phoneKey(phone))) {
        phones.add(phone);
        kinds[phone] = back.phoneKinds[phone] ?? inferPhoneKind(phone);
      }
    }
    String fill(String current, String candidate) =>
        current.trim().isEmpty ? candidate : current;
    return CardData(
      name: fill(front.name, back.name),
      company: fill(front.company, back.company),
      title: fill(front.title, back.title),
      email: fill(front.email, back.email),
      website: fill(front.website, back.website),
      address: fill(front.address, back.address),
      phones: phones,
      phoneKinds: kinds,
    );
  }
}
