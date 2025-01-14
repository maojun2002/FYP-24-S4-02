
/*
import 'package:flutter/material.dart';
import 'package:fyp_desktop_app/OTPManager.dart';
import 'package:fyp_desktop_app/QRCodeManager.dart';
import 'package:win32/win32.dart';
import 'dart:ffi';
import 'package:url_launcher/url_launcher.dart'; // use to direct user to desktop app setting
import 'dart:async';
import 'dart:io'; // Use for getting host name/uuid
import 'dart:convert';
import 'package:ffi/ffi.dart'; // For calloc memory management
import 'package:qr_flutter/qr_flutter.dart';


class ConnectionPage extends StatefulWidget {
  const ConnectionPage({super.key});

  @override
  ConnectionPageState createState() => ConnectionPageState();
}

class ConnectionPageState extends State<ConnectionPage> {
  bool _bluetoothEnabled = false; // Track Bluetooth status
  Timer? _bluetoothStatusTimer; // For periodic Bluetooth status checks
  Timer? _countdownTimer; // For countdown display
  int _remainingSeconds = 0; // Countdown duration in seconds
  bool _showQRPage = true;
  String _qrData = ""; // Initialize to store the QR code data
 


  @override
  void initState() {
    super.initState();
    _initializeBluetooth(); // Check Bluetooth status when the app starts
    _startBluetoothStatusTimer(); // Set up periodic listener
  }

  @override
  void dispose() {
    _bluetoothStatusTimer?.cancel(); // Cancel subscription when widget is disposed
    _countdownTimer?.cancel(); // Cancel countdown timer
    super.dispose();
  }

Future<void> _initializeBluetooth() async {
    try {
      // FOrce wake up software
      final activated = _forceActivateBluetoothHardware();
      if (activated) {
        await Future.delayed(const Duration(seconds: 1)); // let bluetooth service booth
        _checkBluetoothState(); // check bluetooth status
      } else {
        print("Failed to activate Bluetooth hardware.");
      }
    } catch (e) {
      print("Failed to initialize Bluetooth: $e");
    }
  }


  bool _forceActivateBluetoothHardware() {
    final pRadio = calloc<HANDLE>();
    final result = BluetoothFindFirstRadio(nullptr, pRadio);

    if (result == 0) {
      print("Bluetooth hardware activated.");
      calloc.free(pRadio);
      return true;
    }

    print("Bluetooth hardware activation failed.");
    calloc.free(pRadio);
    return false;
  }


  // Periodically check the Bluetooth state
  void _startBluetoothStatusTimer() {
    _bluetoothStatusTimer =
        Timer.periodic(const Duration(seconds: 3), (_) => _checkBluetoothState());
  }


  // Checks if Bluetooth is enabled on the system using Windows APIs
  Future<void> _checkBluetoothState() async {
    try {
      final bluetoothState = _queryBluetoothStatusFromSystem();
      print("Retrieved Bluetooth state: $bluetoothState");
      setState(() {
        _bluetoothEnabled = bluetoothState;
        if (!_bluetoothEnabled){
          _resetQRState();
        }
      });
    } catch (e) {
      print("Error checking Bluetooth state: $e");
    }
  }

    void _resetQRState() {
    setState(() {
      _qrData = "";
      _remainingSeconds = 0;
      _countdownTimer?.cancel();
    });
  }

  // Query Bluetooth status using Windows APIs
  bool _queryBluetoothStatusFromSystem() {
    final pRadio = calloc<HANDLE>();
    final findRadioResult = BluetoothFindFirstRadio(nullptr, pRadio);

    if (findRadioResult == 0) { // Successfully found a Bluetooth radio
      final hRadio = pRadio.value;

      // Check if the radio is discoverable
      final discoverable = _isBluetoothDiscoverable(hRadio);
      print("Is Bluetooth discoverable? $discoverable");

      calloc.free(pRadio);
      CloseHandle(hRadio);
      return discoverable; // Return true if discoverable
    }

    print("No Bluetooth radio found.");
    calloc.free(pRadio);
    return false; // Bluetooth is not available
  }

  bool _isBluetoothDiscoverable(int  hRadio) {
    final discoverable = BluetoothIsDiscoverable(hRadio); // Pass the hRadio handle
    print("Bluetooth discoverable status: $discoverable");
    return discoverable != 0; // Return true if Bluetooth is discoverable
  }


  // Opens the Bluetooth settings in Windows
  Future<void> _openBluetoothSettings() async {
    const String url = 'ms-settings:bluetooth'; // URL for Bluetooth settings
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url)); // Open the Bluetooth settings page
    } else {
      print('Could not open Bluetooth settings page');
    }
  }

  // Handles the switch toggle logic
  void _onBluetoothSwitchChanged(bool value) {
    if (value && !_bluetoothEnabled) {
      _showEnableBluetoothDialog();
    } else {

    setState(() {
      _bluetoothEnabled = value;
      if (!_bluetoothEnabled) {
        _resetQRState();
      }
    });
  }
}

  // Displays a dialog to confirm enabling Bluetooth
  void _showEnableBluetoothDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("Enable Bluetooth"),
        content: const Text("Do you want to open Bluetooth settings?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _openBluetoothSettings();
            },
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }


 // QR connection
  String getDesktopId() {
    return Platform.localHostname; // return the name of the desktop.
  }

  // Function to generate dynamic QR Code data
  String generateQRCodeData(String playerId) {
    final desktopId = getDesktopId(); // 动态获取桌面 ID
    final otp = generateOTP(playerId); // Generate OTP for the player
    final timestamp = DateTime.now().millisecondsSinceEpoch; // Current timestamp

    // Construct the QR Code data in JSON format
    return jsonEncode({
      "desktopId": desktopId, // 动态嵌入桌面 ID
      "playerId": playerId,
      "otp": otp,
      "timestamp": timestamp
    });
  }

  // 生成动态 OTP
  String generateOTP(String playerId) {
    final currentTime = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 600000; // 1min
    final data = "$currentTime-$playerId"; // 使用时间窗口和玩家 ID 组合数据
    final otp = (data.hashCode % 1000000); // 生成 6 位 OTP
    return otp.toString().padLeft(6, '0'); // 确保前导补零
  }


void _startCountdownTimer(String playerId) {
  setState(() {
  _qrData = generateQRCodeData(playerId); // 每次生成新的 QR Code 数据
  _remainingSeconds = 60 ;
 });

  // Regenerate the QR code immediately
  _qrData = generateQRCodeData(playerId);

  // Create a periodic timer to update the countdown
  _countdownTimer?.cancel(); // Cancel any previous timer
  _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {

    setState(() {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
      } else {
        // Reset countdown and regenerate QR code
        _qrData = generateQRCodeData(playerId);
        _remainingSeconds = 60;
      }
    });
  });
}


Widget _buildQRPageWithButton(String playerId) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      ElevatedButton(
        onPressed: _bluetoothEnabled
            ? () {
                setState(() {
                  // Start generating QR Code and countdown
                  _startCountdownTimer(playerId);
                });
              }
            : null, // Disable button if Bluetooth is not enabled
        style: ElevatedButton.styleFrom(
          backgroundColor: _bluetoothEnabled
              ? Colors.blue
              : Colors.grey, // Blue if enabled, grey otherwise
        ),
        child: Text(
          _bluetoothEnabled ? 'Generate QR Code' : 'Enable Bluetooth to Proceed',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      const SizedBox(height: 16),
      // Display QR Code and countdown if the timer has started
      _qrData.isNotEmpty && _bluetoothEnabled
          ? Column(
              children: [
                QrImageView(
                  data: _qrData, // Dynamically updated QR Code data
                  version: QrVersions.auto,
                  size: 200.0,
                  foregroundColor: Colors.white,
                ),
                const SizedBox(height: 16),
                Text(
                  'Time remaining: $_remainingSeconds seconds',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            )
          : const Text(
              'Press the button to generate QR Code.',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
    ],
  );
}



  // OTP page widget
  Widget _buildOTPPage() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OTPManager(),
        Text(
          'Enter OTP to pair the device.',
          style: TextStyle(color: Colors.white70, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
        TextField(
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black54,
            hintText: 'Enter OTP',
            hintStyle: TextStyle(color: Colors.white54),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide.none,
            ),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
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
                      value: _bluetoothEnabled,
                      onChanged: _onBluetoothSwitchChanged,
                      activeColor: Colors.green,
                      inactiveThumbColor: Colors.grey,
                    ),
                    Text("Bluetooth Enabled: $_bluetoothEnabled", // 调试用
                    style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 40),
            // Player 1 with QR and OTP buttons
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Player 1',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  setState(() => _showQRPage = true);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _showQRPage
                                      ? const Color(0xFF4E46E4)
                                      : Colors.grey,
                                ),
                                child: const Text(
                                  'QR',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() => _showQRPage = false);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: !_showQRPage
                                      ? const Color(0xFF4E46E4)
                                      : Colors.grey,
                                ),
                                child: const Text(
                                  'OTP',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              color: Colors.black54,
                              child: _showQRPage ? _buildQRPageWithButton("PLAYER_1") : _buildOTPPage(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Player 2 with QR and OTP buttons
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Player 2',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  setState(() => _showQRPage = true);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _showQRPage
                                      ? const Color(0xFF4E46E4)
                                      : Colors.grey,
                                ),
                                child: const Text(
                                  'QR',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() => _showQRPage = false);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: !_showQRPage
                                      ? const Color(0xFF4E46E4)
                                      : Colors.grey,
                                ),
                                child: const Text(
                                  'OTP',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              color: Colors.black54,
                              child: _showQRPage ? _buildQRPageWithButton("PLAYER_2") : _buildOTPPage(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
*/

import 'package:flutter/material.dart';
import 'package:win32/win32.dart';
import 'dart:ffi';
import 'dart:async';
import 'package:ffi/ffi.dart'; // Import ffi package
import 'package:url_launcher/url_launcher.dart'; // For opening Bluetooth settings
import 'package:fyp_desktop_app/OTPManager.dart';
import 'package:fyp_desktop_app/QRCodeManager.dart';

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

  /// Start periodic Bluetooth status checks every 3 seconds
void _startBluetoothStatusTimer() {
  _bluetoothStatusTimer =
      Timer.periodic(const Duration(seconds: 3), (_) => _checkBluetoothState());
}

  /// Check Bluetooth status and update UI
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


  /// Show dialog to enable Bluetooth
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
                    (connected) => setState(() => _player1Connected = connected), 
                  ),
                  const SizedBox(width: 16),
                  _buildPlayerSection(
                    "Player 2",
                    _showQRPageForPlayer2,
                    _player2Connected,
                    (value) => setState(() => _showQRPageForPlayer2 = value),
                    (connected) => setState(() => _player2Connected = connected),
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
              onPressed: _bluetoothEnabled ? () => onConnect(!isConnected) : null,
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