import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:ystore/config/app_assets.dart';
import 'package:ystore/config/app_color.dart';
import 'package:ystore/widgets/bottom_custom.dart';
import 'package:ystore/widgets/bottom_navigation.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isPasswordVisible = false;

  Future<void> _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Email dan password harus diisi!")),
      );
      return;
    }

    // Tampilan loading screen
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/loading.json',
              width: 100,
              height: 100,
            ),
            const SizedBox(height: 10),
            Text(
              'Mohon Tunggu Sebentar...',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    try {
      // tunda ke next screen selama 2 detik
      await Future.delayed(const Duration(seconds: 2));

      // Login dengan Firebase Authentication
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Ambil data user dari Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user?.uid)
          .get();

      if (!userDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User tidak terdaftar!")),
        );
        return;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      // Verifikasi password yang di-hash
      bool isPasswordValid = _authService.verifyPassword(
        password,
        userData['password'],
      );

      // Verifikasi status user
      if (userData['status'] == 'inactive') {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Akun Anda tidak aktif!")),
        );
        return;
      }

      if (isPasswordValid) {
        // ignore: use_build_context_synchronously
        if (context.mounted)
          Navigator.of(context)
              .pop(); // tutup dialog screen jika login berhasil
        print(
            'Role sebelum navigasi: ${userData['role']}'); // Log role sebelum navigasi

        // Berhasil login, redirect ke dashboard
        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen(
              role: userData['role'],
              userId: userCredential.user?.uid ?? '',
            ),
          ),
        );
      } else {
        // ignore: use_build_context_synchronously
        if (context.mounted)
          Navigator.of(context)
              .pop(); // tutup loading screen jika password salah
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Password salah!")),
        );
      }
    } on FirebaseAuthException catch (e) {
      // ignore: use_build_context_synchronously
      if (context.mounted)
        Navigator.of(context).pop(); // tutup loading screen jika login gagal
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login gagal: ${e.message}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.bg,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: AppColor.secondary.withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        AppAssets.logo,
                        width: 118,
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                    const SizedBox(
                      height: 40,
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Text(
                            'Selamat Datang!',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall!
                                .copyWith(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 24,
                                  color: AppColor.primary,
                                ),
                          ),
                          Text(
                            'Masukkan Akun Anda',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium!
                                .copyWith(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                  color: AppColor.grey,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    TextFormField(
                      controller: _emailController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        hintText: 'Email',
                        hintStyle: TextStyle(color: AppColor.grey),
                        prefixIcon: const Icon(Icons.email),
                        prefixIconColor: AppColor.grey,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: AppColor.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        hintText: 'Password',
                        hintStyle: TextStyle(color: AppColor.grey),
                        prefixIcon: const Icon(Icons.password),
                        prefixIconColor: AppColor.grey,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        suffixIconColor: AppColor.grey,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: AppColor.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    BottomCustom(
                      label: 'Login',
                      isExpand: false,
                      onTap: () {
                        _login();
                      },
                      borderRadius: 50,
                      width: 122,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
