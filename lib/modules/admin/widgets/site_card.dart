import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/site_model.dart';

class SiteCard extends StatelessWidget {
  final SiteModel site;
  final String branchName;
  final VoidCallback onTap;

  const SiteCard({
    super.key,
    required this.site,
    required this.branchName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.neutral200),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.location_city_rounded,
                  color: AppColors.primary600,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      site.name,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.neutral900,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      branchName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.neutral600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 14,
                          color: AppColors.neutral400,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            site.location,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.neutral500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: site.isActive ? AppColors.success : AppColors.warning,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.neutral400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
