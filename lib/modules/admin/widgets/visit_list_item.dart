import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/visit_model.dart';

class VisitListItem extends StatelessWidget {
  final VisitModel visit;

  const VisitListItem({super.key, required this.visit});

  Color get _statusColor {
    switch (visit.status) {
      case 'Completed':
        return AppColors.success;
      case 'In Progress':
        return AppColors.primary600;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  visit.managerName,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.neutral900,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  visit.status,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: _statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${visit.date} • ${visit.time}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.neutral500,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (visit.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              visit.notes,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.neutral700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
