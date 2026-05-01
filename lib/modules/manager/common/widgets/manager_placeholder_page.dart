import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';

class ManagerPlaceholderPage extends StatelessWidget {
  const ManagerPlaceholderPage({
    super.key,
    required this.title,
    required this.label,
  });

  final String title;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          title,
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: Center(
        child: Text(
          label,
          style: AppTextStyles.headingMedium.copyWith(
            color: AppColors.neutral700,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
