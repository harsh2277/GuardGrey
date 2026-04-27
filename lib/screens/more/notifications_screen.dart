import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const List<_NotificationItem> _notifications = [
    _NotificationItem(
      title: 'Attendance Updated',
      message: 'Ravi Patel marked present for the morning shift.',
      time: '10 min ago',
    ),
    _NotificationItem(
      title: 'Site Visit Logged',
      message: 'Office Building visit was completed by Heena Shah.',
      time: '32 min ago',
    ),
    _NotificationItem(
      title: 'Manager Activity',
      message: 'Amit Joshi updated the Warehouse Gate notes.',
      time: '1 hr ago',
    ),
    _NotificationItem(
      title: 'Daily Summary Ready',
      message: 'Today\'s attendance summary is available to review.',
      time: 'Today',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final notifications = _notifications;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Notifications',
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: notifications.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.neutral200,
              ),
              itemBuilder: (context, index) {
                final item = notifications[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.neutral900,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.message,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.neutral600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        item.time,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.neutral500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
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
                Icons.notifications_none_rounded,
                color: AppColors.primary600,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationItem {
  const _NotificationItem({
    required this.title,
    required this.message,
    required this.time,
  });

  final String title;
  final String message;
  final String time;
}
