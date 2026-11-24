import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:intl/intl.dart';
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
  return androidInfo.id; // Android ID sebagai Machine ID
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