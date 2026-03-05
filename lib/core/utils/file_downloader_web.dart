// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

Future<String?> downloadBytes({
  required String fileName,
  required String mimeType,
  required Uint8List bytes,
}) async {
  final base64Data = base64Encode(bytes);
  final url = 'data:$mimeType;base64,$base64Data';
  final anchor = html.AnchorElement(href: url)
    ..download = fileName
    ..style.display = 'none';
  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  return null;
}
