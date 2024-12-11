import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'home.dart';

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

class _RootPageState extends State<RootPage> with SingleTickerProviderStateMixin{
  double _angleX = 0.0; // Angle offset for tilt effect
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // ignore: deprecated_member_use
    gyroscopeEvents.listen((GyroscopeEvent event) {
      setState(() {
        _angleX = event.x * 5; // Adjust sensitivity by scaling factor
      });
    });

    // Animation setup
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true); // Repeats animation back and forth

    _animation = Tween<double>(begin: 1.0, end: 1.1).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

   void _navigateToNextPage(BuildContext context) {
     Navigator.of(context).push(
       MaterialPageRoute(builder: (context) => const Home()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Set the background color to black
      body: GestureDetector(
        onTap: () => _navigateToNextPage(context),
        child: Stack(
          children: [
            // Background Image with Animation
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // Perspective effect
                      ..rotateY(_angleX * 0.01) // Rotate based on tilt angle
                      ..scale(_animation.value), // Scale based on animation
                    alignment: Alignment.center,
                    child: Image.asset(
                      'images/controllerHomeImg.jpg', // Replace with your image asset path
                      fit: BoxFit.contain, // Ensures the image covers the entire screen
                      height: MediaQuery.of(context).size.height,
                    ),
                  );
                },
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

            // Bottom Text
            Positioned(
              bottom: 50.0,
              left: 20.0,
              right: 20.0,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Text(
                    'Tap to Enter',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: _animation.value * 24, // Animate the font size
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(1.0, 1.0),
                          blurRadius: 2.0,
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
