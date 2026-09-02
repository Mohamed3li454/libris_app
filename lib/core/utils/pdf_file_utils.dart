import 'dart:io';

Future<bool> fileLooksLikePdf(String path) async {
  try {
    final file = File(path);
    if (!await file.exists()) return false;
    if (await file.length() < 5) return false;
    final raf = await file.open();
    try {
      final header = await raf.read(5);
      return header.length >= 4 &&
          header[0] == 0x25 &&
          header[1] == 0x50 &&
          header[2] == 0x44 &&
          header[3] == 0x46;
    } finally {
      await raf.close();
    }
  } catch (_) {
    return false;
  }
}
