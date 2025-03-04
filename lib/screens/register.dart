import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_color.dart';
import '../services/auth_service.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final AuthService _authService = AuthService();

  // Daftar pilihan role
  final List<String> _roles = ['admin', 'kasir', 'superAdmin'];
  String? _selectedRole; // Role default

  // Daftar pilihan status
  final List<String> _statuses = ['active', 'inactive'];
  String? _selectedStatus; // Status default

  Future<void> _register() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String username = _usernameController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Email harus diisi!")),
      );
      return;
    }

    if (!email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Email tidak valid!")),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password harus diisi!")),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password minimal 6 karakter!")),
      );
      return;
    }

    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Username harus diisi!")),
      );
      return;
    }

    try {
      // Daftarkan user ke Firebase Authentication
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Hash password sebelum menyimpannya ke Firestore
      String hashedPassword = _authService.hashPassword(password);

      // Simpan data user ke Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user?.uid)
          .set({
        'username': username,
        'email': email,
        'password': hashedPassword,
        'role': _selectedRole,
        'status': _selectedStatus,
        'createdAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User berhasil ditambahkan!")),
      );

      // Kembali ke halaman manage role
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menambahkan user: ${e.message}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.bg,
      appBar: AppBar(
        backgroundColor: AppColor.bg,
        // title: Text('Tambah User Baru'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Tambah User",
                    style: TextStyle(
                      fontSize: 32,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      color: AppColor.primary,
                    ),
                  ),
                  Image.asset(
                    "assets/images/logo.png",
                    width: 57,
                    height: 57,
                  )
                ],
              ),
              Padding(
                padding: EdgeInsets.only(top: 35),
                child: TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: AppColor.navigation,
                        width: 1,
                      ),
                    ),
                    // jika user focus pada textfield
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: AppColor.navigation, width: 1),
                    ),
                    // jika user tidak focus pada textfield
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: AppColor.navigation, width: 1),
                    ),
                  ),
                  style: TextStyle(
                    color: AppColor.primary,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: AppColor.navigation,
                      width: 1,
                    ),
                  ),
                  // jika user focus pada textfield
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: AppColor.navigation, width: 1),
                  ),
                  // jika user tidak focus pada textfield
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: AppColor.navigation, width: 1),
                  ),
                ),
                style: TextStyle(
                  color: AppColor.primary,
                  fontSize: 16,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: AppColor.navigation,
                      width: 1,
                    ),
                  ),
                  // jika user focus pada textfield
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: AppColor.navigation, width: 1),
                  ),
                  // jika user tidak focus pada textfield
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: AppColor.navigation, width: 1),
                  ),
                ),
                style: TextStyle(
                  color: AppColor.primary,
                  fontSize: 16,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: 20),

              // Dropdown untuk memilih role
              DropdownButton2<String>(
                value: _selectedRole,
                hint: Text("Pilih Role"),
                items: _roles.map((String role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(role),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedRole = newValue!;
                  });
                },
                buttonStyleData: ButtonStyleData(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColor.grey),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  height: 56,
                  width: double.infinity,
                ),
                dropdownStyleData: DropdownStyleData(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: AppColor.white,
                  ),
                  padding: EdgeInsets.symmetric(vertical: 6),
                  maxHeight: 300,
                  elevation: 8,
                  width: 360,
                ),
                menuItemStyleData: MenuItemStyleData(
                  height: 50,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
              SizedBox(height: 20),

              // Dropdown untuk memilih status
              DropdownButton2<String>(
                value: _selectedStatus,
                hint: Text("Pilih Status"),
                items: _statuses.map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedStatus = newValue!;
                  });
                },
                buttonStyleData: ButtonStyleData(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColor.grey),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  height: 56,
                  width: double.infinity,
                ),
                dropdownStyleData: DropdownStyleData(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: AppColor.white,
                  ),
                  padding: EdgeInsets.symmetric(vertical: 6),
                  maxHeight: 300,
                  elevation: 8,
                  width: 360,
                ),
                menuItemStyleData: MenuItemStyleData(
                  height: 50,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
              SizedBox(height: 30),

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
                  onPressed: _register,
                  child: Text(
                    'Tambah User',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'Poppins',
                      color: AppColor.primary,
                    ),
                  ),
                ),
              ),

              // ElevatedButton(
              //   onPressed: _register,
              //   child: Text('Tambah User'),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
