import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getInitials(String? displayName, String? email) {
    if (displayName != null && displayName.trim().isNotEmpty) {
      final parts = displayName.trim().split(RegExp(r'\s+'));
      if (parts.length == 1) {
        return parts.first.substring(0, 1).toUpperCase();
      }
      return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
          .toUpperCase();
    }

    if (email != null && email.isNotEmpty) {
      return email.substring(0, 1).toUpperCase();
    }

    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('inventory').snapshots(),
        builder: (context, inventorySnapshot) {
          if (inventorySnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (inventorySnapshot.hasError) {
            return Center(
              child: Text('Error: ${inventorySnapshot.error}'),
            );
          }

          final inventoryDocs = inventorySnapshot.data?.docs ?? [];

          int totalItemsManaged = inventoryDocs.length;
          double totalInventoryValue = 0;
          final Map<String, int> categoryCounts = {};

          for (final doc in inventoryDocs) {
            final data = doc.data() as Map<String, dynamic>;
            final int quantity = (data['quantity'] ?? 0) as int;
            final double unitPrice = (data['unitPrice'] ?? 0).toDouble();
            final String category =
                (data['category'] ?? 'Uncategorized').toString();

            totalInventoryValue += quantity * unitPrice;
            categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('inventory_logs')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, logsSnapshot) {
              if (logsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (logsSnapshot.hasError) {
                return Center(
                  child: Text('Error: ${logsSnapshot.error}'),
                );
              }

              final logsDocs = logsSnapshot.data?.docs ?? [];

              int itemsAddedToday = 0;
              int totalActivities = logsDocs.length;
              final DateTime now = DateTime.now();

              for (final doc in logsDocs) {
                final data = doc.data() as Map<String, dynamic>;
                final String action = (data['action'] ?? '').toString();
                final Timestamp? timestamp = data['timestamp'] as Timestamp?;

                if (action == 'register' && timestamp != null) {
                  final DateTime logDate = timestamp.toDate();
                  if (_isSameDate(logDate, now)) {
                    itemsAddedToday++;
                  }
                }
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildUserCard(user),
                    const SizedBox(height: 24),
                    _buildStatsSection(
                      itemsAddedToday: itemsAddedToday,
                      totalItemsManaged: totalItemsManaged,
                      totalCategories: categoryCounts.length,
                      totalInventoryValue: totalInventoryValue,
                      totalActivities: totalActivities,
                    ),
                    const SizedBox(height: 24),
                    _buildCategoryBreakdown(categoryCounts),
                    const SizedBox(height: 32),
                    _buildSystemOverview(totalActivities, totalItemsManaged, user),
                    const SizedBox(height: 32),
                    _buildAccountActions(context),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildUserCard(User? user) {
    final displayName =
        (user?.displayName != null && user!.displayName!.trim().isNotEmpty)
            ? user.displayName!
            : 'Unnamed User';

    final email = user?.email ?? 'No email';
    final initials = _getInitials(user?.displayName, user?.email);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blueAccent,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  email,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 6),
                Chip(
                  label: Text(
                    user != null ? 'Authenticated User' : 'Guest',
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                  backgroundColor: Colors.black,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection({
    required int itemsAddedToday,
    required int totalItemsManaged,
    required int totalCategories,
    required double totalInventoryValue,
    required int totalActivities,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Your Statistics",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        _statRow("Items Added Today", itemsAddedToday.toString()),
        _statRow("Total Items Managed", totalItemsManaged.toString()),
        _statRow("Categories", totalCategories.toString()),
        _statRow("Recent Activity Records", totalActivities.toString()),
        _statRow(
          "Total Inventory Value",
          "₱${totalInventoryValue.toStringAsFixed(2)}",
          isBold: true,
        ),
      ],
    );
  }

  Widget _buildSystemOverview(
    int totalActivities,
    int totalItemsManaged,
    User? user,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey[50],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "System Overview",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _statRow("Inventory Records", totalItemsManaged.toString()),
          _statRow("Logged Activities", totalActivities.toString()),
          _statRow("User ID", user?.uid ?? 'No UID'),
        ],
      ),
    );
  }

  Widget _buildAccountActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Account Actions",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text(
              "Sign Out",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              side: const BorderSide(color: Colors.redAccent),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown(Map<String, int> categoryCounts) {
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
          const Text(
            "Category Breakdown",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (categoryCounts.isEmpty)
            const Text("No categories available yet.")
          else
            ...categoryCounts.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _statRow(entry.key, entry.value.toString()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}