import 'package:flutter/services.dart' show rootBundle;

/// Telefonda kurulu olan derlemenin sürümünü verir.
///
/// `pubspec.yaml` uygulamanın içine varlık olarak gömüldüğü için okunan değer,
/// kaynak koddaki güncel sürüm değil, o paketi derleyen sürümdür. Yani eski bir
/// derleme kuruluysa eski sürüm görünür — mağaza güncellemesinin cihaza inip
/// inmediği bu satırdan anlaşılır.
class AppVersion {
  AppVersion._();

  /// pubspec'in en üst düzeydeki `version:` satırı. Girintili satırlar
  /// (bağımlılıklar) `^` nedeniyle eşleşmez.
  static final RegExp _versionLine = RegExp(
    r'^version:\s*([^\s#]+)',
    multiLine: true,
  );

  static String? _cached;

  /// `1.6.0 (build 30)` biçiminde döner. Okunamazsa null.
  static Future<String?> load() async {
    final cached = _cached;
    if (cached != null) return cached;
    try {
      return _cached = parsePubspec(await rootBundle.loadString('pubspec.yaml'));
    } catch (_) {
      return null;
    }
  }

  /// pubspec içeriğinden sürümü ayıklayıp biçimlendirir.
  static String? parsePubspec(String pubspec) {
    final match = _versionLine.firstMatch(pubspec);
    return match == null ? null : format(match.group(1)!);
  }

  /// `1.6.0+30` → `1.6.0 (build 30)`. Build numarası yoksa sürüm aynen döner.
  static String format(String version) {
    final plus = version.indexOf('+');
    if (plus < 0) return version;
    final build = version.substring(plus + 1);
    if (build.isEmpty) return version.substring(0, plus);
    return '${version.substring(0, plus)} (build $build)';
  }
}
