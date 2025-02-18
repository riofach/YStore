import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Import intl package for date formatting and number formatting

class PurchaseDetailsScreen extends StatelessWidget {
  final String purchaseId;

  PurchaseDetailsScreen({required this.purchaseId});

  Future<String> _fetchUserName(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
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
  Widget build(BuildContext context) {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Pembelian'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _firestore.collection('purchases').doc(purchaseId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Terjadi error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text("Pembelian tidak ditemukan."));
          }

          Map<String, dynamic> purchaseData =
              snapshot.data!.data() as Map<String, dynamic>;

          List<String> productNames = [];
          int totalQuantity = 0;

          for (var product in purchaseData['products']) {
            productNames.add("${product['name']} (${product['quantity']})");
            totalQuantity += (product['quantity'] as num).toInt();
          }

          String formattedDate = DateFormat('EEEE, d MMMM y', 'id_ID')
              .format(purchaseData['purchaseDate'].toDate());

          return FutureBuilder<String>(
            future: _fetchUserName(purchaseData['purchasedBy']),
            builder: (context, userSnapshot) {
              String purchasedBy = userSnapshot.data ?? 'Unknown';

              return ListView(
                children: [
                  ListTile(
                    title: Text("Produk"),
                    subtitle: Text(productNames.join(', ')),
                  ),
                  ListTile(
                    title: Text("Qty"),
                    subtitle: Text("$totalQuantity"),
                  ),
                  ListTile(
                    title: Text("Total"),
                    subtitle:
                        Text("Rp ${formatRupiah(purchaseData['totalAmount'])}"),
                  ),
                  ListTile(
                    title: Text("Tanggal"),
                    subtitle: Text(formattedDate),
                  ),
                  ListTile(
                    title: Text("Dibeli oleh"),
                    subtitle: Text(purchasedBy),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
