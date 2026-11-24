import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'dart:convert';

class PrinterService {
  static Future<List<BluetoothInfo>> getPairedPrinters() async {
    try {
      return await PrintBluetoothThermal.pairedBluetooths;
    } catch (e) {
      throw Exception("Gagal memindai printer: $e");
    }
  }

  static Future<bool> connect(String macAddress) async {
    try {
      bool isConnected = await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
      return isConnected;
    } catch (e) {
      throw Exception("Gagal terhubung ke printer: $e");
    }
  }

  static Future<bool> printText(String text) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      String finalText = text + "\n\n\n";
      List<int> bytes = utf8.encode(finalText);
      bool result = await PrintBluetoothThermal.writeBytes(bytes);
      return result;
    } catch (e) {
      throw Exception("Gagal mencetak: $e");
    }
  }

  static Future<bool> printBytes(List<int> bytes) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      bool result = await PrintBluetoothThermal.writeBytes(bytes);
      return result;
    } catch (e) {
      throw Exception("Gagal mencetak bytes: $e");
    }
  }

  static Future<void> disconnect() async {
    try {
      await PrintBluetoothThermal.disconnect;
    } catch (e) {
      // Abaikan error saat disconnect
    }
  }
}