import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ystore/config/app_color.dart';
import '../services/add_purchase.dart';
import 'purchase_details_screen.dart';

class ManagePurchasesScreen extends StatefulWidget {
  @override
  _ManagePurchasesScreenState createState() => _ManagePurchasesScreenState();
}

class _ManagePurchasesScreenState extends State<ManagePurchasesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  TextEditingController _startDateController = TextEditingController();
  TextEditingController _endDateController = TextEditingController();
  DateTime? startDate;
  DateTime? endDate;

  Future<void> _deletePurchase(String purchaseId) async {
    try {
      await _firestore.collection('purchases').doc(purchaseId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Pembelian berhasil dihapus!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menghapus pembelian: $e")),
      );
    }
  }

  void _showDeleteConfirmationDialog(String purchaseId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Konfirmasi Hapus"),
          content: Text("Apakah Anda yakin ingin menghapus pembelian ini?"),
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
                _deletePurchase(purchaseId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<String> _fetchProductName(String productId) async {
    try {
      DocumentSnapshot productDoc =
          await _firestore.collection('products').doc(productId).get();
      Map<String, dynamic> productData =
          productDoc.data() as Map<String, dynamic>;
      return productData['name'] ?? 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
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

  void _clearFilters() {
    setState(() {
      _startDateController.clear();
      _endDateController.clear();
      startDate = null;
      endDate = null;
    });
  }

  @override
  void initState() {
    super.initState();
    initializeDateFormatting(
        'id_ID', null); // date formatting for Indonesian locale
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
                      'Kelola Pembelian',
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
                  stream: _firestore.collection('purchases').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text("Tidak ada data pembelian."));
                    }

                    List<DocumentSnapshot> filteredDocs = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        DocumentSnapshot purchaseDoc = filteredDocs[index];
                        Map<String, dynamic> purchaseData =
                            purchaseDoc.data() as Map<String, dynamic>;

                        List<String> productNames = [];
                        int totalQuantity = 0;

                        for (var product in purchaseData['products']) {
                          productNames.add(
                              "${product['name']} (${product['quantity']})");
                          totalQuantity += (product['quantity'] as num).toInt();
                        }

                        String formattedDate =
                            DateFormat('EEEE, d MMMM y', 'id_ID')
                                .format(purchaseData['purchaseDate'].toDate());

                        String displayedProducts =
                            productNames.take(2).join(', ');
                        if (productNames.length > 2) {
                          displayedProducts += ', ......';
                        }

                        return FutureBuilder<String>(
                          future: _fetchUserName(purchaseData['purchasedBy']),
                          builder: (context, userSnapshot) {
                            String purchasedBy = userSnapshot.data ?? 'Unknown';

                            return Card(
                              elevation: 2,
                              color: AppColor.white,
                              margin: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.all(16),
                                title: Text(
                                  displayedProducts,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                    "Total: ${purchaseData['totalAmount']}, Tgl: $formattedDate, Dibeli: $purchasedBy"),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.visibility,
                                          color: AppColor.orange),
                                      onPressed: () {
                                        _showPurchaseDetails(purchaseDoc.id);
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete,
                                          color: AppColor.maroon),
                                      onPressed: () {
                                        _showDeleteConfirmationDialog(
                                            purchaseDoc.id);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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
          // Navigate to add purchase screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddPurchaseScreen()),
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

  void _showPurchaseDetails(String purchaseId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PurchaseDetailsScreen(purchaseId: purchaseId),
      ),
    );
  }
}
