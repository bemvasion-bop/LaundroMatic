import 'file_download_stub.dart'
    if (dart.library.html) 'file_download_web.dart';

export 'file_download_stub.dart'
    if (dart.library.html) 'file_download_web.dart';

Future<DownloadResult> downloadFile({
  required String filename,
  required String content,
  required String mimeType,
}) async {
  return await saveFile(filename: filename, content: content, mimeType: mimeType);
}

Future<void> shareFile({
  required String filePath,
  required String filename,
  required String mimeType,
}) async {
  await shareDownloadedFile(filePath: filePath, filename: filename, mimeType: mimeType);
}

Future<void> shareText({
  required String text,
  String? subject,
}) async {
  await shareTextContent(text: text, subject: subject);
}
