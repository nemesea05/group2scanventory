import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  String _formatAction(String action, int qty) {
    switch (action) {
      case 'register':
        return 'Registered item (+$qty)';
      case 'stock_in':
        return 'Stock In (+$qty)';
      case 'stock_out':
        return 'Stock Out (-$qty)';
      case 'edit_quantity':
        return 'Edit Quantity ($qty)';
      case 'edit_item':
        return 'Edited item details';
      case 'delete':
        return 'Deleted item';
      default:
        return action;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'register':
        return Icons.add_box_outlined;
      case 'stock_in':
        return Icons.add_circle_outline;
      case 'stock_out':
        return Icons.remove_circle_outline;
      case 'edit_quantity':
        return Icons.edit_note;
      case 'edit_item':
        return Icons.edit;
      case 'delete':
        return Icons.delete_outline;
      default:
        return Icons.history;
    }
  }

  String _formatActor(String displayName, String email) {
    if (displayName.trim().isNotEmpty) {
      return displayName;
    }
    if (email.trim().isNotEmpty) {
      return email;
    }
    return 'Unknown User';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recent Activity"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('inventory_logs')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final logs = snapshot.data?.docs ?? [];

          if (logs.isEmpty) {
            return const Center(
              child: Text("No activity yet."),
            );
          }

          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final data = logs[index].data() as Map<String, dynamic>;

              final String itemName = data['itemName'] ?? 'Unknown Item';
              final String action = data['action'] ?? '';
              final int qty = data['quantityChanged'] ?? 0;
              final String userDisplayName = data['userDisplayName'] ?? '';
              final String userEmail = data['userEmail'] ?? '';
              final Timestamp? timestamp = data['timestamp'] as Timestamp?;

              final String formattedDate = timestamp != null
                  ? DateFormat('MMM dd, yyyy • hh:mm a').format(timestamp.toDate())
                  : 'No date';

              return ListTile(
                leading: Icon(_getActionIcon(action)),
                title: Text(itemName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_formatAction(action, qty)),
                    Text(
                      'By: ${_formatActor(userDisplayName, userEmail)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                trailing: Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.right,
                ),
                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }
}