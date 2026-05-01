import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';

class CurrentLocationButtonWidget extends StatelessWidget {
  const CurrentLocationButtonWidget({
    super.key,
    required this.isLoading,
    required this.onTap,
  });

  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: const StadiumBorder(),
      child: TextButton(
        onPressed: isLoading ? null : onTap,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary600,
          backgroundColor: Colors.white,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          overlayColor: AppColors.primary50.withValues(alpha: 0.2),
          disabledForegroundColor: AppColors.primary400,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: const StadiumBorder(),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.my_location,
                    size: 19,
                    color: AppColors.primary600,
                  ),
            const SizedBox(width: 8),
            Text(
              'Current Location',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
