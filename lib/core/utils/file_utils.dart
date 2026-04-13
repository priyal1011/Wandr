import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class FileUtils {
  /// Copies a source file to the application's persistent documents directory
  /// to ensure it survives cache clears and app updates.
  static Future<String> saveFilePersistently(String sourcePath) async {
    if (sourcePath.isEmpty || sourcePath.startsWith('http')) return sourcePath;
    
    try {
      final File sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) return sourcePath;

      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String fileName = p.basename(sourcePath);
      final String targetPath = p.join(appDocDir.path, 'wandr_media', fileName);

      // Ensure directory exists
      final Directory mediaDir = Directory(p.join(appDocDir.path, 'wandr_media'));
      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
      }

      final File targetFile = await sourceFile.copy(targetPath);
      return targetFile.path;
    } catch (e) {
      debugPrint('Error saving file persistently: $e');
      return sourcePath;
    }
  }
}
