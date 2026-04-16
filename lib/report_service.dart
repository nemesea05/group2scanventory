import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'download_csv_stub.dart'
    if (dart.library.html) 'download_csv_web.dart';

class ReportService {
  String _getStockStatus(int quantity) {
    if (quantity <= 0) {
      return 'Out of Stock';
    } else if (quantity <= 10) {
      return 'Low Stock';
    } else {
      return 'In Stock';
    }
  }

  String _formatAction(String action) {
    switch (action) {
      case 'stock_in':
        return 'Stock In';
      case 'stock_out':
        return 'Stock Out';
      case 'edit_quantity':
        return 'Edit Quantity';
      case 'edit_item':
        return 'Edit Item';
      case 'delete':
        return 'Delete Item';
      default:
        return 'No Activity';
    }
  }

  Future<void> exportInventoryReport() async {
    final inventorySnapshot = await FirebaseFirestore.instance
        .collection('inventory')
        .orderBy('createdAt', descending: true)
        .get();

    final logsSnapshot = await FirebaseFirestore.instance
        .collection('inventory_logs')
        .orderBy('timestamp', descending: true)
        .get();

    final Map<String, String> latestActivityByItem = {};

    for (final doc in logsSnapshot.docs) {
      final data = doc.data();
      final String itemName = (data['itemName'] ?? '').toString();
      final String action = (data['action'] ?? '').toString();

      if (itemName.isNotEmpty && !latestActivityByItem.containsKey(itemName)) {
        latestActivityByItem[itemName] = _formatAction(action);
      }
    }

    final List<List<dynamic>> rows = [];

    rows.add([
      'Item Name',
      'Barcode',
      'Category',
      'Quantity',
      'Unit Price',
      'Supplier',
      'Status',
      'Created At',
      'Last Activity',
    ]);

    for (final doc in inventorySnapshot.docs) {
      final data = doc.data();

      final String name = (data['name'] ?? '').toString();
      final String barcode = (data['barcode'] ?? '').toString();
      final String category = (data['category'] ?? '').toString();
      final int quantity = (data['quantity'] ?? 0) as int;
      final double unitPrice = (data['unitPrice'] ?? 0).toDouble();
      final String supplier = (data['supplier'] ?? '').toString();
      final Timestamp? createdAtTimestamp = data['createdAt'] as Timestamp?;
      final String createdAt = createdAtTimestamp != null
          ? createdAtTimestamp.toDate().toString()
          : '';

      final String lastActivity =
          latestActivityByItem[name] ?? 'No Activity';

      rows.add([
        name,
        barcode.isEmpty ? 'No barcode' : barcode,
        category,
        quantity,
        unitPrice.toStringAsFixed(2),
        supplier.isEmpty ? 'N/A' : supplier,
        _getStockStatus(quantity),
        createdAt,
        lastActivity,
      ]);
    }

    final String csvData = const CsvEncoder().convert(rows);
    final String fileName =
        'inventory_report_${DateTime.now().toIso8601String().replaceAll(':', '-')}.csv';

    if (kIsWeb) {
      downloadCsvFile(csvData, fileName);
      return;
    }

    final Directory directory = await getApplicationDocumentsDirectory();
    final String path = '${directory.path}/$fileName';

    final File file = File(path);
    await file.writeAsString(csvData);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path)],
        text: 'Inventory Report',
        subject: 'Inventory Report',
      ),
    );
  }
}