import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ystore/config/app_color.dart';
import '../services/add_sale.dart';
import 'sale_details_screen.dart';
import '../services/auth_service.dart'; // Import AuthService

class ManageSalesScreen extends StatefulWidget {
  @override
  _ManageSalesScreenState createState() => _ManageSalesScreenState();
}

class _ManageSalesScreenState extends State<ManageSalesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService(); // AuthService instance
  String? _userRole;
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  DateTime? startDate;
  DateTime? endDate;

  Future<void> _deleteSale(String saleId) async {
    try {
      DocumentSnapshot saleDoc =
          await _firestore.collection('sales').doc(saleId).get();
      Map<String, dynamic> saleData = saleDoc.data() as Map<String, dynamic>;

      // Restore stock for each product
      for (var product in saleData['products']) {
        String productId = product['id'];
        int quantity = product['quantity'];

        DocumentSnapshot productDoc =
            await _firestore.collection('products').doc(productId).get();
        Map<String, dynamic> productData =
            productDoc.data() as Map<String, dynamic>;

        await _firestore.collection('products').doc(productId).update({
          'stock': productData['stock'] + quantity,
        });
      }

      // Delete the sale document
      await _firestore.collection('sales').doc(saleId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Penjualan berhasil dihapus!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menghapus penjualan: $e")),
      );
    }
  }

  void _showDeleteConfirmationDialog(String saleId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Konfirmasi Hapus"),
          content: Text("Apakah Anda yakin ingin menghapus penjualan ini?"),
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
                _deleteSale(saleId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showSaleDetails(String saleId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SaleDetailsScreen(saleId: saleId),
      ),
    );
  }

  Future<String> _fetchUserName(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      return userData['username'] ?? 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  String formatRupiah(int amount) {
    return NumberFormat("#,##0", "id_ID").format(amount);
  }

  @override
  void initState() {
    super.initState();
    initializeDateFormatting(
        'id_ID', null); // date formatting for Indonesian locale
    String? currentUserId = _authService.getCurrentUserUid();
    if (currentUserId != null) {
      _authService.getUserRole(currentUserId).then((role) {
        setState(() {
          _userRole = role;
        });
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _startDateController.clear();
      _endDateController.clear();
      startDate = null;
      endDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Kelola Penjualan',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColor.primary),
                    ),
                    IconButton(
                      icon: Icon(Icons.filter_list),
                      onPressed: () {
                        _clearFilters();
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _startDateController,
                        decoration: InputDecoration(
                          labelText: 'Tanggal Mulai',
                          border: UnderlineInputBorder(),
                        ),
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            _startDateController.text =
                                DateFormat('yyyy-MM-dd').format(pickedDate);
                            setState(() {
                              startDate = pickedDate;
                            });
                          }
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _endDateController,
                        decoration: InputDecoration(
                          labelText: 'Tanggal Akhir',
                          border: UnderlineInputBorder(),
                        ),
                        onTap: () async {
                          if (startDate == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      "Pilih tanggal mulai terlebih dahulu")),
                            );
                            return;
                          }
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: startDate!,
                            firstDate: startDate!,
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            _endDateController.text =
                                DateFormat('yyyy-MM-dd').format(pickedDate);
                            setState(() {
                              endDate = pickedDate;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('sales').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                          child: Text("Terjadi error: ${snapshot.error}"));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text("Tidak ada data penjualan."));
                    }

                    List<DocumentSnapshot> filteredDocs =
                        snapshot.data!.docs.where((doc) {
                      DateTime saleDate =
                          (doc.data() as Map<String, dynamic>)['saleDate']
                              .toDate();
                      if (startDate != null && endDate != null) {
                        return saleDate.isAfter(startDate!) &&
                            saleDate.isBefore(endDate!.add(Duration(days: 1)));
                      } else if (startDate != null) {
                        return saleDate.isAfter(startDate!);
                      } else if (endDate != null) {
                        return saleDate
                            .isBefore(endDate!.add(Duration(days: 1)));
                      } else {
                        return true;
                      }
                    }).toList();

                    return ListView.builder(
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        DocumentSnapshot saleDoc = filteredDocs[index];
                        Map<String, dynamic> saleData =
                            saleDoc.data() as Map<String, dynamic>;

                        List<String> productNames = [];
                        if (saleData['products'] is List) {
                          for (var product in saleData['products']) {
                            productNames.add(
                                "${product['name']} (${product['quantity']})");
                          }
                        }

                        String formattedDate =
                            DateFormat('EEEE, d MMMM y', 'id_ID')
                                .format(saleData['saleDate'].toDate());

                        String displayedProducts =
                            productNames.take(2).join(', ');
                        if (productNames.length > 2) {
                          displayedProducts += ', ....';
                        }

                        return Card(
                          elevation: 2,
                          color: AppColor.white,
                          margin:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.all(16),
                            title: Text(
                              displayedProducts,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle:
                                Text("Tgl: $formattedDate, Penjual: owner"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.visibility,
                                      color: AppColor.orange),
                                  onPressed: () {
                                    _showSaleDetails(saleDoc.id);
                                  },
                                ),
                              ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigasi ke halaman tambah user (register.dart)
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddSaleScreen()),
          );
        },
        backgroundColor: AppColor.secondary,
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
    );
  }
}
