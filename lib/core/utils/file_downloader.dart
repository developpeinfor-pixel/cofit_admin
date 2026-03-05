import 'dart:typed_data';

import 'file_downloader_stub.dart'
    if (dart.library.html) 'file_downloader_web.dart'
    if (dart.library.io) 'file_downloader_io.dart' as impl;

Future<String?> downloadBytes({
  required String fileName,
  required String mimeType,
  required Uint8List bytes,
}) {
  return impl.downloadBytes(fileName: fileName, mimeType: mimeType, bytes: bytes);
}
