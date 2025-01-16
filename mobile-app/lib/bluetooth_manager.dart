import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothManager {
  /// Start scanning and listening for connections on desktop platforms
  void startListeningForConnections(String targetDeviceId, String otp) {
    print("Starting to listen for Bluetooth connections...");

    // Check platform and initiate appropriate scanning
    if (isDesktopPlatform()) {
      _startDesktopScan(targetDeviceId, otp);
    } else {
      _startMobileScan(targetDeviceId, otp);
    }
  }

  /// Desktop Bluetooth scan using Windows API
  void _startDesktopScan(String targetDeviceId, String otp) {
    final deviceInfo = calloc<BLUETOOTH_DEVICE_INFO>();
    deviceInfo.ref.dwSize = sizeOf<BLUETOOTH_DEVICE_INFO>();

    final findRadioParams = calloc<BLUETOOTH_FIND_RADIO_PARAMS>();
    findRadioParams.ref.dwSize = sizeOf<BLUETOOTH_FIND_RADIO_PARAMS>();

    final radioHandle = calloc<HANDLE>();
    final findRadio = BluetoothFindFirstRadio(findRadioParams, radioHandle);

    if (findRadio != 0) {
      do {
        final findDeviceParams = calloc<BLUETOOTH_DEVICE_SEARCH_PARAMS>();
        findDeviceParams.ref.dwSize = sizeOf<BLUETOOTH_DEVICE_SEARCH_PARAMS>();
        findDeviceParams.ref.fReturnRemembered = TRUE;
        findDeviceParams.ref.fReturnAuthenticated = TRUE;
        findDeviceParams.ref.fReturnConnected = TRUE;
        findDeviceParams.ref.fIssueInquiry = TRUE;
        findDeviceParams.ref.hRadio = radioHandle.value;

        final findDeviceHandle = BluetoothFindFirstDevice(findDeviceParams, deviceInfo);

        if (findDeviceHandle != 0) {
          do {
            final nameArray = deviceInfo.ref.szName;
            final codeUnits = <int>[];

            // Extract device name
            for (int i = 0; i < 248 && nameArray[i] != 0; i++) {
              codeUnits.add(nameArray[i]);
            }

            final deviceName = String.fromCharCodes(codeUnits);
            final isConnected = deviceInfo.ref.fConnected != 0;

            // Check if the device matches the target
            if (deviceName == targetDeviceId) {
              print("Target device found: $deviceName, Connected: $isConnected");
              _handleDesktopConnection(deviceName, otp);
              break;
            }
          } while (BluetoothFindNextDevice(findDeviceHandle, deviceInfo) != 0);

          BluetoothFindDeviceClose(findDeviceHandle);
        }

        calloc.free(findDeviceParams);
      } while (BluetoothFindNextRadio(findRadio, radioHandle) != 0);

      BluetoothFindRadioClose(findRadio);
    } else {
      print("No Bluetooth radios found.");
    }

    calloc.free(deviceInfo);
    calloc.free(findRadioParams);
    calloc.free(radioHandle);
  }

  /// Mobile Bluetooth scan using FlutterBluePlus
  void _startMobileScan(String targetDeviceId, String otp) {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 30));

    // Listen for scan results
    FlutterBluePlus.scanResults.listen((List<ScanResult> results) {
      for (final result in results) {
        print("Device found: ${result.device.name} (${result.device.id})");

        // Check device name or identifier
        if (result.device.id.id == targetDeviceId) {
          FlutterBluePlus.stopScan(); // Stop scanning
          _handleConnection(result.device, otp); // Handle connection
          break;
        }
      }
    });
  }

  /// Handle connection for desktop devices
  void _handleDesktopConnection(String deviceName, String otp) {
    print("Connecting to desktop device: $deviceName");
    // Add connection logic here if required
  }

  /// Handle connection for mobile devices
  Future<void> _handleConnection(BluetoothDevice device, String otp) async {
    print("Connecting to device: ${device.name}");

    try {
      await device.connect(); // Connect to device
      print("Connected to device: ${device.name}");

      // Discover services dynamically
      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        print("Discovered service: ${service.uuid}");
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          print("Discovered characteristic: ${characteristic.uuid}");
          if (characteristic.properties.read) {
            print("Readable characteristic found. Waiting for OTP...");
            characteristic.value.listen((data) {
              final receivedOtp = String.fromCharCodes(data);
              print("Received OTP: $receivedOtp");
              _verifyIncomingOTP(receivedOtp, otp, characteristic);
            });
          }
        }
      }
    } catch (e) {
      print("Error connecting to device: $e");
      await device.disconnect();
    }
  }

  /// Verify OTP and send result
  void _verifyIncomingOTP(
      String receivedOtp, String expectedOtp, BluetoothCharacteristic characteristic) async {
    print("Received OTP: $receivedOtp");
    print("Expected OTP: $expectedOtp");
    if (receivedOtp == expectedOtp) {
      print("OTP verified successfully.");
      await characteristic.write("VERIFIED".codeUnits, withoutResponse: true);
    } else {
      print("Invalid OTP.");
      await characteristic.write("FAILED".codeUnits, withoutResponse: true);
    }
  }



  /// Check if running on a desktop platform
  bool isDesktopPlatform() {
    return ['windows', 'macos', 'linux'].contains(Platform.operatingSystem);
  }

  /// Retrieves the Bluetooth address of the device
static String getDeviceAddress() {
    final findRadioParams = calloc<BLUETOOTH_FIND_RADIO_PARAMS>();
    final radioHandle = calloc<IntPtr>();
    final adapterInfo = calloc<BLUETOOTH_RADIO_INFO>();

    try {
      // Initialize the BLUETOOTH_FIND_RADIO_PARAMS structure
      findRadioParams.ref.dwSize = sizeOf<BLUETOOTH_FIND_RADIO_PARAMS>();

      // Open Bluetooth radio handle
      final findHandle = BluetoothFindFirstRadio(findRadioParams, radioHandle);
      if (findHandle == 0) {
        return 'Bluetooth adapter not found';
      }

      // Initialize the BLUETOOTH_RADIO_INFO structure
      adapterInfo.ref.dwSize = sizeOf<BLUETOOTH_RADIO_INFO>();

      // Get radio info
      final getInfoResult = BluetoothGetRadioInfo(radioHandle.value, adapterInfo);
      if (getInfoResult != ERROR_SUCCESS) {
        return 'Error retrieving Bluetooth adapter info';
      }

      // Extract and format the Bluetooth address in big-endian order
      final addressBytes = adapterInfo.ref.address.rgBytes;
      final address = List.generate(6, (index) => addressBytes[5 - index].toRadixString(16).padLeft(2, '0')).join(':');
      return address.toUpperCase();
    } finally {
      // Free allocated memory
      free(findRadioParams);
      free(radioHandle);
      free(adapterInfo);
    }
  }

}
