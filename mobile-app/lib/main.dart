import 'package:flutter/material.dart';
import 'package:fyp_desktop_app/setting_page.dart';
import 'package:fyp_desktop_app/connection_page.dart';

// Entry point of the Flutter app
void main() {
  runApp(MyApp());
}

// Root widget of the application
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E2E),
        primaryColor: const Color(0xFF4E46E4),
      ),
      home: MyHomePage(),
    );
  }
}

// Main of the application------------------------------------------------------
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _selectedItem = 'Connection';

  // Define the pages for each sidebar item
  final Map<String, Widget> _pages = {
    'Connection': const ConnectionPage(), // Replace with your ConnectionPage
    'Settings': const SettingsPage(),

  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar Section
          SizedBox(
            width: 250, // Sidebar width must be finite
            child: Container(
              color: const Color.fromARGB(255, 13, 13, 23),
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Mob Control',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4E46E4),
                      ),
                    ),
                  ),
                  SidebarItem(
                    title: 'Connection',
                    selected: _selectedItem == 'Connection',
                    onTap: () {
                      setState(() => _selectedItem = 'Connection');
                    },
                  ),
                  SidebarItem(
                    title: 'Settings',
                    selected: _selectedItem == 'Settings',
                    onTap: () {
                      setState(() => _selectedItem = 'Settings');
                    },
                  ),
                ],
              ),
            ),
          ),
          // Main Content Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                color: const Color(0xFF1E1E2E), // Ensure background is visible
                child: _pages[_selectedItem] ?? const Text('Page not found'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Sidebar Item Widget--------------------------------------------------------------------------
class SidebarItem extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const SidebarItem({
    super.key,
    required this.title,
    this.selected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Container(
          decoration: selected
              ? BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            title: Text(
              title,
              style: TextStyle(
                color: selected ? const Color(0xFF4E46E4) : Colors.white,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
