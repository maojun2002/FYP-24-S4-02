import 'package:flutter/material.dart';
import 'custom_theme_switch.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool _isDark = false;
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar----------------------------------------------------------------
      appBar: AppBar(
        title: const Text("Mob Control"),
        backgroundColor: _isDark ? Colors.black : Colors.white,
        titleTextStyle: TextStyle(
          color: _isDark ? Colors.white : Colors.black,
          fontSize: 25,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.bold,
        ),
      ),
      //----------------------------------------------------------------------

      // Body-----------------------------------------------------------------
      backgroundColor: _isDark ? Colors.black87 : Colors.white,
      body: Column(
        children: [
          // Theme Bar
          Container(
            height: 70,
            // Rectangle bar background-------------------------------------
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  _isDark ? 'images/moon_night.jpg' : 'images/sunny.jpg',
                ),
                fit: BoxFit.cover,
              ),
              border: Border(
                top: BorderSide(
                  color: _isDark
                      ? Colors.white70
                      : const Color.fromARGB(255, 69, 69, 69),
                  width: 2.0,
                ),
                bottom: BorderSide(
                  color: _isDark
                      ? Colors.white70
                      : const Color.fromARGB(255, 69, 69, 69),
                  width: 2.0,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Theme",
                  style: TextStyle(
                    color: _isDark ? Colors.white : Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(1.0, 1.0),
                        blurRadius: 5.0,
                        color: _isDark ? Colors.black54 : Colors.white,
                      ),
                    ],
                  ),
                ),
                CustomThemeSwitch(
                  isOn: _isDark,
                  onToggle: () {
                    setState(() {
                      _isDark = !_isDark;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Collapsible "Controller" bar-----------------------------------
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
              decoration: BoxDecoration(
                color: _isDark ? Colors.grey[800] : Colors.grey[300],
                border: Border(
                  bottom: BorderSide(
                      color: _isDark ? Colors.white70 : Colors.grey,
                      width: 1.0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Controller",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),

          if (_isExpanded)
            Container(
              width: MediaQuery.of(context).size.width,
              height: 200,
              color: _isDark ? Colors.grey[900] : Colors.grey[200],
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      _isDark
                          ? 'images/dark_background_image.webp'
                          : 'images/light_background_image.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: IconButton(
                      icon: Icon(Icons.settings,
                          color: _isDark ? Colors.white : Colors.black),
                      onPressed: () {
                        // Add functionality for the settings icon here
                      },
                    ),
                  ),
                  Positioned(
                    top: 64,
                    left: 16,
                    child: IconButton(
                      icon: Icon(Icons.image,
                          color: _isDark ? Colors.white : Colors.black),
                      onPressed: () {
                        // Add functionality for the picture icon here
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
