import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ystore/config/app_assets.dart';
import 'package:ystore/config/app_color.dart';
import 'package:ystore/screens/dashboard_screen.dart';
import 'package:ystore/screens/manage_purchases.dart';
import 'package:ystore/screens/manage_role.dart';
import 'package:ystore/screens/manage_sales.dart';
import 'package:ystore/screens/notifications_screen.dart';
import 'package:ystore/widgets/bottom_navigation.dart';
import '../services/add_product.dart';

class ManageProductScreen extends StatefulWidget {
  final String role;

  ManageProductScreen({required this.role});

  @override
  _ManageProductScreenState createState() => _ManageProductScreenState();
}

class _ManageProductScreenState extends State<ManageProductScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _currentIndex = 0;
  String _searchQuery = '';

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

  void _onBottomNavigationTapped(int index) {
    print('Navigasi ke: $index dengan role: ${widget.role}');
    switch (index) {
      case 0:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => DashboardScreen(role: widget.role)),
          (route) => false,
        );
        break;
      case 1:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => ManageProductScreen(role: widget.role)),
          (route) => false,
        );
        break;
      case 2:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => ManageSalesScreen()),
          (route) => false,
        );
        break;
      case 3:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => ManagePurchasesScreen()),
          (route) => false,
        );
        break;
      case 4:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => NotificationsScreen()),
          (route) => false,
        );
        break;
      case 5:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => ManageRoleScreen(role: widget.role)),
          (route) => false,
        );
        break;
      // Add more cases for other icons
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.only(top: 63.0, left: 10.0, right: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Kelola Produk",
                      style: TextStyle(
                        fontSize: 32,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        color: AppColor.primary,
                      ),
                    ),
                    Image.asset(
                      'assets/images/logo.png',
                      width: 57,
                      height: 57,
                    )
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.only(top: 24.0, left: 10.0, right: 10.0),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelText: 'Cari berdasarkan nama produk',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('products').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                          child: Text("Terjadi error: ${snapshot.error}"));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text("Tidak ada data produk."));
                    }

                    var filteredDocs = snapshot.data!.docs.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      var productName = data['name']?.toLowerCase() ?? '';
                      return productName.contains(_searchQuery);
                    }).toList();

                    return ListView.builder(
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        DocumentSnapshot document = filteredDocs[index];
                        Map<String, dynamic> data =
                            document.data() as Map<String, dynamic>;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColor.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  spreadRadius: 2,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              title: Text(
                                data['name'] ?? 'Tidak ada nama',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColor.primary,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                "Hb: ${data['buyPrice'] ?? 'kosong'}, Hj: ${data['sellPrice'] ?? 'kosong'}, Stok: ${data['stock'] ?? 0}",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColor.grey,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              trailing: widget.role != 'kasir'
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.edit,
                                              color: AppColor.orange),
                                          onPressed: () =>
                                              _showEditProductDialog(
                                                  document.id),
                                        ),
                                        SizedBox(width: 8), // Jarak antara ikon
                                        IconButton(
                                          icon: Icon(Icons.delete,
                                              color: AppColor.maroon),
                                          onPressed: () =>
                                              _showDeleteConfirmationDialog(
                                                  document.id,
                                                  data['name'] ??
                                                      'Tidak ada nama'),
                                        ),
                                      ],
                                    )
                                  : null,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onBottomNavigationTapped,
        role: widget.role,
      ),
      floatingActionButton: widget.role != 'kasir'
          ? Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColor.secondary,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(31, 0, 0, 0),
                    blurRadius: 2,
                    spreadRadius: 2,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddProductScreen()),
                  );
                },
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            )
          : null,
    );
  }
}
