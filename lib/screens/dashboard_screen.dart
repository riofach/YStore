import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:ystore/config/app_color.dart';
import '../services/auth_service.dart';
import 'login.dart';

class DashboardScreen extends StatefulWidget {
  final String role;
  final AuthService _authService = AuthService();

  DashboardScreen({required this.role});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, double> salesData = {};
  List<Color> colors = [];
  double totalRevenue = 0.0;
  double totalExpenses = 0.0;

  Stream<Map<String, double>> _fetchSalesData() {
    DateTime now = DateTime.now();
    DateTime startOfMonth = DateTime(now.year, now.month, 1);
    DateTime endOfMonth = DateTime(now.year, now.month + 1, 0);

    return _firestore
        .collection('sales')
        .where('saleDate', isGreaterThanOrEqualTo: startOfMonth)
        .where('saleDate', isLessThanOrEqualTo: endOfMonth)
        .snapshots()
        .map((snapshot) {
      Map<String, double> tempData = {};
      double revenue = 0.0;
      for (var sale in snapshot.docs) {
        Map<String, dynamic> saleData = sale.data() as Map<String, dynamic>;
        revenue += saleData['totalAmount'] ?? 0.0;
        for (var product in saleData['products']) {
          String productName = product['name'] ?? 'Unknown';
          int quantity = product['quantity'] ?? 0;
          tempData[productName] = (tempData[productName] ?? 0) + quantity;
        }
      }
      totalRevenue = revenue;
      return tempData;
    }).map((tempData) {
      List<MapEntry<String, double>> sortedEntries = tempData.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return Map.fromEntries(sortedEntries.take(10));
    });
  }

  Stream<double> _fetchTotalExpenses() {
    DateTime now = DateTime.now();
    DateTime startOfMonth = DateTime(now.year, now.month, 1);
    DateTime endOfMonth = DateTime(now.year, now.month + 1, 0);

    return _firestore
        .collection('purchases')
        .where('purchaseDate', isGreaterThanOrEqualTo: startOfMonth)
        .where('purchaseDate', isLessThanOrEqualTo: endOfMonth)
        .snapshots()
        .map((snapshot) {
      double expenses = 0.0;
      for (var purchase in snapshot.docs) {
        Map<String, dynamic> purchaseData =
            purchase.data() as Map<String, dynamic>;
        expenses += purchaseData['totalAmount'] ?? 0.0;
      }
      return expenses;
    });
  }

  String formatRupiah(double amount) {
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    print('Role saat build: ${widget.role}');
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard YStore'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await widget._authService.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Selamat datang, Anda login sebagai ${widget.role}'),
              SizedBox(height: 20),
              Text('Penjualan Produk Terlaris Bulan Ini',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              StreamBuilder<Map<String, double>>(
                stream: _fetchSalesData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else {
                    Map<String, double> salesData = snapshot.data ?? {};
                    if (salesData.isNotEmpty) {
                      colors = List.generate(
                          salesData.length, (index) => generateRandomColor());
                    }

                    return salesData.isEmpty
                        ? Text('Tidak ada data penjualan bulan ini')
                        : Column(
                            children: [
                              SizedBox(
                                height: 300, // Set fixed height for pie chart
                                child: PieChart(
                                  PieChartData(
                                    sections: salesData.entries.map((entry) {
                                      int index = salesData.keys
                                          .toList()
                                          .indexOf(entry.key);
                                      return PieChartSectionData(
                                        value: entry.value,
                                        color: colors[index],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: salesData.entries.map((entry) {
                                  int index = salesData.keys
                                      .toList()
                                      .indexOf(entry.key);
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: colors[index],
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            '${entry.key}: ${entry.value}',
                                            style:
                                                TextStyle(color: Colors.black),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          );
                  }
                },
              ),
              SizedBox(height: 20),
              StreamBuilder<double>(
                stream: _fetchTotalExpenses(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else {
                    totalExpenses = snapshot.data ?? 0.0;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Card(
                            color: AppColor.primary,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Total Pendapatan',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColor.white,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    formatRupiah(totalRevenue),
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColor.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Card(
                            color: AppColor.primary,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Total Pengeluaran',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColor.white,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    formatRupiah(totalExpenses),
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColor.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color generateRandomColor() {
    return Color.fromRGBO(
      Random().nextInt(256),
      Random().nextInt(256),
      Random().nextInt(256),
      1,
    );
  }
}
