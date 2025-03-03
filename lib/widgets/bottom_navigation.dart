import 'package:flutter/material.dart';
import 'package:ystore/config/app_color.dart';


class CustomBottomNavigation extends StatelessWidget {
  final String role;
  final int currentIndex;
  final Function(int) onTap; 

  const CustomBottomNavigation({
    Key? key,
    required this.role,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<IconData> icons = [
      Icons.home,
      Icons.search,
      Icons.pie_chart,
      Icons.add_shopping_cart_outlined,
      Icons.notifications_none,
      Icons.person,
    ];

    return Container(
      width: 361,
      height: 64,
      margin: const EdgeInsets.only(left: 16, bottom: 16, right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
        children: List.generate(
          role == 'superAdmin' ? icons.length : icons.length - 1,
          (index) {
            return GestureDetector(
              onTap: () => onTap(index), 
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: currentIndex == index
                      ? AppColor.primary
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    icons[index],
                    color: currentIndex == index
                        ? AppColor.secondary
                        : Colors.grey,
                    size: currentIndex == index ? 30 : 26,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
