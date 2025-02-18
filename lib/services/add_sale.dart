import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:ystore/main.dart';

class AddSaleScreen extends StatefulWidget {
  @override
  _AddSaleScreenState createState() => _AddSaleScreenState();
}

class _AddSaleScreenState extends State<AddSaleScreen> {
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
          'sellPrice': data['sellPrice'],
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

  Future<void> _addSale() async {
    if (_selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Tambahkan produk ke penjualan!")),
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

        if (productData['stock'] < quantity) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    "Stok tidak mencukupi untuk produk: ${productData['name']}")),
          );
          return;
        }

        int sellPrice = productData['sellPrice'];
        int productTotalAmount = quantity * sellPrice;

        totalQuantity += quantity;
        totalAmount += productTotalAmount;

        // Update product stock
        await _firestore.collection('products').doc(productId).update({
          'stock': productData['stock'] - quantity,
        });

        // Check if stock matches minStock and create notification if necessary
        if (productData['stock'] - quantity == productData['minStock'] ||
            productData['stock'] - quantity <= productData['minStock']) {
          await _firestore.collection('notifications').add({
            'productId': productId,
            'message': "Stock untuk ${productData['name']} menipis",
            'createdAt': Timestamp.now(),
            'read': false,
          });

          // Show local notification
          const AndroidNotificationDetails androidPlatformChannelSpecifics =
              AndroidNotificationDetails(
            'your_channel_id',
            'your_channel_name',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker',
          );
          const NotificationDetails platformChannelSpecifics =
              NotificationDetails(android: androidPlatformChannelSpecifics);
          await flutterLocalNotificationsPlugin.show(
            0,
            'Stock Alert',
            'Stock untuk ${productData['name']} menipis',
            platformChannelSpecifics,
          );
        }
      }

      // Get the count of documents in sales collection
      QuerySnapshot salesSnapshot = await _firestore.collection('sales').get();
      int count = salesSnapshot.docs.length + 1;

      String saleId = _firestore.collection('sales').doc().id;
      await _firestore.collection('sales').doc(saleId).set({
        'id': saleId,
        'products': _selectedProducts,
        'totalQuantity': totalQuantity,
        'totalAmount': totalAmount,
        'saleDate': Timestamp.now(),
        'soldBy': _auth.currentUser?.uid,
        'nomor':
            '${DateTime.now().day}${DateTime.now().month}${DateTime.now().year}$count',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Penjualan berhasil ditambahkan!")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal menambahkan penjualan: $e")));
    }
  }

  void _addProductToSale(String productId) {
    int quantity = 1;
    Map<String, dynamic> product =
        _products.firstWhere((p) => p['id'] == productId);

    if (_selectedProducts.any((p) => p['id'] == productId)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              "Produk ${product['name']} sudah ditambahkan ke penjualan.")));
      return;
    }

    setState(() {
      _selectedProducts.add({
        'id': productId,
        'name': product['name'],
        'sellPrice': product['sellPrice'],
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
          total + (product['quantity'] as int) * (product['sellPrice'] as int),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Tambah Penjualan'),
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
                        "Jumlah: ${product['quantity']}, Total: ${(product['quantity'] as int) * (product['sellPrice'] as int)}"),
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
              onPressed: _addSale,
              child: Text('Tambah Penjualan'),
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
                    _addProductToSale(product['id']);
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
