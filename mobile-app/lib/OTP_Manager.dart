import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'package:flutter/material.dart';

class OTPManager extends StatefulWidget {
const OTPManager({super.key});

  @override
  OTPManagerState createState() => OTPManagerState();
}

class OTPManagerState extends State<OTPManager> {
  List<Map<String, String>> pairedDevices = [];

  @override
  void initState() {
    super.initState();
    fetchPairedDevicesWindows();
  }

  void fetchPairedDevicesWindows() {
  List<Map<String, String>> devices = [];

    // Allocate memory for BLUETOOTH_DEVICE_INFO structure
    final deviceInfo = calloc<BLUETOOTH_DEVICE_INFO>();
    deviceInfo.ref.dwSize = sizeOf<BLUETOOTH_DEVICE_INFO>();

    // Allocate memory for BLUETOOTH_FIND_RADIO_PARAMS structure
    final findRadioParams = calloc<BLUETOOTH_FIND_RADIO_PARAMS>();
    findRadioParams.ref.dwSize = sizeOf<BLUETOOTH_FIND_RADIO_PARAMS>();

    // Open a handle to the Bluetooth radio
    final radioHandle = calloc<HANDLE>();
    final findRadio = BluetoothFindFirstRadio(findRadioParams, radioHandle);

  if (findRadio != 0) {
    do {
      final findDeviceParams = calloc<BLUETOOTH_DEVICE_SEARCH_PARAMS>();
      findDeviceParams.ref.dwSize = sizeOf<BLUETOOTH_DEVICE_SEARCH_PARAMS>();
      findDeviceParams.ref.fReturnRemembered = TRUE;
      findDeviceParams.ref.hRadio = radioHandle.value;

      final findDeviceHandle =
          BluetoothFindFirstDevice(findDeviceParams, deviceInfo);
      if (findDeviceHandle != 0) {
        do {
          final nameArray = deviceInfo.ref.szName;
          final codeUnits = <int>[];

          // Extract device name
          for (int i = 0; i < 248 && nameArray[i] != 0; i++) {
            codeUnits.add(nameArray[i]);
          }

          final deviceName = String.fromCharCodes(codeUnits);

          // Debug log for connection status
          print("Device: $deviceName, fConnected: ${deviceInfo.ref.fConnected}");

          // Check if the device is connected
          final isConnected = deviceInfo.ref.fConnected != 0; // Explicit boolean conversion

          // Add device info to the list
          devices.add({
            'name': deviceName,
            'status': isConnected ? 'Connected' : 'Not Connected',
          });
        } while (BluetoothFindNextDevice(findDeviceHandle, deviceInfo) != 0);
        BluetoothFindDeviceClose(findDeviceHandle);
      }

      CloseHandle(radioHandle.value);
    } while (BluetoothFindNextRadio(findRadio, radioHandle) != 0);
    BluetoothFindRadioClose(findRadio);
  }

  // Free allocated memory
  calloc.free(deviceInfo);
  calloc.free(findRadioParams);
  calloc.free(radioHandle);

  // Update UI with device list
  setState(() {
    pairedDevices = devices.isEmpty
        ? [
            {'name': 'No devices found', 'status': ''}
          ]
        : devices;
  });
}


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bluetooth',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Paired Devices",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              ElevatedButton(
                onPressed: fetchPairedDevicesWindows,
                child: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          pairedDevices.isNotEmpty
              ? ListView.builder(
                  shrinkWrap: true,
                  itemCount: pairedDevices.length,
                  itemBuilder: (context, index) {
                    final device = pairedDevices[index];
                    return ListTile(
                      title: Text(
                        device['name']!,
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: Text(
                        device['status']!,
                        style: TextStyle(
                          color: device['status'] == 'Connected'
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                )
              : const Text(
                  "No paired devices found.",
                  style: TextStyle(color: Colors.white70),
                ),
        ],
      ),
    );
  }
}
