import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/modules/location/models/location_search_result.dart';

class SearchDropdown extends StatelessWidget {
  const SearchDropdown({
    super.key,
    required this.results,
    required this.onSelected,
    this.errorText,
    this.showNoResults = false,
  });

  final List<LocationSearchResult> results;
  final ValueChanged<LocationSearchResult> onSelected;
  final String? errorText;
  final bool showNoResults;

  @override
  Widget build(BuildContext context) {
    final bool hasMessage = (errorText?.isNotEmpty ?? false) || showNoResults;

    return Material(
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 260),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.neutral200),
        ),
        child: hasMessage
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      errorText != null
                          ? Icons.error_outline_rounded
                          : Icons.search_off_rounded,
                      color: errorText != null
                          ? AppColors.error
                          : AppColors.neutral500,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        errorText ?? 'No results found',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: errorText != null
                              ? AppColors.error
                              : AppColors.neutral600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: results.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: AppColors.neutral200,
                ),
                itemBuilder: (context, index) {
                  final result = results[index];
                  return InkWell(
                    onTap: () => onSelected(result),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.location_on_outlined,
                              color: AppColors.primary600,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              result.displayName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.neutral800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
