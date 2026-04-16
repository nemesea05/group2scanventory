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

  String _formatActor(String? name, String? email) {
    final safeName = (name ?? '').trim();
    final safeEmail = (email ?? '').trim();

    if (safeName.isNotEmpty) return safeName;
    if (safeEmail.isNotEmpty) return safeEmail;
    return 'Unknown Admin';
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    return timestamp.toDate().toString();
  }

  Future<void> exportInventoryReport() async {
    final inventorySnapshot = await FirebaseFirestore.instance
        .collection('inventory')
        .orderBy('createdAt', descending: true)
        .get();

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
      'Created By',
      'Created By Email',
      'Last Updated By',
      'Last Updated By Email',
      'Last Updated At',
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
      final Timestamp? lastUpdatedAtTimestamp =
          data['lastUpdatedAt'] as Timestamp?;

      final String createdByName = (data['createdByName'] ?? '').toString();
      final String createdByEmail = (data['createdByEmail'] ?? '').toString();
      final String lastUpdatedByName =
          (data['lastUpdatedByName'] ?? '').toString();
      final String lastUpdatedByEmail =
          (data['lastUpdatedByEmail'] ?? '').toString();

      rows.add([
        name,
        barcode.isEmpty ? 'No barcode' : barcode,
        category,
        quantity,
        unitPrice.toStringAsFixed(2),
        supplier.isEmpty ? 'N/A' : supplier,
        _getStockStatus(quantity),
        _formatTimestamp(createdAtTimestamp),
        _formatActor(createdByName, createdByEmail),
        createdByEmail.isEmpty ? 'N/A' : createdByEmail,
        _formatActor(lastUpdatedByName, lastUpdatedByEmail),
        lastUpdatedByEmail.isEmpty ? 'N/A' : lastUpdatedByEmail,
        _formatTimestamp(lastUpdatedAtTimestamp),
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

  Future<void> exportActivityLogsReport() async {
    final logsSnapshot = await FirebaseFirestore.instance
        .collection('inventory_logs')
        .orderBy('timestamp', descending: true)
        .get();

    final List<List<dynamic>> rows = [];

    rows.add([
      'Item Name',
      'Action',
      'Quantity Changed',
      'Performed By',
      'Email',
      'Timestamp',
    ]);

    for (final doc in logsSnapshot.docs) {
      final data = doc.data();

      final String itemName = (data['itemName'] ?? '').toString();
      final String action = (data['action'] ?? '').toString();
      final int quantityChanged = (data['quantityChanged'] ?? 0) as int;
      final String userName = (data['userDisplayName'] ?? '').toString();
      final String userEmail = (data['userEmail'] ?? '').toString();
      final Timestamp? timestamp = data['timestamp'] as Timestamp?;

      rows.add([
        itemName,
        action,
        quantityChanged,
        userName.isEmpty ? 'Unknown Admin' : userName,
        userEmail.isEmpty ? 'N/A' : userEmail,
        timestamp != null ? timestamp.toDate().toString() : 'N/A',
      ]);
    }

    final String csvData = const CsvEncoder().convert(rows);
    final String fileName =
        'activity_logs_${DateTime.now().toIso8601String().replaceAll(':', '-')}.csv';

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
        text: 'Activity Logs Report',
        subject: 'Activity Logs Report',
      ),
    );
  }
}