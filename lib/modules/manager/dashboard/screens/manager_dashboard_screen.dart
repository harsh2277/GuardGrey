import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/data/models/attendance_record.dart';
import 'package:guardgrey/data/models/manager_model.dart';
import 'package:guardgrey/data/models/site_model.dart';
import 'package:guardgrey/data/repositories/guard_grey_repository.dart';
import 'package:guardgrey/features/notifications/services/notification_module.dart';
import 'package:guardgrey/routes/app_routes.dart';

class ManagerDashboardScreen extends StatelessWidget {
  const ManagerDashboardScreen({super.key});

  GuardGreyRepository get _repository => GuardGreyRepository.instance;

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Manager Dashboard',
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.managerNotifications),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: StreamBuilder<ManagerModel?>(
        stream: _repository.watchManagerByEmail(email),
        builder: (context, managerSnapshot) {
          if (managerSnapshot.connectionState == ConnectionState.waiting &&
              !managerSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final manager = managerSnapshot.data;
          if (manager == null) {
            return _ManagerEmptyState(email: email);
          }

          return StreamBuilder<List<SiteModel>>(
            stream: _repository.watchSites(),
            builder: (context, sitesSnapshot) {
              return StreamBuilder<List<AttendanceRecord>>(
                stream: _repository.watchAttendance(),
                builder: (context, attendanceSnapshot) {
                  final assignedSites =
                      (sitesSnapshot.data ?? const <SiteModel>[])
                          .where(
                            (site) =>
                                site.managerId == manager.id ||
                                manager.siteIds.contains(site.id),
                          )
                          .toList(growable: false);
                  final attendanceCount =
                      (attendanceSnapshot.data ?? const <AttendanceRecord>[])
                          .where((record) => record.managerId == manager.id)
                          .length;

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    children: [
                      _ManagerHeroCard(
                        managerName: manager.name,
                        email: manager.email,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              title: 'Assigned Sites',
                              value: '${assignedSites.length}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MetricCard(
                              title: 'Attendance Logs',
                              value: '$attendanceCount',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      StreamBuilder<int>(
                        stream: NotificationModule.repository
                            .watchUnreadCount(),
                        builder: (context, snapshot) {
                          final unreadCount = snapshot.data ?? 0;
                          return _InfoCard(
                            title: 'Notifications',
                            subtitle: unreadCount == 0
                                ? 'No unread notifications'
                                : '$unreadCount unread notifications',
                            icon: Icons.notifications_active_outlined,
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.managerNotifications,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _InfoCard(
                        title: 'Site Visits',
                        subtitle:
                            'Review recent site activity and visit history',
                        icon: Icons.pin_drop_outlined,
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.managerVisits,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ManagerHeroCard extends StatelessWidget {
  const _ManagerHeroCard({required this.managerName, required this.email});

  final String managerName;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary600,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            managerName,
            style: AppTextStyles.headingMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            email,
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value});

  final String title;
  final String value;

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
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.neutral500,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.headingMedium.copyWith(
              color: AppColors.neutral900,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
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
                child: Icon(icon, color: AppColors.primary600),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.neutral500,
                      ),
                    ),
                  ],
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
  }
}

class _ManagerEmptyState extends StatelessWidget {
  const _ManagerEmptyState({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          email.isEmpty
              ? 'Manager account details are not available.'
              : 'No manager profile was found for $email.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.neutral500),
        ),
      ),
    );
  }
}
