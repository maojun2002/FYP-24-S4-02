// Updated BluetoothManager.dart (phone)
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';

class BluetoothManager {
  final FlutterBluePlus flutterBlue = FlutterBluePlus();

  Future<void> connectAndSendOtp(String bluetoothAddress, String otp) async {
    print("Starting scan...");
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) async {
      for (final result in results) {
        if (result.device.id.toString() == bluetoothAddress) {
          print("Target device found: ${result.device.name}");
          await result.device.connect();
          FlutterBluePlus.stopScan();

          // Discover services dynamically
          final services = await result.device.discoverServices();
          for (final service in services) {
            print("Discovered service: ${service.uuid}");
            for (final characteristic in service.characteristics) {
              print("Found characteristic: ${characteristic.uuid}");

              if (characteristic.properties.write) {
                print("Writable characteristic found. Sending OTP...");
                await characteristic.write(otp.codeUnits, withoutResponse: true);
                print("OTP sent successfully.");
              }
            }
          }
          return;
        }
      }
    });
  }
}

