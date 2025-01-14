import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:win32/win32.dart';
import 'dart:ffi';
import 'package:ffi/ffi.dart';

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

  void _generateQRCode(String playerId) {
    final desktopId = Platform.localHostname;
    final bluetoothAddress = _getBluetoothAddress(); // get desktop's Bluetooth address
    final serviceUUID = "00001101-0000-1000-8000-00805f9b34fb"; // Fixed Service UUID
    final otp = _generateOTP(playerId);
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    setState(() {
      _qrData = jsonEncode({
        "desktopId": desktopId, // ADDED: desktopId for identification
        "bluetoothAddress": bluetoothAddress,
        "serviceUUID": serviceUUID,
        "playerId": playerId,
        "otp": otp,
        "timestamp": timestamp,
      });
    });
  }

  String _getBluetoothAddress() {
    final pRadio = calloc<HANDLE>();
    try {
      final findRadioResult = BluetoothFindFirstRadio(nullptr, pRadio);
      if (findRadioResult == 0) {
        final hRadio = pRadio.value;
        final radioInfo = calloc<BLUETOOTH_RADIO_INFO>();
        radioInfo.ref.dwSize = sizeOf<BLUETOOTH_RADIO_INFO>();

        final result = BluetoothGetRadioInfo(hRadio, radioInfo);
        if (result == 0) {
          final address = radioInfo.ref.address;
          final bluetoothAddress = "${address.rgBytes[0].toRadixString(16).padLeft(2, '0')}:${address.rgBytes[1].toRadixString(16).padLeft(2, '0')}:${address.rgBytes[2].toRadixString(16).padLeft(2, '0')}:${address.rgBytes[3].toRadixString(16).padLeft(2, '0')}:${address.rgBytes[4].toRadixString(16).padLeft(2, '0')}:${address.rgBytes[5].toRadixString(16).padLeft(2, '0')}".toUpperCase();
          calloc.free(radioInfo);
          return bluetoothAddress;
        }
        calloc.free(radioInfo);
      }
      return "Unknown";
    } finally {
      calloc.free(pRadio);
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
