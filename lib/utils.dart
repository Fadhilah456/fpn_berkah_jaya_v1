import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'config.dart';

String fmt(int n) {
  final formatter = NumberFormat('#,###', 'id_ID');
  return formatter.format(n);
}

String nowDateStr() {
  return DateFormat('dd/MM/yyyy').format(DateTime.now());
}

String nowTimeStr() {
  return DateFormat('HH:mm:ss').format(DateTime.now());
}

Future<String> getMachineId() async {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
  return androidInfo.id;
}

String generateActivationCode(String machineId) {
  String input = AppConfig.secret + machineId;
  List<int> bytes = utf8.encode(input);
  Digest digest = sha256.convert(bytes);
  String hex = digest.toString().toUpperCase();
  List<String> parts = [];
  for (int i = 0; i < 16; i += 4) {
    parts.add(hex.substring(i, i + 4));
  }
  return parts.join('-');
}

String centerText(String text, int width) {
  int padding = (width - text.length) ~/ 2;
  if (padding < 0) padding = 0;
  return text.padLeft(padding + text.length).padRight(width);
}

String padRight(String text, int width) {
  if (text.length >= width) return text;
  return text.padRight(width);
}

String padLeft(String text, int width) {
  if (text.length >= width) return text;
  return text.padLeft(width);
}

// Simpan teks ke file TXT di folder internal aplikasi, kembalikan path-nya
Future<String> saveTextToFile(String teks, String namaFile) async {
  final directory = await getApplicationDocumentsDirectory();
  final folder = Directory('${directory.path}/hasil');
  if (!await folder.exists()) {
    await folder.create(recursive: true);
  }
  final file = File('${folder.path}/$namaFile');
  await file.writeAsString(teks, encoding: utf8);
  return file.path;
}

// Ambil daftar semua file .txt yang pernah disimpan (terbaru lebih dulu)
Future<List<File>> listSavedFiles() async {
  final directory = await getApplicationDocumentsDirectory();
  final folder = Directory('${directory.path}/hasil');
  if (!await folder.exists()) return [];
  final files = folder
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.txt'))
      .toList();
  files.sort((a, b) =>
      b.statSync().modified.compareTo(a.statSync().modified));
  return files;
}

// Format ukuran file jadi KB/MB
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// Konversi bytes gambar (jpg/png) dari asset menjadi perintah ESC/POS raster
/// (GS v 0). Mendukung JPEG & PNG otomatis. Width default 384 dot (58mm).
Future<List<int>> logoBytesToEscPos(
  Uint8List bytes, {
  int maxWidth = 384,
}) async {
  try {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return [];

    int w = decoded.width;
    int h = decoded.height;
    if (w > maxWidth) {
      h = (h * maxWidth / w).round();
      w = maxWidth;
    }

    final resized = img.copyResize(decoded, width: w, height: h);
    final gray = img.grayscale(resized);

    final int bytesPerRow = (w + 7) ~/ 8;
    final List<int> out = <int>[];

    out.addAll([0x1D, 0x76, 0x30, 0x00]);
    out.add(bytesPerRow & 0xFF);
    out.add((bytesPerRow >> 8) & 0xFF);
    out.add(h & 0xFF);
    out.add((h >> 8) & 0xFF);

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < bytesPerRow; x++) {
        int byte = 0;
        for (int bit = 0; bit < 8; bit++) {
          final px = x * 8 + bit;
          if (px < w) {
            final p = gray.getPixel(px, y);
            final lum = (p.r + p.g + p.b) ~/ 3;
            if (lum < 128) byte |= (1 << (7 - bit));
          }
        }
        out.add(byte);
      }
    }
    return out;
  } catch (e) {
    return [];
  }
}