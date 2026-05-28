import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Saves the given bytes to the device's user-visible Downloads area.
///
/// Android: writes to MediaStore.Downloads via a native MethodChannel. The
/// file appears in the Files app's Downloads section with no storage
/// permission required on Android 10+.
///
/// iOS: writes to the app's Documents directory, which is visible to the
/// user in the Files app under "On My iPhone → New Balan Medical".
///
/// Returns a human-readable location string that the UI can show (e.g.
/// "Downloads/invoice_ABC.pdf"). Throws on failure — callers should
/// catch and surface a friendly error.
class Downloads {
  static const _channel = MethodChannel('com.newbalan.medical/downloads');

  static Future<String> saveBytes({
    required Uint8List bytes,
    required String filename,
    String mimeType = 'application/octet-stream',
  }) async {
    if (Platform.isAndroid) {
      final result = await _channel.invokeMethod<String>(
        'saveToDownloads',
        {
          'bytes': bytes,
          'filename': filename,
          'mimeType': mimeType,
        },
      );
      if (result == null || result.isEmpty) {
        throw const FormatException('Native save returned no path');
      }
      return result;
    }

    if (Platform.isIOS) {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);
      return 'On My iPhone → New Balan Medical → $filename';
    }

    // Other platforms (web, desktop) — fall back to temp dir.
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file.path;
  }
}
