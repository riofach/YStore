import 'dart:async';

import 'package:another_flutter_splash_screen/another_flutter_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ystore/config/app_color.dart';
import 'package:ystore/screens/login.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FlutterSplashScreen.fadeIn(
      backgroundColor: AppColor.primary,
      onInit: () {
        debugPrint("On Init");
      },
      onEnd: () {
        debugPrint("On End");
      },
      childWidget: Container(
        width: 250,
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize
              .min, //untuk mengambil ruang yang dibutuhkan content saja
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
                height: 210,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    "assets/images/logo.png",
                    fit: BoxFit.cover,
                  ),
                )),
            const SizedBox(
              height: 20,
            ),
            const Text(
              "Yudi Store",
              style: TextStyle(
                color: AppColor.white,
                fontSize: 20,
                fontFamily: "Poppins",
                fontWeight: FontWeight.w600,
              ),
            ),
            // Animasi loading screen
            const SizedBox(
              height: 20,
            ),
            const SpinKitThreeBounce(
              color: AppColor.white,
              size: 24.0,
              duration: Duration(milliseconds: 1500),
            )
          ],
        ),
      ),
      onAnimationEnd: () {
        debugPrint("On Fade In End");
        Timer(const Duration(milliseconds: 1500), () {});
      },
      nextScreen: LoginScreen(),
      duration: const Duration(milliseconds: 3000),
    );
  }
}
