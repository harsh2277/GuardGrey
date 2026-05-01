import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/core/widgets/section_header.dart';

class ManagerSurfaceCard extends StatelessWidget {
  const ManagerSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (onTap == null) {
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.neutral200),
        ),
        child: child,
      );
    }

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.neutral200),
          ),
          child: child,
        ),
      ),
    );
  }
}

class ManagerStatusChip extends StatelessWidget {
  const ManagerStatusChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final normalized = label.trim().toLowerCase();
    Color background = AppColors.primary50;
    Color foreground = AppColors.primary700;

    if (normalized.contains('complete') ||
        normalized.contains('present') ||
        normalized.contains('approved')) {
      background = AppColors.successLight;
      foreground = AppColors.successDark;
    } else if (normalized.contains('pending') ||
        normalized.contains('progress') ||
        normalized.contains('late')) {
      background = AppColors.warningLight;
      foreground = AppColors.warningDark;
    } else if (normalized.contains('missed') ||
        normalized.contains('absent') ||
        normalized.contains('reject')) {
      background = AppColors.errorLight;
      foreground = AppColors.errorDark;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class ManagerEmptyState extends StatelessWidget {
  const ManagerEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.action,
  });

  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary50,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.inbox_outlined,
                color: AppColors.primary600,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.neutral500,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}

class ManagerListCard extends StatelessWidget {
  const ManagerListCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.meta,
    this.status,
    this.icon = Icons.folder_open_outlined,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String? meta;
  final String? status;
  final IconData icon;
  final VoidCallback? onTap;

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
                child: Icon(icon, color: AppColors.primary600, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.neutral900,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.neutral600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (meta != null && meta!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        meta!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.neutral500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (status != null && status!.trim().isNotEmpty) ...[
                    ManagerStatusChip(label: status!),
                    const SizedBox(height: 10),
                  ],
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: AppColors.neutral400,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ManagerFormLabel extends StatelessWidget {
  const ManagerFormLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.neutral800,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class ManagerSectionTitle extends StatelessWidget {
  const ManagerSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SectionHeader(title: title);
  }
}
