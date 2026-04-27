import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class SearchLocationBar extends StatelessWidget {
  const SearchLocationBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.isLoading = false,
    this.height = 48,
    this.borderRadius = 24,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool isLoading;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          return TextField(
            controller: controller,
            onChanged: onChanged,
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              hintText: 'Search location',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.neutral500,
                size: 20,
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 44,
                minHeight: 48,
              ),
              suffixIcon: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : value.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            controller.clear();
                            onChanged('');
                          },
                          splashRadius: 18,
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.neutral500,
                            size: 18,
                          ),
                        )
                      : null,
              suffixIconConstraints: const BoxConstraints(
                minWidth: 44,
                minHeight: 48,
              ),
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.neutral400,
              ),
              filled: true,
              fillColor: AppColors.neutral100,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide.none,
              ),
            ),
          );
        },
      ),
    );
  }
}
