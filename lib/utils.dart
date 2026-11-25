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

/// Baris dengan LABEL di kiri dan NILAI rata kanan (total = width).
String rowRight(String label, String value, int width) {
  int space = width - label.length - value.length;
  if (space < 1) space = 1;
  return label + (" " * space) + value;
}

/// Baris Key-Value natural (label : value), aman di 32 maupun 48 karakter.
String rowKV(String label, String value) {
  return "$label : $value";
}

/// Lebar karakter berdasarkan ukuran kertas printer.
int getLebarKarakter(int paperWidthMm) {
  return (paperWidthMm == 58) ? 32 : 48;
}

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

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// Konversi logo menjadi ESC/POS raster (GS v 0).
/// FIX: satu loop saja (tidak double), ukuran proporsional per kertas.
/// [paperWidthMm]: 58 atau 80. [logoScale]: 0.5 - 2.0.
Future<List<int>> logoBytesToEscPos(
  Uint8List bytes, {
  int paperWidthMm = 80,
  double logoScale = 1.0,
}) async {
  try {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return [];

    int maxDots = (paperWidthMm == 58) ? 384 : 576;
    int defaultMax = (paperWidthMm == 58) ? 150 : 200;
    int effectiveMax = defaultMax > maxDots ? maxDots : defaultMax;

    int w = decoded.width;
    int h = decoded.height;

    int targetW = (w * logoScale).round();
    if (targetW > effectiveMax) targetW = effectiveMax;
    if (targetW < 32) targetW = 32;

    if (w != targetW) {
      h = (h * targetW / w).round();
      w = targetW;
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