import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kartvizit_cep/services/app_version.dart';

void main() {
  test('Build numarası ayrı gösterilir', () {
    expect(AppVersion.format('1.6.0+30'), '1.6.0 (build 30)');
  });

  test('Build numarası yoksa sürüm olduğu gibi kalır', () {
    expect(AppVersion.format('1.6.0'), '1.6.0');
    expect(AppVersion.format('1.6.0+'), '1.6.0');
  });

  test('Girintili version satırları bağımlılıklardan okunmaz', () {
    const pubspec = 'name: kartvizit_cep\n'
        'version: 1.6.0+30\n'
        'dependencies:\n'
        '  bir_paket:\n'
        '    version: 9.9.9\n';
    expect(AppVersion.parsePubspec(pubspec), '1.6.0 (build 30)');
  });

  test('Sürüm satırı yoksa null döner', () {
    expect(AppVersion.parsePubspec('name: kartvizit_cep\n'), isNull);
  });

  test('Projenin gerçek pubspec dosyası okunabiliyor', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(AppVersion.parsePubspec(pubspec), isNotNull);
  });

  test('pubspec.yaml varlık olarak paketlenmiş', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('\n    - pubspec.yaml\n'));
  });
}
