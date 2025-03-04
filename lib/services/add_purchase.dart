import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ystore/config/app_color.dart';
import 'package:ystore/widgets/bottom_custom.dart';

class AddPurchaseScreen extends StatefulWidget {
  @override
  _AddPurchaseScreenState createState() => _AddPurchaseScreenState();
}

class _AddPurchaseScreenState extends State<AddPurchaseScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _selectedProducts = [];

  Future<void> _fetchProducts() async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore.collection('products').get();
      List<Map<String, dynamic>> productsList = [];
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        productsList.add({
          'id': doc.id,
          'name': data['name'],
          'buyPrice': data['buyPrice'],
          'stock': data['stock'],
        });
      }
      setState(() {
        _products = productsList;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mengambil data produk: $e")),
      );
    }
  }

  Future<void> _addPurchase() async {
    if (_selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Tambahkan produk ke pembelian!")),
      );
      return;
    }

    try {
      int totalQuantity = 0;
      int totalAmount = 0;

      for (var product in _selectedProducts) {
        String productId = product['id'];
        int quantity = product['quantity'];
        DocumentSnapshot productDoc =
            await _firestore.collection('products').doc(productId).get();
        Map<String, dynamic> productData =
            productDoc.data() as Map<String, dynamic>;

        int buyPrice = productData['buyPrice'];
        int productTotalAmount = quantity * buyPrice;

        totalQuantity += quantity;
        totalAmount += productTotalAmount;

        // Update product stock
        await _firestore.collection('products').doc(productId).update({
          'stock': productData['stock'] + quantity,
        });

        // Check if stock exceeds minStock and update notifications
        if (productData['stock'] + quantity > productData['minStock']) {
          await _firestore
              .collection('notifications')
              .where('productId', isEqualTo: productId)
              .where('read', isEqualTo: false)
              .get()
              .then((snapshot) {
            for (var doc in snapshot.docs) {
              doc.reference.update({'read': true});
            }
          });
        }
      }

      await _firestore.collection('purchases').add({
        'products': _selectedProducts,
        'totalQuantity': totalQuantity,
        'totalAmount': totalAmount,
        'purchaseDate': Timestamp.now(),
        'purchasedBy': _auth.currentUser?.uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Pembelian berhasil ditambahkan!")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menambahkan pembelian: $e")),
      );
    }
  }

  void _addProductToPurchase(String productId) {
    int quantity = 1;
    Map<String, dynamic> product =
        _products.firstWhere((p) => p['id'] == productId);

    if (_selectedProducts.any((p) => p['id'] == productId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Produk ${product['name']} sudah ditambahkan ke pembelian.")),
      );
      return;
    }

    setState(() {
      _selectedProducts.add({
        'id': productId,
        'name': product['name'],
        'buyPrice': product['buyPrice'],
        'quantity': quantity,
      });
    });
  }

  void _updateProductQuantity(String productId, int newQuantity) {
    setState(() {
      _selectedProducts = _selectedProducts.map((product) {
        if (product['id'] == productId) {
          return {...product, 'quantity': newQuantity};
        }
        return product;
      }).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    int totalEstimatedCost = _selectedProducts.fold(
      0,
      (int total, product) =>
          total + (product['quantity'] as int) * (product['buyPrice'] as int),
    );

    return Scaffold(
      backgroundColor: AppColor.bg,
      appBar: AppBar(
        backgroundColor: AppColor.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
            size: 30,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tambah Pembelian',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: 28),
                  ),
                  SizedBox(height: 22),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _selectedProducts.length,
                      itemBuilder: (context, index) {
                        Map<String, dynamic> product = _selectedProducts[index];
                        return Card(
                          elevation: 2,
                          color: AppColor.white,
                          margin: EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              title: Text(
                                product['name'],
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                  "Jumlah: ${product['quantity']}, Total: ${(product['quantity'] as int) * (product['buyPrice'] as int)}"),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.remove_circle,
                                      color: AppColor.maroon,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _selectedProducts.removeAt(index);
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.edit,
                                      color: AppColor.orange,
                                    ),
                                    onPressed: () {
                                      _showQuantityDialog(product['id']);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Total Belanja: $totalEstimatedCost",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColor.primary,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  BottomCustom(
                    label: 'Tambah Pembelian',
                    onTap: _addPurchase,
                    isExpand: true,
                  ),
                  SizedBox(height: 20),
                ],
              ),
              Positioned(
                bottom: 80,
                right: 16,
                child: FloatingActionButton(
                  onPressed: () {
                    _showProductSelectionDialog();
                  },
                  backgroundColor: AppColor.primary,
                  foregroundColor: AppColor.white,
                  elevation: 8.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    Icons.add,
                    size: 35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProductSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Pilih Produk"),
          content: SingleChildScrollView(
            child: ListBody(
              children: _products.map((product) {
                return ListTile(
                  title: Text(product['name']),
                  onTap: () {
                    _addProductToPurchase(product['id']);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _showQuantityDialog(String productId) {
    int quantity =
        _selectedProducts.firstWhere((p) => p['id'] == productId)['quantity'];
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Ubah Jumlah"),
          content: TextField(
            keyboardType: TextInputType.number,
            onChanged: (value) {
              int? newQuantity = int.tryParse(value);
              if (newQuantity != null && newQuantity > 0) {
                _updateProductQuantity(productId, newQuantity);
              }
            },
            controller: TextEditingController(text: '$quantity'),
          ),
          actions: [
            TextButton(
              child: Text("Batal"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text("Simpan"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
