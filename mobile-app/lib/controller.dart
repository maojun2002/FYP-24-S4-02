import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class Controller extends StatefulWidget {
  const Controller({super.key});

  @override
  State<Controller> createState() => _ControllerState();
}

class _ControllerState extends State<Controller> {
  Offset _joystickLeftOffset = Offset.zero;
  Offset _joystickRightOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    // Force horizontal orientation and fullscreen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Reset to default orientation and UI mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  // Simulate sending ESC key command via Bluetooth
  void sendEscKeyCommand() {
    //ESC commands
  }

  // Show exit confirmation dialog
  Future<bool> _showExitConfirmationDialog() async {
    bool? exitApp =  await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm Exit'),
              content: const Text('Are you sure you want to exit the controller?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false); // Stay on the page
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true); // Exit the page
                  },
                  child: const Text('Exit'),
                ),
              ],
            );
          },
        ) ;
        return exitApp ?? false; // Default to false if dialog is dismissed
  }

  void _updateJoystickLeft(DragUpdateDetails details) {
    setState(() {
      _joystickLeftOffset = Offset(
        (_joystickLeftOffset.dx + details.delta.dx).clamp(-40.0, 40.0),
        (_joystickLeftOffset.dy + details.delta.dy).clamp(-40.0, 40.0),
      );
    });
  }

  void _updateJoystickRight(DragUpdateDetails details) {
    setState(() {
      _joystickRightOffset = Offset(
        (_joystickRightOffset.dx + details.delta.dx).clamp(-40.0, 40.0),
        (_joystickRightOffset.dy + details.delta.dy).clamp(-40.0, 40.0),
      );
    });
  }

  void _resetJoystickLeft(DragEndDetails details) {
    setState(() {
      _joystickLeftOffset = Offset.zero;
    });
  }

  void _resetJoystickRight(DragEndDetails details) {
    setState(() {
      _joystickRightOffset = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _showExitConfirmationDialog, // Intercept back navigation
      child: Scaffold(
        backgroundColor: Colors.deepPurple,
        body: Stack(
          children: [
            // Home button at the top center
            Positioned(
              top: 20,
              left: MediaQuery.of(context).size.width / 2 - 35, // Center horizontally
              child: GestureDetector(
                onTap: () {
                  sendEscKeyCommand(); // Trigger ESC command
                },
                child: Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 3), // Circular outline
                  ),
                  child: const Icon(Icons.home, size: 30, color: Colors.black),
                ),
              ),
            ),

            // Left-side ZL and L buttons
            Positioned(
              top: 20,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 150,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text(
                        'ZL',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 100,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text(
                        'L',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Right-side ZR and R buttons
            Positioned(
              top: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 150,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text(
                        'ZR',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 100,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text(
                        'R',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Left joystick
            Positioned(
              left: 90,
              bottom: 35,
              child: GestureDetector(
                onPanUpdate: _updateJoystickLeft,
                onPanEnd: _resetJoystickLeft,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[600],
                      ),
                    ),
                    Transform.translate(
                      offset: _joystickLeftOffset,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Right joystick
            Positioned(
              right: 90,
              bottom: 35,
              child: GestureDetector(
                onPanUpdate: _updateJoystickRight,
                onPanEnd: _resetJoystickRight,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[600],
                      ),
                    ),
                    Transform.translate(
                      offset: _joystickRightOffset,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // D-Pad
            Positioned(
              left: 200,
              bottom: 115,
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_drop_up, color: Colors.white, size: 30),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_left, color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 20),
                      Container(
                        width: 40,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_right, color: Colors.white, size: 30),
                      ),
                    ],
                  ),
                  Container(
                    width: 80,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 30),
                  ),
                ],
              ),
            ),

            // AXYB buttons
            Positioned(
              right: 190,
              bottom: 115,
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      backgroundColor: Colors.grey[700]!,
                      padding: const EdgeInsets.all(20),
                    ),
                    child: const Text('X', style: TextStyle(color: Colors.white)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          backgroundColor: Colors.grey[700]!,
                          padding: const EdgeInsets.all(20),
                        ),
                        child: const Text('Y', style: TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(width: 55), // Increased the width between two button
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          backgroundColor: Colors.grey[700]!,
                          padding: const EdgeInsets.all(20),
                        ),
                        child: const Text('A', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      backgroundColor: Colors.grey[700]!,
                      padding: const EdgeInsets.all(20),
                    ),
                    child: const Text('B', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),

            // Settings button
            Positioned(
              bottom: 10,
              left: MediaQuery.of(context).size.width / 2 - 35,
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.settings, size: 35, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}