import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'bluetooth_Manager.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:bluetooth_info/bluetooth_info.dart';
import 'package:win_ble/win_ble.dart';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';


class QRCodeManager extends StatefulWidget {
  final String playerId;

  const QRCodeManager({super.key, required this.playerId});

  @override
  QRCodeManagerState createState() => QRCodeManagerState();
}

class QRCodeManagerState extends State<QRCodeManager> {
  String _qrData = "";
  Timer? _countdownTimer;
  int _remainingSeconds = 60;


  @override
  void initState() {
    super.initState();
    _generateQRCode(widget.playerId); //playerId in QR generation
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

void _generateQRCode(String playerId) async {
  final desktopId = Platform.localHostname;
  final bluetoothAddress = await _getBluetoothAddress(); // Get desktop's Bluetooth address
  //testing
  print("Bluetooth Address: ${_getBluetoothAddress()}");
  final serviceUUID = await _getServiceUUID(); // Await the asynchronous result
  final otp = _generateOTP(playerId);
  final timestamp = DateTime.now().millisecondsSinceEpoch;

  final qrData = jsonEncode({
    "desktopId": desktopId,
    "bluetoothAddress": bluetoothAddress,
    "serviceUUID": serviceUUID,
    "playerId": playerId,
    "otp": otp,
    "timestamp": timestamp,
  });

  print("Generated QR Code Data: $qrData"); // Debug log
  setState(() {
    _qrData = qrData;
  });
}

  Future<String> _getServiceUUID() async {
    return "00001101-0000-1000-8000-00805f9b34fb"; // Serial Port Profile (SPP) UUID
  }


   Future<String> _getBluetoothAddress() async {
    try {
      final address = await BluetoothManager.getDeviceAddress();
      print("Bluetooth Address: $address");
      return address; // Return address directly since it's non-null
    } catch (e) {
      print("Failed to retrieve Bluetooth Address: $e");
      return "Unknown"; // Return "Unknown" if an exception occurs
    }
  }

  String _generateOTP(String playerId) {
    final currentTime = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 600000;
    final data = "$currentTime-$playerId";
    return (data.hashCode % 1000000).toString().padLeft(6, '0');
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _remainingSeconds = 60;
          _generateQRCode(widget.playerId); // Regenerate QR Code
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        QrImageView(
          data: _qrData,
          version: QrVersions.auto,
          size: 200.0,
          backgroundColor: Colors.white, 
        ),
        const SizedBox(height: 16),
        Text(
          'Time remaining: $_remainingSeconds seconds',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ],
    );
  }
}
