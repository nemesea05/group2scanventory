import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _supplierController = TextEditingController();

  String? _selectedCategory;

  final RegExp _nameRegex = RegExp(r"^[A-Za-z0-9\s'().,-]+$");
  final RegExp _supplierRegex = RegExp(r"^[A-Za-z0-9\s'().,-]*$");
  final RegExp _barcodeRegex = RegExp(r'^\d*$');
  final RegExp _wholeNumberRegex = RegExp(r'^\d+$');
  final RegExp _decimalRegex = RegExp(r'^\d+(\.\d{1,2})?$');

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

  Future<void> _addCategoryToFirestore(String categoryName) async {
    final user = FirebaseAuth.instance.currentUser;

    final existing = await FirebaseFirestore.instance
        .collection('categories')
        .where('name', isEqualTo: categoryName)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category already exists.')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('categories').add({
      'name': categoryName,
      'createdAt': FieldValue.serverTimestamp(),
      'createdByUid': user?.uid ?? '',
      'createdByEmail': user?.email ?? '',
      'createdByName': user?.displayName ?? '',
    });

    if (!mounted) return;
    setState(() {
      _selectedCategory = categoryName;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Category added successfully.')),
    );
  }

  Future<void> _showAddCategoryDialog() async {
    final TextEditingController categoryController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add New Category"),
          content: TextField(
            controller: categoryController,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z0-9\s'().,-]")),
            ],
            decoration: const InputDecoration(
              hintText: "Enter category name",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final newCategory = categoryController.text.trim();

                if (newCategory.isEmpty) return;

                Navigator.pop(context);
                await _addCategoryToFirestore(newCategory);
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  bool _validateInputs() {
    final String name = _nameController.text.trim();
    final String barcode = _barcodeController.text.trim();
    final String qty = _qtyController.text.trim();
    final String price = _priceController.text.trim();
    final String supplier = _supplierController.text.trim();

    if (name.isEmpty || qty.isEmpty || price.isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return false;
    }

    if (!_nameRegex.hasMatch(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Item name must contain letters, numbers, spaces, and basic punctuation only.',
          ),
        ),
      );
      return false;
    }

    if (barcode.isNotEmpty && !_barcodeRegex.hasMatch(barcode)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Barcode must contain numbers only.')),
      );
      return false;
    }

    if (!_wholeNumberRegex.hasMatch(qty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity must be a whole number.')),
      );
      return false;
    }

    if (!_decimalRegex.hasMatch(price)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unit price must be a valid number.')),
      );
      return false;
    }

    if (supplier.isNotEmpty && !_supplierRegex.hasMatch(supplier)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Supplier must contain letters, numbers, spaces, and basic punctuation only.',
          ),
        ),
      );
      return false;
    }

    return true;
  }

  Future<void> _saveItem() async {
    if (!_validateInputs()) return;

    final String itemName = _nameController.text.trim();
    final int quantity = int.parse(_qtyController.text.trim());
    final user = FirebaseAuth.instance.currentUser;

    try {
      final docRef = await FirebaseFirestore.instance.collection('inventory').add({
        'name': itemName,
        'barcode': _barcodeController.text.trim(),
        'category': _selectedCategory,
        'quantity': quantity,
        'unitPrice': double.parse(_priceController.text.trim()),
        'supplier': _supplierController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'createdByUid': user?.uid ?? '',
        'createdByEmail': user?.email ?? '',
        'createdByName': user?.displayName ?? '',
        'lastUpdatedAt': FieldValue.serverTimestamp(),
        'lastUpdatedByUid': user?.uid ?? '',
        'lastUpdatedByEmail': user?.email ?? '',
        'lastUpdatedByName': user?.displayName ?? '',
      });

      await _logAction(
        itemId: docRef.id,
        itemName: itemName,
        action: 'register',
        quantityChanged: quantity,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item saved successfully!')),
      );

      _nameController.clear();
      _barcodeController.clear();
      _qtyController.clear();
      _priceController.clear();
      _supplierController.clear();

      setState(() {
        _selectedCategory = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save item: $e')),
      );
    }
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    _supplierController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B466E),
        foregroundColor: Colors.white,
        title: const Text(
          "Add New Item",
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('categories')
              .orderBy('name')
              .snapshots(),
          builder: (context, snapshot) {
            final categoryDocs = snapshot.data?.docs ?? [];
            final categories = categoryDocs
                .map((doc) =>
                    (doc.data() as Map<String, dynamic>)['name'].toString())
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(),
                const SizedBox(height: 20),
                _buildLabel("Item Name *"),
                _buildTextField(
                  _nameController,
                  "Enter item name",
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r"[A-Za-z0-9\s'().,-]"),
                    ),
                  ],
                ),
                _buildLabel("Barcode"),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        _barcodeController,
                        "Enter or scan barcode",
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildScannerButton(),
                  ],
                ),
                _buildLabel("Category *"),
                _buildDropdown(categories),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("Quantity *"),
                          _buildTextField(
                            _qtyController,
                            "0",
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("Unit Price *"),
                          _buildTextField(
                            _priceController,
                            "0.00",
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                _buildLabel("Supplier"),
                _buildTextField(
                  _supplierController,
                  "Enter supplier name",
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r"[A-Za-z0-9\s'().,-]"),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                _buildSubmitButton(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        const Icon(Icons.inventory_2_outlined, size: 20),
        const SizedBox(width: 8),
        Text(
          "Add New Item",
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildScannerButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        icon: const Icon(Icons.qr_code_scanner),
        onPressed: () {
          debugPrint("Scanner Triggered");
        },
      ),
    );
  }

  Widget _buildDropdown(List<String> categories) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          hint: const Text("Select category"),
          items: [
            ...categories.map((value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }),
            const DropdownMenuItem<String>(
              value: "ADD_NEW",
              child: Text("+ Add New Category"),
            ),
          ],
          onChanged: (value) {
            if (value == "ADD_NEW") {
              _showAddCategoryDialog();
            } else {
              setState(() {
                _selectedCategory = value;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _saveItem,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          "Save Item",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}