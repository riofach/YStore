import 'package:flutter/material.dart';
import 'package:ystore/config/app_color.dart';
import 'package:ystore/screens/dashboard_screen.dart';
import 'package:ystore/screens/manage_product.dart';
import 'package:ystore/screens/manage_purchases.dart';
import 'package:ystore/screens/manage_role.dart';
import 'package:ystore/screens/manage_sales.dart';
import 'package:ystore/screens/notifications_screen.dart';

class CustomBottomNavBar extends StatefulWidget {
  final String role;
  final String userId;
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavBar({
    super.key,
    required this.role,
    required this.userId,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  // icon untuk role superAdmin
  final List<IconData> superAdminIcons = const [
    Icons.home,
    Icons.person_2_outlined,
    Icons.inventory_outlined,
    Icons.bar_chart_outlined,
    Icons.add_shopping_cart_outlined,
    Icons.notifications_none,
  ];

  // Icon untuk user dengan role selain superAdmin
  final List<IconData> otherRoleIcons = const [
    Icons.home,
    Icons.inventory_outlined,
    Icons.bar_chart_outlined,
    Icons.add_shopping_cart_outlined,
    Icons.notifications_none,
  ];

  Widget _getBody(int index) {
    if (widget.role == 'superAdmin')
    // login sebagai super admin
    {
      switch (index) {
        case 0:
          return DashboardScreen(userId: widget.userId);
        case 1:
          return ManageRoleScreen(role: widget.role);
        case 2:
          return ManageProductScreen(role: widget.role);
        case 3:
          return ManageSalesScreen();
        case 4:
          return ManagePurchasesScreen();
        case 5:
          return NotificationsScreen();
        default:
          return DashboardScreen(userId: widget.userId);
      }
    } else {
      // akses untuk non super admin
      switch (index) {
        case 0:
          return DashboardScreen(userId: widget.userId);
        case 1:
          return ManageProductScreen(role: widget.role);
        case 2:
          return ManageSalesScreen();
        case 3:
          return ManagePurchasesScreen();
        case 4:
          return NotificationsScreen();
        default:
          return DashboardScreen(userId: widget.userId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pilih daftar ikon berdasarkan role
    final List<IconData> icons =
        widget.role == 'superAdmin' ? superAdminIcons : otherRoleIcons;

    return Scaffold(
        body: _getBody(widget.selectedIndex),
        bottomNavigationBar: Container(
          width: 362,
          height: 64,
          margin: const EdgeInsets.only(left: 16, bottom: 16, right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: AppColor.white,
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
            children: List.generate(
              icons.length, // Gunakan panjang daftar ikon yang sesuai
              (index) {
                return GestureDetector(
                  onTap: () => widget.onItemTapped(
                      index), // Panggil callback saat tombol ditekan
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: widget.selectedIndex == index
                          ? AppColor.primary // Warna saat tombol aktif
                          : Colors.transparent, // Warna saat tombol tidak aktif
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        icons[index],
                        color: widget.selectedIndex == index
                            ? AppColor.secondary // Warna ikon saat tombol aktif
                            : AppColor
                                .navigation, // Warna ikon saat tombol tidak aktif
                        size: widget.selectedIndex == index
                            ? 33
                            : 29, // Ukuran ikon
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ));
  }
}

class MainScreen extends StatefulWidget {
  final String role;
  final String userId;

  const MainScreen({Key? key, required this.role, required this.userId})
      : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomBottomNavBar(
      role: widget.role,
      userId: widget.userId,
      selectedIndex: _selectedIndex,
      onItemTapped: _onItemTapped,
    );
  }
}
