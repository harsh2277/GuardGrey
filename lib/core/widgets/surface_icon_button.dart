import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';

class SurfaceIconButton extends StatelessWidget {
  const SurfaceIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 50,
    this.iconSize = 22,
    this.borderRadius = 18,
    this.iconColor = AppColors.neutral700,
    this.backgroundColor = AppColors.neutral100,
    this.borderColor = AppColors.neutral200,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;
  final double borderRadius;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: borderColor),
          ),
          child: Icon(icon, size: iconSize, color: iconColor),
        ),
      ),
    );
  }
}
