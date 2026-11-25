import 'dart:async';
import 'dart:convert';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:permission_handler/permission_handler.dart';

class PrinterService {
  static Future<bool> ensurePermissions() async {
    try {
      final statuses = await [
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.location,
      ].request();
      return statuses.values.every((s) => s.isGranted || s.isLimited);
    } catch (e) {
      return false;
    }
  }

  static Future<List<BluetoothInfo>> getPairedPrinters({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      return await PrintBluetoothThermal.pairedBluetooths.timeout(timeout);
    } on TimeoutException {
      throw Exception(
        'Waktu scan habis (15 detik).\n'
        'Pastikan Bluetooth HP AKTIF dan printer sudah di-pairing.',
      );
    } catch (e) {
      throw Exception('Gagal memindai printer: $e');
    }
  }

  static Future<bool> connect(String macAddress) async {
    try {
      return await PrintBluetoothThermal.connect(
        macPrinterAddress: macAddress,
      ).timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw Exception(
        'Waktu koneksi habis (20 detik).\n'
        'Matikan printer, nyalakan lagi, lalu coba connect ulang.',
      );
    } catch (e) {
      throw Exception('Gagal terhubung ke printer: $e');
    }
  }

  static Future<bool> printText(String text) async {
    try {
      List<int> bytes = utf8.encode(text + "\n\n\n");
      return await PrintBluetoothThermal.writeBytes(bytes);
    } catch (e) {
      throw Exception('Gagal mencetak: $e');
    }
  }

  static Future<bool> printBytes(List<int> bytes) async {
    try {
      return await PrintBluetoothThermal.writeBytes(bytes);
    } catch (e) {
      throw Exception('Gagal mengirim bytes: $e');
    }
  }

  /// Print job LENGKAP dengan urutan benar:
  /// reset -> center -> logo -> header PERTAMINA (besar) -> left -> teks -> cut.
  static Future<bool> printFullJob({
    required String textContent,
    List<int>? logoBytes,
    required bool includePertaminaHeader,
  }) async {
    try {
      final List<int> allBytes = <int>[];

      // 1. ESC @ reset
      allBytes.addAll([0x1B, 0x40]);
      await Future.delayed(const Duration(milliseconds: 300));

      // 2. ESC a 1 center
      allBytes.addAll([0x1B, 0x61, 0x01]);

      // 3. Logo
      if (logoBytes != null && logoBytes.isNotEmpty) {
        allBytes.addAll(logoBytes);
        await Future.delayed(const Duration(milliseconds: 400));
      }

      // 4. Header PERTAMINA double-size (hanya Bon BBM)
      if (includePertaminaHeader) {
        allBytes.addAll([0x1B, 0x21, 0x30]); // double height + width
        allBytes.addAll(utf8.encode("PERTAMINA"));
        allBytes.addAll([0x1B, 0x21, 0x00]); // reset font
        allBytes.add(0x0A);
        allBytes.add(0x0A);
      }

      // 5. ESC a 0 left + teks struk
      allBytes.addAll([0x1B, 0x61, 0x00]);
      allBytes.addAll(utf8.encode(textContent));

      // 6. Feed + auto cut (GS V 0)
      allBytes.addAll([0x1D, 0x56, 0x00]);

      return await PrintBluetoothThermal.writeBytes(allBytes);
    } catch (e) {
      throw Exception('Gagal print job: $e');
    }
  }

  static Future<void> disconnect() async {
    try {
      await PrintBluetoothThermal.disconnect;
    } catch (e) {
      // abaikan
    }
  }
}