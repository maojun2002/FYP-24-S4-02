// Updated BluetoothManager.dart (phone)
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';
import 'dart:convert';

class BluetoothManager {
  Future<bool> connectAndSendOtp(String bluetoothAddress, String otp) async {
    try {
      // Find and connect to the Bluetooth device using the address
      BluetoothDevice device = await findDeviceByAddress(bluetoothAddress);
      await device.connect();
      print("Connected to device: ${device.name}");

      // Discover services and characteristics
      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          // Write OTP to the writable characteristic
          if (characteristic.properties.write) {
            await characteristic.write(otp.codeUnits);
            print("OTP sent: $otp");
            return true; // Assume success for simplicity
          }
        }
      }

      return false; // No writable characteristic found
    } catch (e) {
      print("Error connecting or sending OTP: $e");
      return false;
    }
  }

  Future<BluetoothDevice> findDeviceByAddress(String bluetoothAddress) async {
    Completer<BluetoothDevice> completer = Completer();

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 30));

    FlutterBluePlus.scanResults.listen((List<ScanResult> results) {
      for (final result in results) {
        print("Discovered device: ${result.device.name} (${result.device.id})");
        if (result.device.id.id == bluetoothAddress) {
          print("Target device found: ${result.device.name}");
          FlutterBluePlus.stopScan();
          completer.complete(result.device);
          return;
        }
      }
    }).onError((e) {
      print("Error during scan: $e");
      completer.completeError(e);
    });

    await Future.delayed(const Duration(seconds: 30));
    if (!completer.isCompleted) {
      FlutterBluePlus.stopScan();
      completer.completeError("Device not found within timeout.");
    }

    return completer.future;
  }



}


