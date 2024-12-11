import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mob Control',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(),
      home: const RootPage(),
    );
  }
}

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  double _offsetX = 0.0; // Horizontal offset for image
  double _angleX = 0.0; // Angle offset for tilt effect

  @override
  void initState() {
    super.initState();
    // ignore: deprecated_member_use
    accelerometerEvents.listen((AccelerometerEvent event) {
      setState(() {
        _angleX = event.x * 5; // Adjust sensitivity by scaling factor
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onHorizontalDragUpdate: (details) {
          setState(() {
            _offsetX += details.delta.dx; // Update horizontal offset based on drag
          });
        },
        child: Stack(
          children: [
            // Background Image
            Positioned(
              left: _offsetX,
              child: Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // Perspective effect
                  ..rotateY(_angleX * 0.01), // Rotate based on tilt angle
                alignment: Alignment.center,
                child: Image.asset(
                  'images/alerchino.png', // Replace with your image asset path
                  fit: BoxFit.contain, // Adjust to contain the image without white borders
                  width: MediaQuery.of(context).size.width * 1.3, // Slightly smaller than full width
                  height: MediaQuery.of(context).size.height * 0.8, // Slightly smaller than full height
                ),
              ),
            ),
            // Centered Text
            Positioned(
              top: 100.0,
              left: 0,
              right: 0,
              child: Text(
                'Mob Control',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(2.0, 2.0),
                      blurRadius: 3.0,
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
