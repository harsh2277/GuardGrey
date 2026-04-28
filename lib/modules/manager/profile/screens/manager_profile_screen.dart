import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/core/widgets/list_tile.dart';
import 'package:guardgrey/data/models/manager_model.dart';
import 'package:guardgrey/data/repositories/guard_grey_repository.dart';
import 'package:guardgrey/routes/app_routes.dart';

class ManagerProfileScreen extends StatelessWidget {
  const ManagerProfileScreen({super.key});

  GuardGreyRepository get _repository => GuardGreyRepository.instance;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'My Profile',
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: StreamBuilder<ManagerModel?>(
        stream: _repository.watchManagerByEmail(email),
        builder: (context, snapshot) {
          final manager = snapshot.data;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.neutral200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      manager?.name ?? 'Manager',
                      style: AppTextStyles.headingMedium.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      manager?.email ?? email,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.neutral500,
                      ),
                    ),
                    if ((manager?.phone ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        manager!.phone,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.neutral500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppListTile(
                title: 'Notifications',
                subtitle: 'Review alerts and updates',
                leadingIcon: Icons.notifications_outlined,
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.managerNotifications,
                ),
              ),
              const SizedBox(height: 12),
              AppListTile(
                title: 'Visit History',
                subtitle: 'View your submitted visit logs',
                leadingIcon: Icons.pin_drop_outlined,
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.managerVisits),
              ),
              const SizedBox(height: 12),
              AppListTile(
                title: 'Logout',
                subtitle: 'Sign out of the manager app',
                leadingIcon: Icons.logout_rounded,
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.login,
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
