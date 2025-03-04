import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:ystore/config/app_color.dart';

class PurchaseDetailsScreen extends StatefulWidget {
  final String purchaseId;

  PurchaseDetailsScreen({required this.purchaseId});

  @override
  _PurchaseDetailsScreenState createState() => _PurchaseDetailsScreenState();
}

class _PurchaseDetailsScreenState extends State<PurchaseDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> _fetchUserName(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();
      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
      return userData?['username'] ?? 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<List<Object>> _fetchProducts(List<String> productIds) async {
    List<Future<DocumentSnapshot>> futures = [];
    for (var id in productIds) {
      futures.add(_firestore.collection('products').doc(id).get());
    }
    List<DocumentSnapshot> snapshots = await Future.wait(futures);
    return snapshots.map((doc) => doc.data() ?? {}).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColor.bg,
      ),
      backgroundColor: AppColor.bg,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<DocumentSnapshot>(
          future:
              _firestore.collection('purchases').doc(widget.purchaseId).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(child: Text("Pembelian tidak ditemukan."));
            }
            Map<String, dynamic> purchaseData =
                snapshot.data!.data() as Map<String, dynamic>;
            List<String> productIds = (purchaseData['products'] as List)
                .map((product) => product['id'] as String)
                .toList();

            return FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchProducts(productIds)
                  .then((list) => list.cast<Map<String, dynamic>>()),
              builder: (context, productSnapshot) {
                if (productSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                List<Map<String, dynamic>> productsData = productSnapshot.data!;

                return FutureBuilder<String>(
                  future: _fetchUserName(purchaseData['purchasedBy'] ?? ''),
                  builder: (context, userSnapshot) {
                    String purchasedBy = userSnapshot.data ?? 'Unknown';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detail Pembelian',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColor.primary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        SizedBox(height: 40),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: AppColor.white,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.05,
                              ),
                              Container(
                                width: double.infinity,
                                child: Column(
                                  children: [
                                    Text(
                                      'Pembelian Products/Stock',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColor.primary,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    Text(
                                      'YSTORE',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColor.primary,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 50),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 6),
                                      child: Text(
                                        'Produk',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w400,
                                            color: AppColor.maroon),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'Qty',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                          color: AppColor.maroon),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Harga',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                          color: AppColor.maroon),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 20),
                                      child: Text(
                                        'SubTotal',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w400,
                                            color: AppColor.maroon),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              ...productsData.asMap().entries.map((entry) {
                                int index = entry.key;
                                Map<String, dynamic> product = entry.value;
                                int quantity = purchaseData['products'][index]
                                        ['quantity'] ??
                                    0;
                                int buyPrice = product['buyPrice'] ?? 0;
                                int subTotal = quantity * buyPrice;
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(left: 6),
                                          child: Text(
                                              product['name'] ?? 'Unknown'),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          quantity.toString(),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(left: 30),
                                          child: Text(
                                            'Rp ${formatRupiah(buyPrice)}',
                                            textAlign: TextAlign.start,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(left: 20),
                                          child: Text(
                                            'Rp ${formatRupiah(subTotal)}',
                                            textAlign: TextAlign.start,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              Divider(thickness: 2),
                              Padding(
                                padding: const EdgeInsets.only(left: 6.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8.0),
                                      child: Text(
                                        'Total Belanja : Rp ${formatRupiah(purchaseData['totalAmount'] ?? 0)}',
                                        style: TextStyle(
                                            color: AppColor.navigation),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8.0),
                                      child: Text(
                                        'Tanggal : ${DateFormat('EEEE, d MMMM y', 'id_ID').format((purchaseData['purchaseDate'] as Timestamp)?.toDate() ?? DateTime.now())}',
                                        style: TextStyle(
                                            color: AppColor.navigation),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8.0),
                                      child: Text(
                                        'Dibeli oleh : $purchasedBy',
                                        style: TextStyle(
                                            color: AppColor.navigation),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  String formatRupiah(int amount) {
    return NumberFormat("#,##0", "id_ID").format(amount);
  }
}
