import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:app_settings/app_settings.dart'; 
import 'controller.dart';
import 'qr_scan_page.dart';
import 'custom_theme_switch.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isBluetoothEnabled = false;
  bool _isDark = false; 
  bool _isExpandedController = false;
  bool _isExpandedBluetooth = false;


  @override
  void initState() {
    super.initState();
    _checkBluetoothState();
    _initializeTheme();
  }

  void _initializeTheme() {
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isDark = brightness == Brightness.dark;
      });
    });
  }

  // Check Bluetooth State
  Future<void> _checkBluetoothState() async {
    // get the current bluetooth status
    final state = await FlutterBluePlus.adapterState.first;
    setState(() {
      isBluetoothEnabled = state == BluetoothAdapterState.on;
    });

    // view bluetooth status has change or not
    FlutterBluePlus.adapterState.listen((event) {
      setState(() {
        isBluetoothEnabled = event == BluetoothAdapterState.on;
      });
    });
  }

  // check if the bluetooth is not open then ask user to open
  Future<void> _showBluetoothEnableDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enable Bluetooth'),
          content: const Text(
              'Bluetooth is required to use this feature. Do you want to enable Bluetooth?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _requestEnableBluetooth();
              },
              child: const Text('Enable'),
            ),
          ],
        );
      },
    );
  }

  // Request to enable bluetooth before the user can use the controller function
  Future<void> _requestEnableBluetooth() async {
    try {
      await FlutterBluePlus.turnOn();
      final state = await FlutterBluePlus.adapterState.first; // Check again the bluetooth status.
      setState(() {
        isBluetoothEnabled = state == BluetoothAdapterState.on;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to enable Bluetooth. Please enable it in system settings.'),
          ),
        );
        AppSettings.openAppSettings(type: AppSettingsType.bluetooth);
      }
    }
  }


  Future<void> _startQRScanner() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScanPage()),
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('QR Code Data: $result')),
      );
    }
  }

  // show otp pin dialog
  Future<void> _showOTPPinDialog() async {
    String pinCode = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter 6-Digit PIN'),
          content: TextField(
            maxLength: 6,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              pinCode = value;
            },
            decoration: const InputDecoration(
              hintText: 'Enter PIN',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Entered PIN: $pinCode')),
                );
              },
              child: const Text('Pair'),
            ),
          ],
        );
      },
    );
  }

  


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar with Theme Switching-----------------------------------------
      appBar: AppBar(
        title: const Text("Mob Control"),
        backgroundColor: 
            _isDark ? const Color.fromARGB(255, 31, 31, 31) : const Color.fromARGB(255, 223, 187, 187),
        titleTextStyle: TextStyle(
          color: _isDark ? Colors.white : Colors.black,
          fontSize: 25,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Body with Fixed Background
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  _isDark ? 'images/dark_background.webp' : 'images/light_background.webp',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),


        // Top bar
        SingleChildScrollView(
          child: Column(
            children: [
              // Theme Section container
               Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                      _isDark ? 'images/moon_night.jpg' : 'images/sunny.jpg',
                    ),
                    fit: BoxFit.cover, 
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Theme",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    CustomThemeSwitch(
                      isOn: _isDark,
                      onToggle: () => setState(() => _isDark = !_isDark),  
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Controller Section
              _buildSectionHeader("Controller", _isExpandedController),
              if (_isExpandedController)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text('Customize Controller Layout'),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text('Reset to Default'),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),

              // Bluetooth Section
              _buildSectionHeader("Bluetooth", _isExpandedBluetooth),
              if (_isExpandedBluetooth)
                Column(
                  children: [
                    SwitchListTile(
                      title: const Text(
                      'Enable Bluetooth',
                      style: TextStyle(fontWeight: FontWeight.bold)
                      ),

                      value: isBluetoothEnabled,
                      onChanged: (value) {
                        if (!isBluetoothEnabled) {
                          _showBluetoothEnableDialog();
                        }
                      },
                    ),
                    ElevatedButton(
                      onPressed: isBluetoothEnabled ? _startQRScanner : null,
                      child: const Text('Pair using QR Code'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: isBluetoothEnabled ? _showOTPPinDialog : null,
                      child: const Text('Pair using 6-digit PIN'),
                    ),
                  ],
                ),

                // Controller button used to connect to controller page.
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      if (isBluetoothEnabled) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Controller(),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Please enable Bluetooth before proceeding!'),
                          ),
                        );
                      }
                    },
                    child: const Text('Controller'),
                  ),
                ),               
            ],
          ),
        ),
      ],
    ),
   );
  }

  // Section Header with Expand/Collapse
  Widget _buildSectionHeader(String title, bool isExpanded) {
    return GestureDetector(
      onTap: () => setState(() {
        if (title == "Controller") {
          _isExpandedController = !_isExpandedController;
        } else {
          _isExpandedBluetooth = !_isExpandedBluetooth;
        }
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        color: _isDark ? Colors.grey[800] : Colors.grey[300],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _isDark ? Colors.white : Colors.black,
              ),
            ),
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: _isDark ? Colors.white : Colors.black,
            ),
          ],
        ),
      ),
    );
  }
}