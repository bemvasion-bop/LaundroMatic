import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DownloadResult {
  final bool success;
  final String filename;
  final String filePath;
  final String storageFolder;
  final String? error;

  const DownloadResult({
    required this.success,
    required this.filename,
    required this.filePath,
    required this.storageFolder,
    this.error,
  });
}

Future<DownloadResult> saveFile({
  required String filename,
  required String content,
  required String mimeType,
}) async {
  File? savedFile;
  String folderName = 'Downloads';

  if (!kIsWeb && Platform.isAndroid) {
    // 1. Primary: Save directly to the public Download directory (/storage/emulated/0/Download)
    try {
      final publicDownload = Directory('/storage/emulated/0/Download');
      if (!await publicDownload.exists()) {
        await publicDownload.create(recursive: true);
      }
      final file = File('${publicDownload.path}/$filename');
      await file.writeAsString(content);
      if (await file.exists() && await file.length() > 0) {
        savedFile = file;
        folderName = 'Downloads';
      }
    } catch (e) {
      debugPrint('Public /storage/emulated/0/Download write attempt: $e');
    }

    // 2. Secondary: Android External Downloads directory
    if (savedFile == null) {
      try {
        final dirs = await getExternalStorageDirectories(
          type: StorageDirectory.downloads,
        );
        if (dirs != null && dirs.isNotEmpty) {
          final file = File('${dirs.first.path}/$filename');
          await file.writeAsString(content);
          if (await file.exists() && await file.length() > 0) {
            savedFile = file;
            folderName = 'Device Storage';
          }
        }
      } catch (e) {
        debugPrint('External Storage downloads write attempt: $e');
      }
    }

    // 3. Tertiary: General External Storage Directory
    if (savedFile == null) {
      try {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          final file = File('${extDir.path}/$filename');
          await file.writeAsString(content);
          if (await file.exists() && await file.length() > 0) {
            savedFile = file;
            folderName = 'Device Storage';
          }
        }
      } catch (e) {
        debugPrint('External Storage directory write attempt: $e');
      }
    }
  }

  // Desktop (Windows / macOS / Linux)
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    try {
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) {
        final file = File('${downloadsDir.path}/$filename');
        await file.writeAsString(content);
        if (await file.exists() && await file.length() > 0) {
          savedFile = file;
          folderName = 'Downloads';
        }
      }
    } catch (e) {
      debugPrint('Desktop downloads write attempt: $e');
    }
  }

  // 4. Fallback for iOS or constrained sandbox: Application Documents
  if (savedFile == null) {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final file = File('${docDir.path}/$filename');
      await file.writeAsString(content);
      if (await file.exists() && await file.length() > 0) {
        savedFile = file;
        folderName = 'Documents';
      }
    } catch (e) {
      debugPrint('Documents directory write attempt: $e');
    }
  }

  // 5. Ultimate fallback: Temporary cache
  if (savedFile == null) {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      await file.writeAsString(content);
      if (await file.exists()) {
        savedFile = file;
        folderName = 'Storage';
      }
    } catch (e) {
      debugPrint('Temporary directory write attempt: $e');
    }
  }

  if (savedFile != null) {
    return DownloadResult(
      success: true,
      filename: filename,
      filePath: savedFile.path,
      storageFolder: folderName,
    );
  } else {
    return DownloadResult(
      success: false,
      filename: filename,
      filePath: '',
      storageFolder: folderName,
      error: 'Unable to save file to device storage',
    );
  }
}

Future<void> shareDownloadedFile({
  required String filePath,
  required String filename,
  required String mimeType,
}) async {
  try {
    // Ensure FileProvider can access the file by having a copy in cache if needed
    final tempDir = await getTemporaryDirectory();
    final cacheFile = File('${tempDir.path}/$filename');
    if (filePath != cacheFile.path) {
      final srcFile = File(filePath);
      if (await srcFile.exists()) {
        await srcFile.copy(cacheFile.path);
      }
    }

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(cacheFile.path, mimeType: mimeType, name: filename)],
        subject: filename,
      ),
    );
  } catch (e) {
    debugPrint('shareDownloadedFile error: $e');
  }
}

Future<void> shareTextContent({
  required String text,
  String? subject,
}) async {
  try {
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: subject,
      ),
    );
  } catch (e) {
    debugPrint('shareText error: $e');
  }
}
