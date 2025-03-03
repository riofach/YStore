import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ystore/config/app_color.dart';
import '../services/auth_service.dart';
import 'register.dart'; // Untuk navigasi setelah logout

class ManageRoleScreen extends StatefulWidget {
  final String role;

  ManageRoleScreen({required this.role});

  @override
  _ManageRoleScreenState createState() => _ManageRoleScreenState();
}

class _ManageRoleScreenState extends State<ManageRoleScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // int _currentIndex = 1;
  String _searchQuery = '';

  // Fungsi untuk mengubah status user
  Future<void> _toggleUserStatus(String userId, String currentStatus) async {
    try {
      String newStatus = currentStatus == 'active' ? 'inactive' : 'active';
      await _firestore.collection('users').doc(userId).update({
        'status': newStatus,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Status user berhasil diubah!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mengubah status user: $e")),
      );
    }
  }

  // void _onBottomNavigationTapped(int index) {
  //   if (_currentIndex == index) return;

  //   setState(() {
  //     _currentIndex = index;
  //   });

  //   switch (index) {
  //     case 0:
  //       Navigator.pushAndRemoveUntil(
  //         context,
  //         MaterialPageRoute(
  //             builder: (context) => DashboardScreen(role: widget.role)),
  //         (route) => false,
  //       );
  //       break;
  //     case 1:
  //       Navigator.pushAndRemoveUntil(
  //         context,
  //         MaterialPageRoute(
  //             builder: (context) => ManageProductScreen(role: widget.role)),
  //         (route) => false,
  //       );
  //       break;
  //     case 2:
  //       Navigator.pushAndRemoveUntil(
  //         context,
  //         MaterialPageRoute(builder: (context) => ManageSalesScreen()),
  //         (route) => false,
  //       );
  //       break;
  //     case 3:
  //       Navigator.pushAndRemoveUntil(
  //         context,
  //         MaterialPageRoute(builder: (context) => ManagePurchasesScreen()),
  //         (route) => false,
  //       );
  //       break;
  //     case 4:
  //       Navigator.pushAndRemoveUntil(
  //         context,
  //         MaterialPageRoute(builder: (context) => NotificationsScreen()),
  //         (route) => false,
  //       );
  //       break;
  //     case 5:
  //       break;
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.bg,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.only(top: 63.0, left: 10.0, right: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Kelola User",
                    style: TextStyle(
                      fontSize: 32,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      color: AppColor.primary,
                    ),
                  ),
                  Image.asset(
                    'assets/images/logo.png',
                    width: 57,
                    height: 57,
                  )
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.only(top: 24.0, left: 10.0, right: 10.0),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelText: 'Cari berdasarkan email atau role',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users')
                    .where('role', whereIn: ['admin', 'kasir']).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                        child: Text("Terjadi error: ${snapshot.error}"));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text("Tidak ada data user."));
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      Map<String, dynamic> data = snapshot.data!.docs[index]
                          .data() as Map<String, dynamic>;

                      // Filter berdasarkan pencarian
                      if (_searchQuery.isNotEmpty &&
                          !data['email'].toLowerCase().contains(_searchQuery) &&
                          !data['role'].toLowerCase().contains(_searchQuery)) {
                        return Container();
                      }
                      return Container(
                        margin: EdgeInsets.only(bottom: 18),
                        child: Card(
                          color: AppColor.white,
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ListTile(
                            title: Text(
                              data['email'],
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColor.primary,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              "Role: ${data['role']}, Status: ${data['status']}",
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColor.grey,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            trailing: Switch(
                              value: data['status'] == 'active',
                              onChanged: (bool newValue) {
                                _toggleUserStatus(snapshot.data!.docs[index].id,
                                    data['status']);
                              },
                              activeColor:
                                  AppColor.orange, // Warna orange saat aktif
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigasi ke halaman tambah user (register.dart)
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RegisterScreen()),
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
}
