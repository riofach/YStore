import 'package:flutter/material.dart';
import 'package:ystore/config/app_color.dart';

class BottomCustom extends StatelessWidget {
  const BottomCustom({
    super.key,
    required this.label,
    required this.onTap,
    this.isExpand,
  });

  final String label;
  final Function onTap;
  final bool? isExpand;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Stack(
        children: [
          Align(
            alignment: const Alignment(0, 0.7),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 116, 146, 170),
                    offset: const Offset(0, 1),
                    blurRadius: 50,
                  ),
                ],
              ),
              width: isExpand == true ? double.infinity : 122,
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(label),
            ),
          ),
          Align(
            child: Material(
              color: AppColor.secondary,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => onTap(),
                child: Container(
                  width: isExpand == true ? double.infinity : 122,
                  height: 40,
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
