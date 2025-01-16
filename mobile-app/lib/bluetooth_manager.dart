// Updated BluetoothManager.dart (phone)
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';
import 'dart:convert';

class BluetoothManager {
  Future<bool> connectAndSendOtp(String bluetoothAddress, String otp) async {
    try {
      print("Finding device by address: $bluetoothAddress");
      BluetoothDevice device = await findDeviceByAddress(bluetoothAddress);

      print("Attempting to connect to device: ${device.name}");
      await device.connect();

      print("Discovering services...");
      List<BluetoothService> services = await device.discoverServices();

      for (BluetoothService service in services) {
        print("Service: ${service.uuid}");
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          print("Characteristic: ${characteristic.uuid}");
          if (characteristic.properties.write) {
            print("Writing OTP: $otp to characteristic: ${characteristic.uuid}");
            await characteristic.write(otp.codeUnits);
            print("OTP sent successfully.");
            return true;
          }
        }
      }
      print("No writable characteristic found.");
      return false;
    } catch (e) {
      print("Error during connection or OTP transmission: $e");
      return false;
    }
  }

  Future<BluetoothDevice> findDeviceByAddress(String bluetoothAddress) async {
    Completer<BluetoothDevice> completer = Completer();

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 60));

    FlutterBluePlus.scanResults.listen((List<ScanResult> results) {
      for (final result in results) {
        print("Scanned device: ${result.device.name} (${result.device.remoteId})");
        if (result.device.remoteId == bluetoothAddress) {
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

    // Handle timeout
    await Future.delayed(const Duration(seconds: 30));
    if (!completer.isCompleted) {
      FlutterBluePlus.stopScan();
      completer.completeError("Device not found within timeout.");
    }

    return completer.future;
  }

}


