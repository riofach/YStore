import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      appBar: AppBar(
        title: Text('Tambah Pembelian'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _selectedProducts.length,
                itemBuilder: (context, index) {
                  Map<String, dynamic> product = _selectedProducts[index];
                  return ListTile(
                    title: Text(product['name']),
                    subtitle: Text(
                        "Jumlah: ${product['quantity']}, Total: ${(product['quantity'] as int) * (product['buyPrice'] as int)}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove_circle),
                          onPressed: () {
                            setState(() {
                              _selectedProducts.removeAt(index);
                            });
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            _showQuantityDialog(product['id']);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Text("Total Belanja: $totalEstimatedCost"),
            ElevatedButton(
              onPressed: _addPurchase,
              child: Text('Tambah Pembelian'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showProductSelectionDialog();
        },
        child: Icon(Icons.add),
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
