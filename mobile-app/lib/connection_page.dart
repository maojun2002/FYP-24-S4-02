import 'package:flutter/material.dart';
import 'package:win32/win32.dart';
import 'dart:ffi';
import 'dart:async';
import 'package:ffi/ffi.dart'; // Import ffi package
import 'package:url_launcher/url_launcher.dart'; // For opening Bluetooth settings
import 'bluetooth_manager.dart';
import 'OTP_Manager.dart';
import 'QRCodeManager.dart';

class ConnectionPage extends StatefulWidget {
  const ConnectionPage({super.key});

  @override
  ConnectionPageState createState() => ConnectionPageState();
}

class ConnectionPageState extends State<ConnectionPage> {
  bool _bluetoothEnabled = false; // Track Bluetooth status
  Timer? _bluetoothStatusTimer; // Periodic Bluetooth status checker
  bool _player1Connected = false; // Indicates if Player 1 is connected
  bool _player2Connected = false; // Indicates if Player 2 is connected
  bool _showQRPageForPlayer1 = true; // Indicates if Player 1 is on QR page
  bool _showQRPageForPlayer2 = true; // Indicates if Player 2 is on QR page

  @override
  void initState() {
    super.initState();
    _initializeBluetooth(); // Initialize Bluetooth when the app starts
    _startBluetoothStatusTimer(); // Start periodic Bluetooth status checks

  }

  @override
  void dispose() {
    _bluetoothStatusTimer?.cancel(); 
    super.dispose();
  }

  /// Initialize Bluetooth at app start
  Future<void> _initializeBluetooth() async {
    final activated = _forceActivateBluetoothHardware();
    if (activated) {
      _checkBluetoothState(); // Check Bluetooth status if hardware activation is successful
    } else {
      print("Failed to activate Bluetooth hardware.");
    }
  }

  /// Force activate Bluetooth hardware
  bool _forceActivateBluetoothHardware() {
    final pRadio = calloc<HANDLE>(); // Allocate memory for HANDLE
    final result = BluetoothFindFirstRadio(nullptr, pRadio); // Find Bluetooth radio
    calloc.free(pRadio);
    return result == 0; // Return true if Bluetooth radio is found
  }

  // Start periodic Bluetooth status checks every 3 seconds
  void _startBluetoothStatusTimer() {
    _bluetoothStatusTimer =
        Timer.periodic(const Duration(seconds: 3), (_) => _checkBluetoothState());
  }

  // Check Bluetooth status and update UI
  Future<void> _checkBluetoothState() async {
      try {
        final bluetoothState = _queryBluetoothStatusFromSystem();
        print("Bluetooth state: $bluetoothState"); 
        setState(() {
          _bluetoothEnabled = bluetoothState; // Update the toggle button's status

        // Reset Player connection states if Bluetooth is disabled
        if (!_bluetoothEnabled) {
          _player1Connected = false;
          _player2Connected = false;
        }
      });
    } catch (e) {
      print("Error checking Bluetooth state: $e");
    }
  }

  /// Query Bluetooth status using Windows API
  bool _queryBluetoothStatusFromSystem() {
    final pRadio = calloc<HANDLE>();
    final findRadioResult = BluetoothFindFirstRadio(nullptr, pRadio);

    if (findRadioResult == 0) { // Successfully find bluetooth status
      final hRadio = pRadio.value;

      // Check if Bluetooth is discoverable
      final isDiscoverable = BluetoothIsDiscoverable(hRadio) != 0;

      CloseHandle(hRadio); // Close the Bluetooth handle  
      calloc.free(pRadio); // Free the allocated memory
      return isDiscoverable; // Return true if Bluetooth is discoverable
    }

    // If no Bluetooth device is found
    calloc.free(pRadio);
    return false; // Bluetooth is disabled
  }


  // Show dialog to enable Bluetooth
  void _showEnableBluetoothDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("Enable Bluetooth"),
        content: const Text("Bluetooth is disabled. Do you want to open settings to enable it?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _openBluetoothSettings();
            },
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  /// Open system Bluetooth settings
  Future<void> _openBluetoothSettings() async {
    const String url = 'ms-settings:bluetooth'; // Windows Bluetooth settings
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      print('Could not open Bluetooth settings page.');
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12131B),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Controller Authentication',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    const Text(
                      'Enable Bluetooth',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: _bluetoothEnabled, // Reflect current Bluetooth status
                      onChanged: (value) {
                        if (value && !_bluetoothEnabled) {
                          _showEnableBluetoothDialog(); // If bluetooth is not open and user want to open redirect to setting
                        } else {
                          setState(() {
                            _bluetoothEnabled = value; // syncronise bluetooth status
                          });
                        }
                      },
                      activeColor: Colors.green,
                      inactiveThumbColor: Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 40),
            Expanded(
              child: Row(
                children: [
                  _buildPlayerSection(
                    "Player 1",
                    _showQRPageForPlayer1,
                    _player1Connected,
                    (value) => setState(() => _showQRPageForPlayer1 = value),
                    (connected) {
                      setState(() => _player1Connected = connected);
                      if (connected && _showQRPageForPlayer1) {
                        BluetoothManager().startListeningForConnections(
                          "targetDeviceId1", // Replace with actual ID 
                          "otp"
                        );
                      }                     
                    } 
                  ),
                  const SizedBox(width: 16),
                  _buildPlayerSection(
                    "Player 2",
                    _showQRPageForPlayer2,
                    _player2Connected,
                    (value) => setState(() => _showQRPageForPlayer2 = value),
                    (connected) {
                      setState(() => _player2Connected = connected);
                      if (connected && _showQRPageForPlayer2) {
                        BluetoothManager().startListeningForConnections(
                          "targetDeviceId2", // Replace with actual ID
                           "otp"
                        );
                      }   
                    }
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build Player Section with QR/OTP toggle
  Widget _buildPlayerSection(
      String playerName,
      bool showQR,
      bool isConnected,
      ValueChanged<bool> onToggleView,
      ValueChanged<bool> onConnect) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(12), // Rounded corners
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Player Name
            Text(
              playerName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _bluetoothEnabled ? () {
                  setState(() {
                    onConnect(!isConnected);
                  });
                }
                : null,

              style: ElevatedButton.styleFrom(
                backgroundColor: _bluetoothEnabled
                    ? (isConnected ? Colors.green : Colors.blue)
                    : Colors.grey,
              ),
              child: Text(
                isConnected ? "Connected" : "Connect",
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            if (isConnected && _bluetoothEnabled)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => onToggleView(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: showQR ? Colors.blue : Colors.grey,
                    ),
                    child: const Text('QR'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => onToggleView(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !showQR ? Colors.blue : Colors.grey,
                    ),
                    child: const Text('OTP'),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: isConnected
                    ? (showQR
                        ? QRCodeManager(playerId: playerName)
                        : const OTPManager())
                    : const Text(
                        'Please enable Bluetooth and press "Connect" to enable features.',
                        style: TextStyle(color: Colors.red, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}