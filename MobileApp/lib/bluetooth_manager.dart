import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothManager {
  final FlutterBluePlus flutterBlue = FlutterBluePlus();

  // Method to connect to a Bluetooth device
  Future<void> connectToDevice(String bluetoothAddress, String otp) async {
    try {
      // Start scanning for devices
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

      // Listen to scan results
      FlutterBluePlus.scanResults.listen((results) async {
        for (ScanResult r in results) {
          print('Device found: ${r.device.name} (${r.device.id})');

          // Check if the device address matches
          if (r.device.id.toString() == bluetoothAddress) {
            print("Connecting to device...");
            await r.device.connect();
            FlutterBluePlus.stopScan(); // Stop scanning after connecting
            print("Connected to device: ${r.device.name}");

            // Verify OTP or perform pairing logic here
            if (await verifyOTP(r.device, otp)) {
              print("Verification successful!");
            } else {
              print("Verification failed!");
              await r.device.disconnect();
            }
          }
        }
      });
    } catch (e) {
      print("Error during Bluetooth connection: $e");
    }
  }

  // OTP verification method
  Future<bool> verifyOTP(BluetoothDevice device, String otp) async {
    try {
      print("Sending OTP for verification...");

      // Discover services on the device
      List<BluetoothService> services = await device.discoverServices();

      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          // Assume the characteristic UUID matches the expected one for OTP verification
          if (characteristic.uuid.toString() == "0000xxxx-0000-1000-8000-00805f9b34fb") { // Replace with the actual UUID
            // Write the OTP to the characteristic
            await characteristic.write(otp.codeUnits, withoutResponse: true);

            // Read the response
            final response = await characteristic.read();
            final responseString = String.fromCharCodes(response);
            print("OTP Verification Response: $responseString");

            return responseString == "VERIFIED"; // Adjust based on the expected response
          }
        }
      }

      return false; // Return false if no matching characteristic is found
    } catch (e) {
      print("Error during OTP verification: $e");
      return false;
    }
  }
}
