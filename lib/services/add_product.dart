import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ystore/config/app_assets.dart';
import 'package:ystore/config/app_color.dart';
import 'package:ystore/widgets/bottom_custom.dart';

class AddProductScreen extends StatefulWidget {
  final String? productId; // Optional product ID for editing

  AddProductScreen({this.productId});

  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedCategory = 'Gas'; // Default category
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _buyPriceController = TextEditingController();
  final TextEditingController _sellPriceController = TextEditingController();
  final TextEditingController _minStockController = TextEditingController();

  // List of categories
  final List<String> _categories = [
    'Gas',
    'Galon',
    'Beras',
    'Minuman',
    'Makanan',
    'Bumbu Makanan',
    'Bumbu Dapur',
    'Rokok',
    'Toilet',
    'Lainnya'
  ];

  Future<void> _addProduct() async {
    String name = _nameController.text.trim();
    String description = _descriptionController.text.trim();
    String category = _selectedCategory;
    int stock = int.tryParse(_stockController.text.trim()) ?? 0;
    int buyPrice = int.tryParse(_buyPriceController.text.trim()) ?? 0;
    int sellPrice = int.tryParse(_sellPriceController.text.trim()) ?? 0;
    int minStock = int.tryParse(_minStockController.text.trim()) ?? 2;

    if (name.isEmpty ||
        description.isEmpty ||
        category.isEmpty ||
        stock <= 0 ||
        buyPrice <= 0 ||
        sellPrice <= 0 ||
        minStock < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Semua field harus diisi dan memiliki nilai valid! Min Stock minimal 2")),
      );
      return;
    }

    try {
      if (widget.productId == null) {
        // Add new product
        await _firestore.collection('products').add({
          'name': name,
          'description': description,
          'category': category,
          'stock': stock,
          'buyPrice': buyPrice,
          'sellPrice': sellPrice,
          'minStock': minStock,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Produk berhasil ditambahkan!")),
        );
      } else {
        // Update existing product
        await _firestore.collection('products').doc(widget.productId).update({
          'name': name,
          'description': description,
          'category': category,
          'stock': stock,
          'buyPrice': buyPrice,
          'sellPrice': sellPrice,
          'minStock': minStock,
          'updatedAt': Timestamp.now(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Produk berhasil diperbarui!")),
        );
      }
      Navigator.pop(context); // Close the add product screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menambahkan produk: $e")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.productId != null) {
      // Fetch product details if editing
      _fetchProductDetails(widget.productId!);
    }
  }

  Future<void> _fetchProductDetails(String productId) async {
    try {
      DocumentSnapshot productDoc =
          await _firestore.collection('products').doc(productId).get();
      Map<String, dynamic> data = productDoc.data() as Map<String, dynamic>;

      _nameController.text = data['name'] ?? '';
      _descriptionController.text = data['description'] ?? '';
      _selectedCategory = data['category'] ?? 'Gas';
      _stockController.text = data['stock'].toString();
      _buyPriceController.text = data['buyPrice'].toString();
      _sellPriceController.text = data['sellPrice'].toString();
      _minStockController.text = data['minStock'].toString();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mengambil data produk: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(100),
        child: AppBar(
          toolbarHeight: 100,
          title: Text(
            widget.productId == null ? 'Tambah Produk' : 'Edit Produk',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 15),
              child: Image.asset(
                AppAssets.logo,
                height: 40,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: AppColor.lightGrey,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  labelText: 'Nama Produk',
                  labelStyle: TextStyle(color: AppColor.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColor.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColor.primary),
                  ),
                ),
              ),
              SizedBox(
                height: 16,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: AppColor.lightGrey,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  labelText: 'Deskripsi Produk',
                  labelStyle: TextStyle(color: AppColor.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColor.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColor.primary),
                  ),
                ),
              ),
              SizedBox(
                height: 12,
              ),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: AppColor.lightGrey,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  labelText: 'Kategori Produk',
                  labelStyle: TextStyle(color: AppColor.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColor.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColor.primary),
                  ),
                ),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                  });
                },
              ),
              SizedBox(
                height: 12,
              ),
              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: AppColor.lightGrey,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  labelText: 'Stock Produk',
                  labelStyle: TextStyle(color: AppColor.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColor.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColor.primary),
                  ),
                ),
              ),
              SizedBox(
                height: 12,
              ),
              TextFormField(
                controller: _buyPriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: AppColor.lightGrey,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  labelText: 'Harga Beli Satuan Produk',
                  labelStyle: TextStyle(color: AppColor.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColor.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColor.primary),
                  ),
                ),
              ),
              SizedBox(
                height: 12,
              ),
              TextFormField(
                controller: _sellPriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: AppColor.lightGrey,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  labelText: 'Harga Jual Satuan Produk',
                  labelStyle: TextStyle(color: AppColor.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColor.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColor.primary),
                  ),
                ),
              ),
              SizedBox(
                height: 12,
              ),
              TextFormField(
                controller: _minStockController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: AppColor.lightGrey,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  labelText: 'minStock Produk (minimal 2)',
                  labelStyle: TextStyle(color: AppColor.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColor.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColor.primary),
                  ),
                ),
              ),
              SizedBox(height: 20),
              BottomCustom(
                label: widget.productId == null
                    ? 'Tambah Produk'
                    : 'Simpan Perubahan',
                onTap: _addProduct,
                isExpand: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
