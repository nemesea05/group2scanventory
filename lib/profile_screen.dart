import 'package:flutter/material.dart';

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
            // User Profile Card [cite: 3, 22]
            _buildUserCard(),
            const SizedBox(height: 24),
            
            // Statistics Section [cite: 4]
            _buildStatsSection(),
            const SizedBox(height: 24),
            
            // Category Breakdown [cite: 13]
            _buildCategoryBreakdown(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard() {
    return InkWell(
      onTap: () => print("Open User Settings"), // Placeholder for [cite: 22]
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
              child: Text("IM"), // 
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Inventory Manager", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text("inventory@company.com", style: TextStyle(color: Colors.grey[600])),
                const Chip(label: Text("Admin", style: TextStyle(fontSize: 12))),
              ],
            )
          ],
        ),
      ),
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