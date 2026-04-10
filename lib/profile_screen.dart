import 'package:flutter/material.dart';
import 'login_screen.dart'; // Import to navigate back to login

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildUserCard(),
            const SizedBox(height: 24),
            _buildStatsSection(),
            const SizedBox(height: 24),
            _buildCategoryBreakdown(),
            const SizedBox(height: 32), // Space before logout
            
            // --- NEW LOGOUT SECTION ---
            _buildAccountActions(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard() {
    return InkWell(
      onTap: () => print("Open User Settings"),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blueAccent,
              child: Text("AD", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("System Admin", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text("admin@scanventory.com", style: TextStyle(color: Colors.grey[600])),
                const Chip(
                  label: Text("Administrator", style: TextStyle(fontSize: 10, color: Colors.white)),
                  backgroundColor: Colors.black,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // New Helper Method for the Logout Button
  Widget _buildAccountActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Account Actions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // Clears all previous routes so user can't press "back" to return to app
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text("Logout Session", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              side: const BorderSide(color: Colors.redAccent),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Your Statistics", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        _statRow("Items Added Today", "0"),
        _statRow("Total Items Managed", "3"),
        _statRow("Categories", "2"),
        _statRow("Total Inventory Value", "\$6590.50", isBold: true),
      ],
    );
  }

  Widget _statRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black87)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Category Breakdown", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _statRow("Sauce", "2"),
          _statRow("Seasoning", "1"),
        ],
      ),
    );
  }
}