import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'bluetooth_manager.dart'; // link bluetooth
import 'dart:convert'; // For JSON decoding

class QRScanPage extends StatefulWidget {
  const QRScanPage({super.key});

  @override
  State<QRScanPage> createState() => _QRScanPageState();
}

final BluetoothManager bluetoothManager = BluetoothManager(); // 创建 BluetoothManager 实例

class _QRScanPageState extends State<QRScanPage> {
  String? result; // Holds the result of the QR code scan
  String message = ""; // Status message for user feedback
  Map<String, dynamic>? parsedData; // Store parsed QR data

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Set background color to black
      body: Stack(
        children: [
          // QR Scanner widget that works in the transparent area
          MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final qrValue = barcode.rawValue;
                if (qrValue != null) {
                  setState(() {
                    result = qrValue;
                    message = "QR Code scanned successfully! Connecting to device...";
                  });

                  // Parse QR data and initiate Bluetooth connection
                  final parsedData = _parseQRCodeData(qrValue);
                  if (parsedData != null) {
                    final bluetoothAddress = parsedData['bluetoothAddress'];
                    final otp = parsedData['otp'];
                    if (bluetoothAddress != null && otp != null) {
                      // call BluetoothManager to build connection
                      bluetoothManager.connectToDevice(bluetoothAddress, otp);
                    } else {
                      setState(() {
                        message = "Invalid QR data: Missing Bluetooth info.";
                      });
                    }
                  }

                  Navigator.pop(context, qrValue);
                  break; // Exit loop after processing one barcode
                }
              }
            },
          ),
          // Overlay with transparent area for scanning
          _buildScannerOverlay(context),
          // Instructions and icons displayed above the scan box
          const Positioned(
            top: 100, // Distance from the top
            left: 0,
            right: 0,
            child: Column(
              children: [
                Icon(
                  Icons.qr_code_scanner,
                  size: 60,
                  color: Colors.blue,
                ),
                SizedBox(height: 10),
                Text(
                  'Scan QR Code',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // Display feedback message at the bottom
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? _parseQRCodeData(String qrData) {
    try {
      final data = jsonDecode(qrData);
      print("Parsed QR Code data: $data");
      return data;
    } catch (e) {
      print("Failed to parse QR code data: $e");
      return null;
    }
  }

  Future<void> _connectToBluetooth(String bluetoothAddress, String otp) async {
    try {
      setState(() {
        message = "Connecting to Bluetooth device...";
      });
      await bluetoothManager.connectToDevice(bluetoothAddress, otp);
      setState(() {
        message = "Connected and OTP verified successfully!";
      });
    } catch (e) {
      setState(() {
        message = "Failed to connect: $e";
      });
    }
  }

  // Builds a scanner overlay with a transparent scan box and transparent outer box size for a better view
  Widget _buildScannerOverlay(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Scanning box size
        const double scanBoxSize = 250.0;

        // Screen width
        final double screenWidth = constraints.maxWidth;

        // Screen height
        final double screenHeight = constraints.maxHeight;

        return Stack(
          children: [
            // Black overlay covering the entire screen
            Positioned.fill(
              child: Container(
                color: Colors.transparent, // Semi-transparent black
              ),
            ),
            // Clear rectangular area for scanning
            Positioned(
              top: (screenHeight - scanBoxSize) / 2,
              left: (screenWidth - scanBoxSize) / 2,
              width: scanBoxSize,
              height: scanBoxSize,
              child: CustomPaint(
                painter: _ScannerCornersPainter(),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Custom painter to draw corner lines for the scanner box
class _ScannerCornersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double cornerLength = 30.0;

    // Top-left corner
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLength, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLength), paint);

    // Top-right corner
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - cornerLength, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLength), paint);

    // Bottom-left corner
    canvas.drawLine(Offset(0, size.height), Offset(cornerLength, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - cornerLength), paint);

    // Bottom-right corner
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width - cornerLength, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width, size.height - cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
