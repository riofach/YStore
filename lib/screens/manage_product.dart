import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/add_product.dart'; // Import the add product screen
import '../services/auth_service.dart'; // Import AuthService

class ManageProductScreen extends StatefulWidget {
  final String role;

  ManageProductScreen({required this.role});

  @override
  _ManageProductScreenState createState() => _ManageProductScreenState();
}

class _ManageProductScreenState extends State<ManageProductScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _deleteProduct(String productId, String productName) async {
    try {
      await _firestore.collection('products').doc(productId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Produk '$productName' berhasil dihapus!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menghapus produk: $e")),
      );
    }
  }

  void _showDeleteConfirmationDialog(String productId, String productName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Konfirmasi Hapus"),
          content:
              Text("Apakah Anda yakin ingin menghapus produk '$productName'?"),
          actions: <Widget>[
            TextButton(
              child: Text("Batal"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Hapus"),
              onPressed: () {
                _deleteProduct(productId, productName);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditProductDialog(String productId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return AddProductScreen(productId: productId);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kelola Produk'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Terjadi error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("Tidak ada data produk."));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot document = snapshot.data!.docs[index];
              Map<String, dynamic> data =
                  document.data() as Map<String, dynamic>;

              return ListTile(
                title: Text(data['name'] ?? 'Tidak ada nama'),
                subtitle: Text(
                    "Hb: ${data['buyPrice'] ?? 'kosong'}, Hj: ${data['sellPrice'] ?? 'kosong'}, Stok: ${data['stock'] ?? 0}"),
                trailing: widget.role != 'kasir'
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () =>
                                _showEditProductDialog(document.id),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => _showDeleteConfirmationDialog(
                                document.id, data['name'] ?? 'Tidak ada nama'),
                          ),
                        ],
                      )
                    : null,
              );
            },
          );
        },
      ),
      floatingActionButton: widget.role != 'kasir'
          ? FloatingActionButton(
              onPressed: () {
                // Navigate to add product screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddProductScreen()),
                );
              },
              child: Icon(Icons.add),
            )
          : null,
    );
  }
}
