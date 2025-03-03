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
      width: width ?? (isExpand == true ? double.infinity : 361),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.secondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: 5,
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        onPressed: () => onTap(),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            fontFamily: 'Poppins',
            color: AppColor.primary,
          ),
        ),
      ),
    );
  }
}
