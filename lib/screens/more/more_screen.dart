import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../routes/app_routes.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_MoreItem> items = const [
      _MoreItem(
        icon: Icons.groups_rounded,
        title: 'Managers',
        routeName: AppRoutes.managers,
      ),
      _MoreItem(
        icon: Icons.account_tree_rounded,
        title: 'Branches',
        routeName: AppRoutes.branches,
      ),
      _MoreItem(
        icon: Icons.assessment_rounded,
        title: 'Reports',
        routeName: AppRoutes.reports,
      ),
      _MoreItem(
        icon: Icons.person_rounded,
        title: 'Profile',
        routeName: AppRoutes.profile,
      ),
      _MoreItem(
        icon: Icons.settings_rounded,
        title: 'Settings',
        routeName: AppRoutes.settings,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'More',
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = items[index];

          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Navigator.pushNamed(context, item.routeName),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.neutral200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary50,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        item.icon,
                        color: AppColors.primary600,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        item.title,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.neutral900,
                        ),
                      ),
                    ),
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
        },
      ),
    );
  }
}

class _MoreItem {
  const _MoreItem({
    required this.icon,
    required this.title,
    required this.routeName,
  });

  final IconData icon;
  final String title;
  final String routeName;
}
