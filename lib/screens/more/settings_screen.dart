import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/list_tile.dart';
import '../../widgets/section_header.dart';
import '../../widgets/toggle_tile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _pullNotifications = true;

  void _showPlaceholderMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primary600,
      ),
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
          'Settings',
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          const SectionHeader(title: 'Notifications'),
          const SizedBox(height: 10),
          ToggleTile(
            title: 'Push Notifications',
            subtitle: 'Receive real-time alerts',
            leadingIcon: Icons.notifications_active_outlined,
            value: _pushNotifications,
            onChanged: (value) {
              setState(() {
                _pushNotifications = value;
              });
            },
          ),
          const SizedBox(height: 12),
          ToggleTile(
            title: 'Pull Notifications',
            subtitle: 'Enable manual refresh for notifications',
            leadingIcon: Icons.refresh_rounded,
            value: _pullNotifications,
            onChanged: (value) {
              setState(() {
                _pullNotifications = value;
              });
            },
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'App Settings'),
          const SizedBox(height: 10),
          const AppListTile(
            title: 'Theme',
            leadingIcon: Icons.light_mode_outlined,
            trailing: _ValuePill(label: 'Light'),
          ),
          const SizedBox(height: 12),
          const AppListTile(
            title: 'Language',
            leadingIcon: Icons.language_rounded,
            trailing: _ValuePill(label: 'English'),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Data'),
          const SizedBox(height: 10),
          AppListTile(
            title: 'Export Reports',
            leadingIcon: Icons.file_upload_outlined,
            onTap: () => _showPlaceholderMessage(
              'Report export will be available soon.',
            ),
          ),
          const SizedBox(height: 12),
          AppListTile(
            title: 'Download Data',
            leadingIcon: Icons.download_outlined,
            onTap: () => _showPlaceholderMessage(
              'Data download will be available soon.',
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'About'),
          const SizedBox(height: 10),
          const AppListTile(
            title: 'App Version',
            leadingIcon: Icons.info_outline_rounded,
            trailing: _ValuePill(label: 'v1.0.0'),
          ),
          const SizedBox(height: 12),
          AppListTile(
            title: 'Privacy Policy',
            leadingIcon: Icons.privacy_tip_outlined,
            onTap: () => _showPlaceholderMessage(
              'Privacy policy details will be available soon.',
            ),
          ),
          const SizedBox(height: 12),
          AppListTile(
            title: 'Terms',
            leadingIcon: Icons.gavel_outlined,
            onTap: () => _showPlaceholderMessage(
              'Terms details will be available soon.',
            ),
          ),
        ],
      ),
    );
  }
}

class _ValuePill extends StatelessWidget {
  const _ValuePill({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary50,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.primary700,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
