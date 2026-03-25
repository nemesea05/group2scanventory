import 'package:flutter/material.dart';
// Import the new files
import 'inventory_screen.dart';
import 'register_screen.dart';
import 'analytics_screen.dart';
import 'profile_screen.dart';

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
      home: const MainNavigationHolder(),
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

  // Now pointing to the separate classes in other files
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
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Inventory'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box_outlined), label: 'Register'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), label: 'Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}