import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class LocationInputField extends StatelessWidget {
  const LocationInputField({
    super.key,
    required this.onTap,
    this.address,
    this.errorText,
  });

  final VoidCallback onTap;
  final String? address;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final hasAddress = address != null && address!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: InputDecorator(
              isFocused: false,
              isEmpty: !hasAddress,
              expands: false,
              decoration: InputDecoration(
                hintText: 'Select location',
                prefixIcon: const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.neutral500,
                  size: 20,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                ),
                suffixIcon: const Icon(
                  Icons.map_outlined,
                  color: AppColors.primary600,
                  size: 20,
                ),
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                ),
                errorText: errorText,
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
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.error),
                ),
              ),
              child: Text(
                hasAddress ? address!.trim() : 'Select location',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: hasAddress
                      ? AppColors.neutral800
                      : AppColors.neutral400,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
