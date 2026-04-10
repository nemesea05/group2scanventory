import 'package:flutter/material.dart';

// Import your screens
import 'splash_screen.dart'; // Added the Splash Screen
import 'inventory_screen.dart';
import 'register_screen.dart';
import 'analytics_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

void main() {
  runApp(const Group2InventoryApp());
}

class Group2InventoryApp extends StatelessWidget {
  const Group2InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScanVentory',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blueAccent,
      ),
      // The app now starts with the Splash Screen
      home: const SplashScreen(),
    );
  }
}

class MainNavigationHolder extends StatefulWidget {
  const MainNavigationHolder({super.key});

  @override
  State<MainNavigationHolder> createState() => _MainNavigationHolderState();
}

class _MainNavigationHolderState extends State<MainNavigationHolder> {
  int _selectedIndex = 0;

  // Pages controlled by the BottomNavigationBar
  final List<Widget> _pages = [
    const InventoryScreen(),
    const RegisterScreen(),
    const AnalyticsScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack preserves the state of each page when switching tabs
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold, 
          fontSize: 12
        ),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt), 
            label: 'Inventory'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined), 
            label: 'Register'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined), 
            label: 'Analytics'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline), 
            label: 'Profile'
          ),
        ],
      ),
    );
  }
}