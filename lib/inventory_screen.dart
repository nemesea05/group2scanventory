import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

enum StockStatus { inStock, lowStock, outOfStock }

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'All';
  String _selectedStatus = 'All';

  final List<String> _statuses = [
    'All',
    'In Stock',
    'Low Stock',
    'Out of Stock',
  ];

  final List<String> _editCategories = [
    'Sauce',
    'Seasoning',
    'Canned Goods',
  ];

  final RegExp _nameRegex = RegExp(r"^[A-Za-z0-9\s'().,-]+$");
  final RegExp _supplierRegex = RegExp(r"^[A-Za-z0-9\s'().,-]*$");
  final RegExp _wholeNumberRegex = RegExp(r'^\d+$');
  final RegExp _decimalRegex = RegExp(r'^\d+(\.\d{1,2})?$');
  final RegExp _barcodeRegex = RegExp(r'^\d*$');

  StockStatus _getStockStatus(int quantity) {
    if (quantity <= 0) {
      return StockStatus.outOfStock;
    } else if (quantity <= 10) {
      return StockStatus.lowStock;
    } else {
      return StockStatus.inStock;
    }
  }

  String _statusToText(StockStatus status) {
    switch (status) {
      case StockStatus.inStock:
        return 'In Stock';
      case StockStatus.lowStock:
        return 'Low Stock';
      case StockStatus.outOfStock:
        return 'Out of Stock';
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
    return DateFormat('MMM dd, yyyy • hh:mm a').format(timestamp.toDate());
  }

  Future<void> _logAction({
    required String itemId,
    required String itemName,
    required String action,
    int quantityChanged = 0,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    await FirebaseFirestore.instance.collection('inventory_logs').add({
      'itemId': itemId,
      'itemName': itemName,
      'action': action,
      'quantityChanged': quantityChanged,
      'timestamp': FieldValue.serverTimestamp(),
      'userId': user?.uid ?? '',
      'userEmail': user?.email ?? '',
      'userDisplayName': user?.displayName ?? '',
    });
  }

  bool _matchesFilters(Map<String, dynamic> data) {
    final String name = (data['name'] ?? '').toString().toLowerCase();
    final String barcode = (data['barcode'] ?? '').toString().toLowerCase();
    final String supplier = (data['supplier'] ?? '').toString().toLowerCase();
    final String category = (data['category'] ?? 'Uncategorized').toString();
    final int quantity = (data['quantity'] ?? 0) as int;

    final StockStatus stockStatus = _getStockStatus(quantity);
    final String statusText = _statusToText(stockStatus);

    final String query = _searchController.text.trim().toLowerCase();

    final bool matchesSearch = query.isEmpty ||
        name.contains(query) ||
        barcode.contains(query) ||
        supplier.contains(query);

    final bool matchesCategory =
        _selectedCategory == 'All' || category == _selectedCategory;

    final bool matchesStatus =
        _selectedStatus == 'All' || statusText == _selectedStatus;

    return matchesSearch && matchesCategory && matchesStatus;
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = 'All';
      _selectedStatus = 'All';
    });
  }

  Future<void> _showQuantityDialog({
    required String docId,
    required String itemName,
    required int currentQuantity,
    required String actionType,
  }) async {
    final TextEditingController qtyController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$actionType - $itemName'),
          content: TextField(
            controller: qtyController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: actionType == 'Edit Quantity'
                  ? 'Enter new quantity'
                  : 'Enter quantity',
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final String input = qtyController.text.trim();

                if (!_wholeNumberRegex.hasMatch(input)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Quantity must be a whole number.'),
                    ),
                  );
                  return;
                }

                final int enteredQty = int.parse(input);
                int newQuantity = currentQuantity;
                final user = FirebaseAuth.instance.currentUser;

                if (actionType == 'Stock In') {
                  newQuantity = currentQuantity + enteredQty;
                } else if (actionType == 'Stock Out') {
                  newQuantity = currentQuantity - enteredQty;
                  if (newQuantity < 0) newQuantity = 0;
                } else if (actionType == 'Edit Quantity') {
                  newQuantity = enteredQty;
                }

                try {
                  await FirebaseFirestore.instance
                      .collection('inventory')
                      .doc(docId)
                      .update({
                    'quantity': newQuantity,
                    'lastUpdatedAt': FieldValue.serverTimestamp(),
                    'lastUpdatedByUid': user?.uid ?? '',
                    'lastUpdatedByEmail': user?.email ?? '',
                    'lastUpdatedByName': user?.displayName ?? '',
                  });

                  await _logAction(
                    itemId: docId,
                    itemName: itemName,
                    action: actionType.toLowerCase().replaceAll(' ', '_'),
                    quantityChanged: enteredQty,
                  );

                  if (!mounted) return;
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '$itemName updated successfully. New quantity: $newQuantity',
                      ),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update item: $e'),
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditItemDialog({
    required String docId,
    required String currentName,
    required String currentBarcode,
    required String currentCategory,
    required double currentPrice,
    required String currentSupplier,
  }) async {
    final TextEditingController nameController =
        TextEditingController(text: currentName);
    final TextEditingController barcodeController =
        TextEditingController(text: currentBarcode == 'No barcode' ? '' : currentBarcode);
    final TextEditingController priceController =
        TextEditingController(text: currentPrice.toStringAsFixed(2));
    final TextEditingController supplierController =
        TextEditingController(text: currentSupplier);

    String selectedCategory = currentCategory;

    final categoriesSnapshot = await FirebaseFirestore.instance
        .collection('categories')
        .orderBy('name')
        .get();

    final List<String> dynamicCategories = categoriesSnapshot.docs
        .map((doc) => (doc.data())['name'].toString())
        .toList();

    if (!dynamicCategories.contains(selectedCategory) &&
        dynamicCategories.isNotEmpty) {
      selectedCategory = dynamicCategories.first;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Item'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r"[A-Za-z0-9\s'().,-]"),
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Item Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: barcodeController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Barcode',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: dynamicCategories.isEmpty ? null : selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: dynamicCategories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedCategory = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Unit Price',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: supplierController,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r"[A-Za-z0-9\s'().,-]"),
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Supplier',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final String newName = nameController.text.trim();
                    final String newBarcode = barcodeController.text.trim();
                    final String priceText = priceController.text.trim();
                    final String newSupplier = supplierController.text.trim();
                    final user = FirebaseAuth.instance.currentUser;

                    if (newName.isEmpty || !_nameRegex.hasMatch(newName)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Item name must contain letters, numbers, spaces, and basic punctuation only.',
                          ),
                        ),
                      );
                      return;
                    }

                    if (newBarcode.isNotEmpty &&
                        !_barcodeRegex.hasMatch(newBarcode)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Barcode must contain numbers only.'),
                        ),
                      );
                      return;
                    }

                    if (!_decimalRegex.hasMatch(priceText)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Unit price must be a valid number.'),
                        ),
                      );
                      return;
                    }

                    if (newSupplier.isNotEmpty &&
                        !_supplierRegex.hasMatch(newSupplier)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Supplier must contain letters, numbers, spaces, and basic punctuation only.',
                          ),
                        ),
                      );
                      return;
                    }

                    try {
                      await FirebaseFirestore.instance
                          .collection('inventory')
                          .doc(docId)
                          .update({
                        'name': newName,
                        'barcode': newBarcode,
                        'category': selectedCategory,
                        'unitPrice': double.parse(priceText),
                        'supplier': newSupplier,
                        'lastUpdatedAt': FieldValue.serverTimestamp(),
                        'lastUpdatedByUid': user?.uid ?? '',
                        'lastUpdatedByEmail': user?.email ?? '',
                        'lastUpdatedByName': user?.displayName ?? '',
                      });

                      await _logAction(
                        itemId: docId,
                        itemName: newName,
                        action: 'edit_item',
                      );

                      if (!mounted) return;
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Item details updated successfully.'),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to update item: $e'),
                        ),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteItem({
    required String docId,
    required String itemName,
  }) async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Item'),
          content: Text('Are you sure you want to delete "$itemName"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmDelete != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('inventory')
          .doc(docId)
          .delete();

      await _logAction(
        itemId: docId,
        itemName: itemName,
        action: 'delete',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$itemName deleted successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete item: $e'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('categories')
          .orderBy('name')
          .snapshots(),
      builder: (context, categorySnapshot) {
        final dynamicCategories = [
          'All',
          ...?categorySnapshot.data?.docs.map(
            (doc) => (doc.data() as Map<String, dynamic>)['name'].toString(),
          ),
        ];

        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF0B466E),
            foregroundColor: Colors.white,
            title: const Text(
              "Inventory",
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        value: _selectedCategory,
                        items: dynamicCategories,
                        hint: 'Category',
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildDropdown(
                        value: _selectedStatus,
                        items: _statuses,
                        hint: 'Status',
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear Filters'),
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('inventory')
                      .orderBy('createdAt', descending: true)
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

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No inventory items yet.',
                          style: TextStyle(fontSize: 16),
                        ),
                      );
                    }

                    final docs = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return _matchesFilters(data);
                    }).toList();

                    if (docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No matching items found.',
                          style: TextStyle(fontSize: 16),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;

                        final String docId = doc.id;
                        final String name = data['name'] ?? 'Unnamed Item';
                        final String barcode = data['barcode'] ?? '';
                        final String category =
                            data['category'] ?? 'Uncategorized';
                        final int quantity = (data['quantity'] ?? 0) as int;
                        final double price =
                            (data['unitPrice'] ?? 0).toDouble();
                        final String supplier = data['supplier'] ?? '';

                        final String createdByName =
                            data['createdByName'] ?? '';
                        final String createdByEmail =
                            data['createdByEmail'] ?? '';
                        final String lastUpdatedByName =
                            data['lastUpdatedByName'] ?? '';
                        final String lastUpdatedByEmail =
                            data['lastUpdatedByEmail'] ?? '';
                        final Timestamp? lastUpdatedAt =
                            data['lastUpdatedAt'] as Timestamp?;

                        final StockStatus status = _getStockStatus(quantity);

                        return _buildInventoryCard(
                          docId: docId,
                          name: name,
                          barcode: barcode.isEmpty ? 'No barcode' : barcode,
                          quantity: quantity,
                          price: price,
                          category: category,
                          supplier: supplier,
                          createdBy:
                              _formatActor(createdByName, createdByEmail),
                          lastUpdatedBy:
                              _formatActor(lastUpdatedByName, lastUpdatedByEmail),
                          lastUpdatedAt: _formatTimestamp(lastUpdatedAt),
                          status: status,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          isExpanded: true,
          hint: Text(hint),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildInventoryCard({
    required String docId,
    required String name,
    required String barcode,
    required int quantity,
    required double price,
    required String category,
    required String supplier,
    required String createdBy,
    required String lastUpdatedBy,
    required String lastUpdatedAt,
    required StockStatus status,
  }) {
    Color statusColor;
    String statusText;

    switch (status) {
      case StockStatus.inStock:
        statusColor = Colors.green;
        statusText = "In Stock";
        break;
      case StockStatus.lowStock:
        statusColor = Colors.orange;
        statusText = "Low Stock";
        break;
      case StockStatus.outOfStock:
        statusColor = Colors.red;
        statusText = "Out of Stock";
        break;
    }

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'stock_in') {
                      _showQuantityDialog(
                        docId: docId,
                        itemName: name,
                        currentQuantity: quantity,
                        actionType: 'Stock In',
                      );
                    } else if (value == 'stock_out') {
                      _showQuantityDialog(
                        docId: docId,
                        itemName: name,
                        currentQuantity: quantity,
                        actionType: 'Stock Out',
                      );
                    } else if (value == 'edit_quantity') {
                      _showQuantityDialog(
                        docId: docId,
                        itemName: name,
                        currentQuantity: quantity,
                        actionType: 'Edit Quantity',
                      );
                    } else if (value == 'edit_item') {
                      _showEditItemDialog(
                        docId: docId,
                        currentName: name,
                        currentBarcode: barcode,
                        currentCategory: category,
                        currentPrice: price,
                        currentSupplier: supplier,
                      );
                    } else if (value == 'delete') {
                      _deleteItem(
                        docId: docId,
                        itemName: name,
                      );
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'stock_in',
                      child: Text('Stock In'),
                    ),
                    PopupMenuItem(
                      value: 'stock_out',
                      child: Text('Stock Out'),
                    ),
                    PopupMenuItem(
                      value: 'edit_quantity',
                      child: Text('Edit Quantity'),
                    ),
                    PopupMenuItem(
                      value: 'edit_item',
                      child: Text('Edit Item'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete Item'),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              barcode,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _metric("Quantity", "$quantity"),
                _metric("Unit Price", "₱${price.toStringAsFixed(2)}"),
                _metric("Category", category),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Supplier: ${supplier.isEmpty ? 'N/A' : supplier}',
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 4),
            Text(
              'Created By: $createdBy',
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Last Updated By: $lastUpdatedBy',
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Last Updated At: $lastUpdatedAt',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
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
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 11),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}