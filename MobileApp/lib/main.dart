import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'home.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mob Control',
      // Disable the 'debug' tag
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

class _RootPageState extends State<RootPage> with TickerProviderStateMixin  {
  double _offsetX = 0.0; // Horizontal offset for image
  double _offsetY = 0.0; // Vertical offset for image

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Controller and animation for the breathing (pulsating) effect on "Tap to Enter"
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller for picture and animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Start the initial scale animation after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });

  // Breathing animation for "Tap to Enter" and picture after the animation come out
    _breathingController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _breathingAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _breathingController,
        curve: Curves.easeInOut,
      ),
    );

  // Listen to accelerometer events for tilting the image
    accelerometerEvents.listen((AccelerometerEvent event) {
      setState(() {
        _offsetX = event.x * 2.5; // Adjust horizontal movement sensitivity
        _offsetY = event.y * 2.5; // Adjust vertical movement sensitivity
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _breathingController.dispose();
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
      body: GestureDetector(
        onTap: () => _navigateToNextPage(context),
        child: Stack(
        children: [
          // Background Color
          Container(
            color: Colors.black, // Background color to match the theme
          ),
          // Background Image with Tilt and Scale Animation
          Positioned.fill(
            child: Transform.translate(
              offset: Offset(_offsetX, _offsetY),
              child: AnimatedBuilder(
                animation: Listenable.merge([_scaleAnimation, _breathingAnimation]),
                builder: (context, child) {
                  // If initial scale animation is completed, apply breathing effect
                  final scale = _animationController.isCompleted
                      ? (1.5 * _breathingAnimation.value)
                      : _scaleAnimation.value;

                  return Transform.scale(
                    scale: scale,
                    child: Image.asset(
                      'images/controllerHomeImg.jpg',
                      fit: BoxFit.contain,
                    ),
                  );
                },
              ),
            ),
          ),

          // Centered Title
          Positioned(
            top: 125.0,
            left: 0,
            right: 0,
            child: Text(
              'Mob Control',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
                shadows: [
                  Shadow(
                    offset: const Offset(3.0, 3.0),
                    blurRadius: 4.0,
                    color: Colors.purple.withOpacity(0.7),
                  ),
                ],
              ),
            ),
          ),

          // "Tap to Enter" with breathing animation
          Positioned(
            bottom: 50.0,
            left: 20.0,
            right: 20.0,
            child: AnimatedBuilder(
              animation: _breathingAnimation,
              builder: (context, child) {
                return Text(
                  'Tap to Enter',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: _breathingAnimation.value * 24, // Animate font size with breathing
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: const Offset(1.0, 1.0),
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

