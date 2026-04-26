import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class SiteInputField extends StatelessWidget {
  final int index;
  final TextEditingController controller;
  final VoidCallback? onRemove;
  final bool canRemove;

  const SiteInputField({
    super.key,
    required this.index,
    required this.controller,
    this.onRemove,
    this.canRemove = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Site ${index + 1}',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.neutral400,
              ),
              filled: true,
              fillColor: AppColors.neutral50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
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
                borderSide: const BorderSide(
                  color: AppColors.primary500,
                  width: 1.5,
                ),
              ),
            ),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.neutral800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (canRemove) ...[
          const SizedBox(width: 10),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.error,
                size: 20,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
