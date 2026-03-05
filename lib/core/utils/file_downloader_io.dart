import 'dart:io';
import 'dart:typed_data';

Future<String?> downloadBytes({
  required String fileName,
  required String mimeType,
  required Uint8List bytes,
}) async {
  final file = File('${Directory.current.path}${Platform.pathSeparator}$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
