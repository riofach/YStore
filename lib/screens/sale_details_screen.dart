import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:ystore/config/app_color.dart';
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
      appBar: AppBar(),
      body: Padding(
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
                    Text(
                      'Detail Penjualan',
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
                            height: MediaQuery.of(context).size.height * 0.05,
                          ),
                          Container(
                            width: double.infinity,
                            child: Column(
                              children: [
                                Text(
                                  'Terimakasih Telah Berbelanja',
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
                                    color: AppColor.primary, // AppColor.primary
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
                                    // textAlign: TextAlign.center, //
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
                          ...saleData['products'].map((product) {
                            int subTotal =
                                product['quantity'] * product['sellPrice'];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment
                                    .center, // Mengubah crossAxisAlignment ke center
                                children: [
                                  Expanded(
                                      flex: 2,
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 6),
                                        child: Text(
                                          product['name']!,
                                        ),
                                      )),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      product['quantity'].toString(),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Expanded(
                                      flex: 2,
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(left: 30),
                                        child: Text(
                                          formatRupiah(product['sellPrice']),
                                          textAlign: TextAlign.start,
                                        ),
                                      )),
                                  Expanded(
                                      flex: 2,
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(left: 20),
                                        child: Text(
                                          formatRupiah(subTotal),
                                          textAlign: TextAlign.start,
                                        ),
                                      )),
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
                                    vertical: 8.0,
                                  ),
                                  child: Text(
                                    'Total Belanja : Rp ${formatRupiah(saleData['totalAmount'])}',
                                    style:
                                        TextStyle(color: AppColor.navigation),
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text(
                                    'Tanggal : ${DateFormat('EEEE, d MMMM y', 'id_ID').format(saleData['saleDate'].toDate())}',
                                    style:
                                        TextStyle(color: AppColor.navigation),
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text(
                                    'Dijual : $soldBy',
                                    style:
                                        TextStyle(color: AppColor.navigation),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColor.secondary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 5,
                                padding: EdgeInsets.symmetric(vertical: 15),
                              ),
                              onPressed: () => _downloadInvoice(context),
                              child: Text(
                                'Invoice',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  fontFamily: 'Poppins',
                                  color: AppColor.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
