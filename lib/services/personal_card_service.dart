import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../models/personal_card.dart';

class PersonalCardService {
  final Future<Directory> Function() _directoryProvider;
  static Future<void> _writes = Future.value();
  PersonalCardService({Future<Directory> Function()? directoryProvider})
    : _directoryProvider =
          directoryProvider ?? getApplicationDocumentsDirectory;
  Future<Directory> _directory() async =>
      Directory('${(await _directoryProvider()).path}/kisisel_kartvizit')
          .create(recursive: true);
  Future<T> _exclusive<T>(Future<T> Function() work) {
    final result = _writes.then((_) => work());
    _writes = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<PersonalCard?> load() async {
    final directory = await _directory();
    final file = File('${directory.path}/profile.json');
    if (!await file.exists()) return null;
    final profile = PersonalCard.fromJson(
      Map<String, dynamic>.from(jsonDecode(await file.readAsString()) as Map),
    );
    final name = profile.avatarPath?.replaceAll('\\', '/').split('/').last;
    if (name == '.' || name == '..' || name == '') {
      throw const FormatException('Fotoğraf yolu geçersiz.');
    }
    return PersonalCard(
      data: profile.data,
      theme: profile.theme,
      avatarPath: name == null ? null : '${directory.path}/$name',
    );
  }

  Future<PersonalCard> save(
    PersonalCard profile, {
    String? sourceAvatar,
    bool removeAvatar = false,
  }) => _exclusive(
    () =>
        _save(profile, sourceAvatar: sourceAvatar, removeAvatar: removeAvatar),
  );

  Future<bool> restoreIfAbsent(
    PersonalCard profile,
    Uint8List? avatar,
  ) => _exclusive(() async {
    if (await load() != null) return false;
    final directory = await _directory();
    File? source;
    try {
      if (avatar != null) {
        source = File(
          '${directory.path}/restore_${DateTime.now().microsecondsSinceEpoch}.tmp',
        );
        await source.writeAsBytes(avatar, flush: true);
      }
      await _save(profile, sourceAvatar: source?.path);
      return true;
    } finally {
      if (source != null) {
        try {
          await source.delete();
        } on FileSystemException {
          /* Temp cleanup. */
        }
      }
    }
  });

  Future<PersonalCard> _save(
    PersonalCard profile, {
    String? sourceAvatar,
    bool removeAvatar = false,
  }) async {
    profile.validate();
    final current = await load();
    final directory = await _directory();
    File? copied;
    var avatar = removeAvatar ? null : current?.avatarPath;
    if (sourceAvatar != null &&
        !removeAvatar &&
        sourceAvatar != current?.avatarPath) {
      final source = File(sourceAvatar);
      if (await source.length() > 12 * 1024 * 1024) {
        throw const FormatException('Fotoğraf 12 MB sınırını aşıyor.');
      }
      copied = await source.copy(
        '${directory.path}/avatar_${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
      avatar = copied.path;
    }
    final saved = PersonalCard(
      data: profile.data,
      theme: profile.theme,
      avatarPath: avatar,
    );
    final file = File('${directory.path}/profile.json');
    try {
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsString(
        jsonEncode({
          ...saved.toJson(),
          'avatarPath': avatar?.replaceAll('\\', '/').split('/').last,
        }),
        flush: true,
      );
      await temporary.rename(file.path);
    } catch (_) {
      if (copied != null) await copied.delete();
      rethrow;
    }
    if (current?.avatarPath != null && current!.avatarPath != avatar) {
      try {
        await File(current.avatarPath!).delete();
      } on FileSystemException {
        /* Already absent. */
      }
    }
    return saved;
  }
}
