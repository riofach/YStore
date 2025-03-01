import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/auth_service.dart';
import 'login.dart';
import 'manage_role.dart';
import 'manage_product.dart';
import 'manage_sales.dart';
import 'notifications_screen.dart';
import 'manage_purchases.dart';

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

  Stream<Map<String, double>> _fetchSalesData() {
    DateTime now = DateTime.now();
    DateTime startOfMonth = DateTime(now.year, now.month, 1);
    DateTime endOfMonth = DateTime(now.year, now.month + 1, 0);

    return _firestore
        .collection('sales')
        .where('saleDate', isGreaterThanOrEqualTo: startOfMonth)
        .where('saleDate', isLessThanOrEqualTo: endOfMonth)
        .snapshots()
        .asyncMap((snapshot) async {
      Map<String, double> tempData = {};
      for (var sale in snapshot.docs) {
        Map<String, dynamic> saleData = sale.data() as Map<String, dynamic>;
        for (var product in saleData['products']) {
          String productName = product['name'] ?? 'Unknown';
          int quantity = product['quantity'] ?? 0;
          tempData[productName] = (tempData[productName] ?? 0) + quantity;
        }
      }
      return tempData;
    }).map((tempData) {
      List<MapEntry<String, double>> sortedEntries = tempData.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return Map.fromEntries(sortedEntries.take(10));
    });
  }

  @override
  Widget build(BuildContext context) {
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
      body: StreamBuilder<Map<String, double>>(
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

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Selamat datang, Anda login sebagai ${widget.role}'),
                    SizedBox(height: 20),
                    Text('Penjualan Produk Terlaris Bulan Ini',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    salesData.isEmpty
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
                                            '${entry.key}',
                                            // '${entry.key}: ${entry.value} Item',
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
                          ),
                    SizedBox(height: 20),
                    if (widget.role == 'superAdmin')
                      ElevatedButton(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ManageRoleScreen())),
                        child: Text('Kelola Role/User'),
                      ),
                    if (widget.role == 'admin' ||
                        widget.role == 'superAdmin' ||
                        widget.role == 'kasir')
                      ElevatedButton(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    ManageProductScreen(role: widget.role))),
                        child: Text('Kelola Produk'),
                      ),
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ManageSalesScreen())),
                      child: Text('Kelola Penjualan'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ManagePurchasesScreen())),
                      child: Text('Kelola Pembelian'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => NotificationsScreen())),
                      child: Text('Notifikasi'),
                    ),
                  ],
                ),
              ),
            );
          }
        },
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
