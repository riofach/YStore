import 'package:flutter/material.dart';
import 'package:ystore/config/app_color.dart';

class BottomCustom extends StatelessWidget {
  const BottomCustom({
    super.key,
    required this.label,
    required this.onTap,
    this.isExpand,
    this.borderRadius = 8,
    this.width,
  });

  final String label;
  final Function onTap;
  final bool? isExpand;
  final double borderRadius;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: width ?? (isExpand == true ? double.infinity : 361),
      child: Stack(
        children: [
          Align(
            alignment: const Alignment(0, 0.7),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 116, 146, 170),
                    offset: const Offset(0, 1),
                    blurRadius: 50,
                  ),
                ],
              ),
              width: width ?? (isExpand == true ? double.infinity : 361),
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Align(
            child: Material(
              color: AppColor.secondary,
              borderRadius: BorderRadius.circular(borderRadius),
              child: InkWell(
                borderRadius: BorderRadius.circular(borderRadius),
                onTap: () => onTap(),
                child: Container(
                  width: width ?? (isExpand == true ? double.infinity : 361),
                  height: 52,
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
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
