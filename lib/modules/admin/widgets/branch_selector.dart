import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/branch_model.dart';

class BranchSelector extends StatelessWidget {
  final String? value;
  final List<BranchModel> branches;
  final ValueChanged<String?> onChanged;

  const BranchSelector({
    super.key,
    required this.value,
    required this.branches,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      items: branches
          .map(
            (branch) => DropdownMenuItem<String>(
              value: branch.id,
              child: Text(branch.name),
            ),
          )
          .toList(),
      onChanged: onChanged,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.neutral500,
      ),
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.neutral800,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: 'Select branch',
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.neutral400,
        ),
        filled: true,
        fillColor: AppColors.neutral50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.neutral200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.neutral200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary500, width: 1.5),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Branch is required';
        }
        return null;
      },
    );
  }
}
