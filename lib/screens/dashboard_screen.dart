import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login.dart';
import 'manage_role.dart';
import 'manage_product.dart';
import 'manage_sales.dart';
import 'notifications_screen.dart'; // Import notifications screen
import 'manage_purchases.dart'; // Import manage purchases screen

class DashboardScreen extends StatelessWidget {
  final String role;
  final AuthService _authService = AuthService();

  DashboardScreen({required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard YStore'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await _authService.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Selamat datang, Anda login sebagai $role'),
            if (role == 'superAdmin')
              ElevatedButton(
                onPressed: () {
                  // Navigasi ke halaman manage role
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ManageRoleScreen()),
                  );
                },
                child: Text('Kelola Role/User'),
              ),
            if (role == 'admin' || role == 'superAdmin' || role == 'kasir')
              ElevatedButton(
                onPressed: () {
                  // Navigasi ke halaman manage product
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ManageProductScreen(role: role),
                    ),
                  );
                },
                child: Text('Kelola Produk'),
              ),
            ElevatedButton(
              onPressed: () {
                // Navigasi ke halaman manage sales
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ManageSalesScreen()),
                );
              },
              child: Text('Kelola Penjualan'),
            ),
            ElevatedButton(
              onPressed: () {
                // Navigasi ke halaman manage purchases
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ManagePurchasesScreen()),
                );
              },
              child: Text('Kelola Pembelian'),
            ),
            ElevatedButton(
              onPressed: () {
                // Navigasi ke halaman notifications
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => NotificationsScreen()),
                );
              },
              child: Text('Notifikasi'),
            ),
          ],
        ),
      ),
    );
  }
}
