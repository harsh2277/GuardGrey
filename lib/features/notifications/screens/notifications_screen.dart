import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/data/models/app_notification.dart';
import 'package:guardgrey/features/notifications/services/notification_module.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key, this.title = 'Notifications'});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          title,
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: () => NotificationModule.repository.markAllAsRead(),
            child: Text(
              'Mark all read',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: NotificationModule.repository.watchNotifications(),
        builder: (context, snapshot) {
          final notifications = snapshot.data ?? const <AppNotification>[];

          if (snapshot.connectionState == ConnectionState.waiting &&
              notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print('Notifications error: ${snapshot.error}');
            return _buildErrorState();
          }

          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(
              height: 12,
              thickness: 0,
              color: Colors.transparent,
            ),
            itemBuilder: (context, index) {
              final item = notifications[index];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: item.isRead
                      ? null
                      : () => NotificationModule.repository.markAsRead(item.id),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: item.isRead ? Colors.white : AppColors.primary50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: item.isRead
                            ? AppColors.neutral200
                            : AppColors.primary100,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _typeBackgroundColor(item.type),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _typeIcon(item.type),
                            color: _typeIconColor(item.type),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: AppTextStyles.bodyLarge.copyWith(
                                        color: AppColors.neutral900,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _formatTimestamp(item.createdAt),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.neutral500,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.message,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.neutral600,
                                ),
                              ),
                              if (!item.isRead) ...[
                                const SizedBox(height: 10),
                                Text(
                                  'Tap to mark as read',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.primary700,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
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
              'No data available',
              style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Notifications will appear here once data is available.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.neutral500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Text(
        'Unable to load notifications.',
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral500),
      ),
    );
  }
}

IconData _typeIcon(NotificationType type) {
  switch (type) {
    case NotificationType.attendance:
      return Icons.fact_check_outlined;
    case NotificationType.visit:
      return Icons.pin_drop_outlined;
    case NotificationType.alert:
      return Icons.notification_important_outlined;
  }
}

Color _typeBackgroundColor(NotificationType type) {
  switch (type) {
    case NotificationType.attendance:
      return AppColors.primary50;
    case NotificationType.visit:
      return const Color(0xFFFFF7ED);
    case NotificationType.alert:
      return const Color(0xFFFEF2F2);
  }
}

Color _typeIconColor(NotificationType type) {
  switch (type) {
    case NotificationType.attendance:
      return AppColors.primary700;
    case NotificationType.visit:
      return const Color(0xFFEA580C);
    case NotificationType.alert:
      return AppColors.error;
  }
}

String _formatTimestamp(DateTime? timestamp) {
  if (timestamp == null) {
    return 'Now';
  }

  final difference = DateTime.now().difference(timestamp);
  if (difference.inMinutes < 1) {
    return 'Just now';
  }
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes} min ago';
  }
  if (difference.inHours < 24) {
    return '${difference.inHours} hr ago';
  }
  if (difference.inDays == 1) {
    return 'Yesterday';
  }
  return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
}
