import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
        title: Text('Detail Pembelian'),
      ),
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
                        SizedBox(height: 20),
                        Text(
                          'Pembelian Products/Stock\nYSTORE',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Produk         Qty        Harga              SubTotal',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        ...productsData.asMap().entries.map((entry) {
                          int index = entry.key;
                          Map<String, dynamic> product = entry.value;
                          int quantity =
                              purchaseData['products'][index]['quantity'] ?? 0;
                          int buyPrice = product['buyPrice'] ?? 0;
                          int subTotal = quantity * buyPrice;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(product['name'] ?? 'Unknown'),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(quantity.toString()),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text('Rp ${formatRupiah(buyPrice)}'),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text('Rp ${formatRupiah(subTotal)}'),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        Divider(thickness: 2),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                              'Total Belanja : Rp ${formatRupiah(purchaseData['totalAmount'] ?? 0)}'),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                              'Tanggal : ${DateFormat('EEEE, d MMMM y', 'id_ID').format((purchaseData['purchaseDate'] as Timestamp)?.toDate() ?? DateTime.now())}'),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('Dibeli oleh : $purchasedBy'),
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
