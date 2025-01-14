// Updated BluetoothManager.dart (phone)
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';
import 'dart:convert';

class BluetoothManager {

  Future<bool> connectAndSendOtp(String bluetoothAddress, String otp) async {
    try {
      print("Attempting to connect to Bluetooth device: $bluetoothAddress");

      // 扫描并找到目标设备
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
      BluetoothDevice? targetDevice;

      await for (final results in FlutterBluePlus.scanResults) {
        for (final result in results) {
          if (result.device.id.id == bluetoothAddress) {
            targetDevice = result.device;
            break;
          }
        }
        if (targetDevice != null) break;
      }

      if (targetDevice == null) {
        print("Device not found.");
        return false;
      }

      FlutterBluePlus.stopScan(); // 停止扫描

      // 连接设备
      await targetDevice.connect();
      print("Connected to device: ${targetDevice.name}");

      // 发现服务
      List<BluetoothService> services = await targetDevice.discoverServices();
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          if (characteristic.properties.write) {
            print("Found writable characteristic: ${characteristic.uuid}");
            await characteristic.write(utf8.encode(otp), withoutResponse: true);
            print("OTP sent successfully.");
            return true; // 成功发送 OTP
          }
        }
      }

      print("No writable characteristic found.");
      return false; // 未找到可写入的特征值
    } catch (e) {
      print("Error during Bluetooth connection: $e");
      return false; // 连接失败
    }
  }
}

