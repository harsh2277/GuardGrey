import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/core/widgets/list_tile.dart';
import 'package:guardgrey/core/widgets/section_header.dart';
import 'package:guardgrey/modules/manager/field_visits/screens/manager_field_visit_screen.dart';
import 'package:guardgrey/modules/manager/leave/screens/manager_leave_screen.dart';
import 'package:guardgrey/modules/manager/profile/screens/manager_profile_screen.dart';
import 'package:guardgrey/modules/manager/settings/screens/manager_settings_screen.dart';
import 'package:guardgrey/routes/app_routes.dart';

class ManagerMoreScreen extends StatelessWidget {
  const ManagerMoreScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Logout',
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Do you want to logout from GuardPulse manager app?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) {
      return;
    }

    await FirebaseAuth.instance.signOut();
    if (!context.mounted) {
      return;
    }
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.authGate,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          const SectionHeader(title: 'Account'),
          const SizedBox(height: 12),
          AppListTile(
            title: 'Profile',
            subtitle: 'Update personal details',
            leadingIcon: Icons.person_outline_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ManagerProfileScreen(showAppBar: true),
              ),
            ),
          ),
          const SizedBox(height: 12),
          AppListTile(
            title: 'Field Visits',
            subtitle: 'Track surprise, inspection and complaint visits',
            leadingIcon: Icons.pin_drop_outlined,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ManagerFieldVisitScreen(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          AppListTile(
            title: 'Leave',
            subtitle: 'Apply and manage leave requests',
            leadingIcon: Icons.event_busy_outlined,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManagerLeaveScreen()),
            ),
          ),
          const SizedBox(height: 18),
          const SectionHeader(title: 'Preferences'),
          const SizedBox(height: 12),
          AppListTile(
            title: 'Settings',
            subtitle: 'Notification preferences and app info',
            leadingIcon: Icons.settings_outlined,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManagerSettingsScreen()),
            ),
          ),
          const SizedBox(height: 18),
          const SectionHeader(title: 'Session'),
          const SizedBox(height: 12),
          AppListTile(
            title: 'Logout',
            subtitle: 'End current manager session',
            leadingIcon: Icons.logout_rounded,
            titleColor: AppColors.errorDark,
            iconColor: AppColors.errorDark,
            onTap: () => _confirmLogout(context),
          ),
        ],
      ),
    );
  }
}
