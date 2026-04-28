import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';

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
    final displayText = hasAddress ? address!.trim() : 'Add location';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      displayText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: hasAddress
                            ? AppColors.neutral800
                            : AppColors.neutral500,
                        fontWeight: hasAddress
                            ? FontWeight.w500
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.neutral500,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              errorText!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ],
    );
  }
}
