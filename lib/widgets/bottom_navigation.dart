import 'package:flutter/material.dart';
import 'package:ystore/config/app_color.dart';
import 'package:ystore/screens/dashboard_screen.dart';
import 'package:ystore/screens/manage_product.dart';
import 'package:ystore/screens/manage_sales.dart';
import 'package:ystore/screens/manage_purchases.dart';
import 'package:ystore/screens/notifications_screen.dart';
import 'package:ystore/screens/manage_role.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final String role;
  final ValueChanged<int> onTap;

  CustomBottomNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.role,
  }) : super(key: key);

  final List<IconData> icons = [
    Icons.home,
    Icons.search,
    Icons.pie_chart,
    Icons.add_shopping_cart_outlined,
    Icons.notifications_none,
    Icons.person,
  ];

  // Menambahkan routes yang sesuai dengan icons
  Map<int, WidgetBuilder> _routes(BuildContext context) {
    return {
      0: (context) => DashboardScreen(role: role),
      1: (context) => ManageProductScreen(role: role),
      2: (context) => ManageSalesScreen(),
      3: (context) => ManagePurchasesScreen(),
      4: (context) => NotificationsScreen(),
      if (role == 'superAdmin') 5: (context) => ManageRoleScreen(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 361,
      height: 64,
      margin: EdgeInsets.only(
          left: 16, bottom: 16, right: 16), // Tambahkan margin kanan
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(icons.length, (index) {
          final WidgetBuilder? routeBuilder = _routes(context)[index];
          if (routeBuilder == null) {
            return SizedBox
                .shrink(); // Jangan tampilkan icon jika route tidak ada
          }
          return GestureDetector(
            onTap: () {
              if (_routes(context).containsKey(index)) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: _routes(context)[index]!),
                  (route) => false,
                );
              }
              onTap(index);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: currentIndex == index
                    ? AppColor.primary
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icons[index],
                color: currentIndex == index
                    ? const Color.fromARGB(255, 119, 151, 209)
                    : Colors.grey,
                size: currentIndex == index ? 30 : 26,
              ),
            ),
          );
        }),
      ),
    );
  }
}
