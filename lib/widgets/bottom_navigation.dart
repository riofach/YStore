import 'package:flutter/material.dart';
import 'package:ystore/config/app_color.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  CustomBottomNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  final List<IconData> icons = [
    Icons.home,
    Icons.search,
    Icons.pie_chart,
    Icons.access_time,
    Icons.notifications_none,
    Icons.person,
  ];

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
          return GestureDetector(
            onTap: () => onTap(index),
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
