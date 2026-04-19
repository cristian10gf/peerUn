import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TeacherBackButton extends StatelessWidget {
  final String? route;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color iconColor;

  const TeacherBackButton({
    super.key,
    this.route,
    this.onTap,
    required this.backgroundColor,
    required this.iconColor,
  }) : assert(route != null || onTap != null);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Get.back(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_back,
          size: 20,
          color: iconColor,
        ),
      ),
    );
  }
}