// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

bool get isWebExport => true;

Future<String?> saveBytes({
  required List<int> bytes,
  required String fileName,
}) async {
  final blob = html.Blob([Uint8List.fromList(bytes)]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = fileName
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
  return fileName;
}

Future<void> openSavedFile(String path) async {
  // File sudah diunduh lewat browser; tidak perlu dibuka lagi.
}
