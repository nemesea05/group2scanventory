import 'package:flutter/material.dart';

enum StockStatus { inStock, lowStock, outOfStock }

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventory", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search items, barcode, or supplier...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _buildInventoryCard(
                  name: "Mama Sita's Oyster Sauce 500ml",
                  barcode: "#123456789012",
                  quantity: 25,
                  price: 5.00,
                  category: "Sauce",
                  status: StockStatus.inStock,
                ),
                _buildInventoryCard(
                  name: "All Purpose Cream Tetra",
                  barcode: "#987654321098",
                  quantity: 8,
                  price: 2.00,
                  category: "Sauce",
                  status: StockStatus.lowStock,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryCard({
    required String name,
    required String barcode,
    required int quantity,
    required double price,
    required String category,
    required StockStatus status,
  }) {
    Color statusColor = status == StockStatus.inStock ? Colors.green : Colors.orange;
    String statusText = status == StockStatus.inStock ? "In Stock" : "Low Stock";

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            Text(barcode, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _metric("Quantity", "$quantity"),
                _metric("Unit Price", "\$${price.toStringAsFixed(2)}"),
                _metric("Category", category),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}