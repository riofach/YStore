import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import '../services/pdf_service.dart';
import 'package:open_file/open_file.dart';

class SaleDetailsScreen extends StatelessWidget {
  final String saleId;
  final PdfService _pdfService = PdfService();

  SaleDetailsScreen({required this.saleId});

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

  Future<void> _downloadInvoice(BuildContext context) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final DocumentSnapshot snapshot =
        await _firestore.collection('sales').doc(saleId).get();
    if (snapshot.exists) {
      final Map<String, dynamic> saleData =
          snapshot.data() as Map<String, dynamic>;
      final String invoiceNumber =
          saleData['nomor'] ?? 'default_invoice_number';
      final Uint8List bytes = await _pdfService.generateInvoicePdf(saleData);
      final Directory? downloadsDir = await getDownloadsDirectory();
      final File file =
          File('${downloadsDir?.path}/invoice-${invoiceNumber}.pdf');
      await file.writeAsBytes(bytes, flush: true);
      OpenFile.open(file.path);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Penjualan tidak ditemukan.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Penjualan'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FutureBuilder<DocumentSnapshot>(
            future: _firestore.collection('sales').doc(saleId).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              }

              if (snapshot.hasError) {
                return Text("Terjadi error: ${snapshot.error}");
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Text("Penjualan tidak ditemukan.");
              }

              Map<String, dynamic> saleData =
                  snapshot.data!.data() as Map<String, dynamic>;

              return FutureBuilder<String>(
                future: _fetchUserName(saleData['soldBy']),
                builder: (context, userSnapshot) {
                  String soldBy = userSnapshot.data ?? 'Unknown';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.05,
                      ),
                      Text(
                        'Terimakasih Telah Berbelanja\nYSTORE',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Produk         Qty       Harga           SubTotal',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      ...saleData['products'].map((product) {
                        int subTotal =
                            product['quantity'] * product['sellPrice'];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 2, child: Text(product['name']!)),
                              Expanded(
                                  flex: 1,
                                  child: Text(product['quantity'].toString())),
                              Expanded(
                                  flex: 2,
                                  child:
                                      Text(formatRupiah(product['sellPrice']))),
                              Expanded(
                                  flex: 2, child: Text(formatRupiah(subTotal))),
                            ],
                          ),
                        );
                      }).toList(),
                      Divider(thickness: 2),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Total Belanja : Rp ${formatRupiah(saleData['totalAmount'])}',
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Tanggal : ${DateFormat('EEEE, d MMMM y', 'id_ID').format(saleData['saleDate'].toDate())}',
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('Dijual : $soldBy'),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => _downloadInvoice(context),
                        child: Text('Download Invoice'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
