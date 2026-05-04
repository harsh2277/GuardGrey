import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/routes/app_routes.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_MoreSection> sections = const [
      _MoreSection(
        title: 'Management',
        items: [
          _MoreItem(
            icon: Icons.business_rounded,
            title: 'Clients',
            routeName: AppRoutes.adminClients,
          ),
          _MoreItem(
            icon: Icons.groups_rounded,
            title: 'Managers',
            routeName: AppRoutes.adminManagers,
          ),
          _MoreItem(
            icon: Icons.account_tree_rounded,
            title: 'Branches',
            routeName: AppRoutes.adminBranches,
          ),
          _MoreItem(
            icon: Icons.event_note_rounded,
            title: 'Manager Leave',
            routeName: AppRoutes.adminLeaves,
          ),
        ],
      ),
      _MoreSection(
        title: 'Analytics',
        items: [
          _MoreItem(
            icon: Icons.location_on_outlined,
            title: 'Field Visit',
            routeName: AppRoutes.adminFieldVisits,
          ),
          _MoreItem(
            icon: Icons.location_searching_rounded,
            title: 'Live Tracking',
            routeName: AppRoutes.adminLiveTracking,
          ),
        ],
      ),
      _MoreSection(
        title: 'Account',
        items: [
          _MoreItem(
            icon: Icons.person_rounded,
            title: 'Profile',
            routeName: AppRoutes.adminProfile,
          ),
          _MoreItem(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            routeName: AppRoutes.adminNotifications,
          ),
          _MoreItem(
            icon: Icons.settings_rounded,
            title: 'Settings',
            routeName: AppRoutes.adminSettings,
          ),
        ],
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
        itemCount: sections.length,
        separatorBuilder: (context, index) => const SizedBox(height: 20),
        itemBuilder: (context, index) {
          final section = sections[index];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.title,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.neutral500,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              ...section.items.asMap().entries.map((entry) {
                final item = entry.value;
                final isLast = entry.key == section.items.length - 1;

                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                  child: Material(
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
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _MoreSection {
  const _MoreSection({required this.title, required this.items});

  final String title;
  final List<_MoreItem> items;
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
