// ignore: avoid_web_libraries_in_flutter
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

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
  try {
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = filename;
    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);

    return DownloadResult(
      success: true,
      filename: filename,
      filePath: filename,
      storageFolder: 'Downloads',
    );
  } catch (e) {
    return DownloadResult(
      success: false,
      filename: filename,
      filePath: '',
      storageFolder: 'Downloads',
      error: e.toString(),
    );
  }
}

Future<void> shareDownloadedFile({
  required String filePath,
  required String filename,
  required String mimeType,
}) async {
  // Web fallback: already downloaded via browser
}

Future<void> shareTextContent({
  required String text,
  String? subject,
}) async {
  // Web fallback
}
