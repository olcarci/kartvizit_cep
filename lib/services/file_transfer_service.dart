import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class FileTransferService {
  static Future<bool> save(Uint8List bytes, String name, String mime) async =>
      await FilePicker.saveFile(
        fileName: name,
        bytes: bytes,
        mimeType: mime,
        dialogTitle: 'Dosyayı kaydet',
      ) !=
      null;

  static Future<ShareResult> share(
    Uint8List bytes,
    String name,
    String mime,
    Rect origin,
  ) async {
    final root = await getTemporaryDirectory();
    final directory = await Directory('${root.path}/kartvizit_paylasim')
        .create(recursive: true);
    final cutoff = DateTime.now().subtract(const Duration(days: 1));
    await for (final entry in directory.list()) {
      if (entry is File && (await entry.stat()).modified.isBefore(cutoff)) {
        try {
          await entry.delete();
        } on FileSystemException {
          /* In use. */
        }
      }
    }
    final file = File(
      '${directory.path}/${DateTime.now().microsecondsSinceEpoch}_$name',
    );
    await file.writeAsBytes(bytes, flush: true);
    // Retain until the receiver has consumed it; clean on the next share after one day.
    return SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: mime)],
        sharePositionOrigin: origin,
      ),
    );
  }
}
