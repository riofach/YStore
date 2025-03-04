import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart' as flutter;

class PdfService {
  Future<Uint8List> generateInvoicePdf(Map<String, dynamic> saleData) async {
    final pdf = pw.Document();

    // Load font from assets
    final regularFont =
        await flutter.rootBundle.load('assets/fonts/OpenSans-Regular.ttf');
    final pdfFont = pw.Font.ttf(
      regularFont,
    );

    // Load logo image from assets
    final logoData = await flutter.rootBundle.load('assets/images/logo.png');
    final logo = pw.Image(
      pw.MemoryImage(logoData.buffer.asUint8List()),
      width: 70, // Set explicit width
      // height: 50, // Set explicit height
    );

    // Fetch username from users collection
    final String soldBy = await _fetchUserName(saleData['soldBy']);

    // Add table to PDF
    final tableData = [
      ['NO', 'PRODUK', 'QTY', 'HARGA', 'SUBTOTAL']
    ];

    for (var i = 0; i < saleData['products'].length; i++) {
      var product = saleData['products'][i];
      final int subTotal = product['quantity'] * product['sellPrice'];
      tableData.add([
        (i + 1).toString(),
        product['name'],
        product['quantity'].toString(),
        'Rp ${product['sellPrice']}',
        'Rp ${subTotal}',
      ]);
    }

    final table = pw.Table.fromTextArray(
      data: tableData,
      cellStyle: pw.TextStyle(font: pdfFont),
      headerStyle: pw.TextStyle(font: pdfFont, fontWeight: pw.FontWeight.bold),
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight
      },
      columnWidths: {
        0: pw.FlexColumnWidth(1),
        1: pw.FlexColumnWidth(3),
        2: pw.FlexColumnWidth(1),
        3: pw.FlexColumnWidth(2),
        4: pw.FlexColumnWidth(2),
      },
      border: null,
    );

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header section with logo
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'INVOICE',
                    style: pw.TextStyle(
                      font: pdfFont,
                      fontSize: 40,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8.0),
                    child: logo,
                  ),
                ],
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8.0),
                child: pw.Text(
                  saleData['nomor'] ?? 'nomor Not Found',
                  style: pw.TextStyle(font: pdfFont, fontSize: 16),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8.0),
                child: pw.Text(
                  '${DateFormat('EEEE, d MMMM y', 'id_ID').format(saleData['saleDate'].toDate())}',
                  style: pw.TextStyle(font: pdfFont, fontSize: 16),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8.0),
                child: pw.Text(
                  'Penjual: $soldBy',
                  style: pw.TextStyle(font: pdfFont, fontSize: 16),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8.0),
                child: pw.Divider(thickness: 1),
              ),

              // Table section
              pw.Expanded(
                child: pw.Center(
                  child: table,
                ),
              ),

              // Total Belanja section
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.SizedBox(width: 10), // Spacing
                  pw.Text(
                    'Total Belanja : Rp ${formatRupiah(saleData['totalAmount'])}',
                    style: pw.TextStyle(
                      font: pdfFont,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),

              // Footer section
              pw.Padding(
                padding: const pw.EdgeInsets.all(8.0),
                child: pw.Text(
                  'TERIMA KASIH !\nBarang yang sudah dibeli tidak dapat ditukar.',
                  style: pw.TextStyle(font: pdfFont, fontSize: 16),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Save PDF to Uint8List
    final bytes = await pdf.save();
    return bytes;
  }

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
}
