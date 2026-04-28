import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../modules/admin/services/firestore_seed_service.dart';
import '../../modules/notifications/services/notification_module.dart';
import '../../widgets/list_tile.dart';
import '../../widgets/section_header.dart';
import '../../widgets/toggle_tile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = false;
  bool _inAppNotifications = true;
  bool _isLoadingPreferences = true;
  bool _isUpdatingPushSetting = false;
  bool _isSendingTestNotification = false;
  bool _isSeedingDatabase = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    await NotificationModule.preferencesService.initialize();
    if (!mounted) {
      return;
    }

    setState(() {
      _pushNotifications = NotificationModule.preferencesService.isPushEnabled;
      _inAppNotifications =
          NotificationModule.preferencesService.isInAppEnabled;
      _isLoadingPreferences = false;
    });
  }

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

  Future<void> _updatePushNotifications(bool value) async {
    if (_isUpdatingPushSetting) {
      return;
    }

    setState(() {
      _isUpdatingPushSetting = true;
      _pushNotifications = value;
    });

    final isEnabled = await NotificationModule.pushNotificationService
        .setPushNotificationsEnabled(value);

    if (!mounted) {
      return;
    }

    setState(() {
      _pushNotifications = isEnabled;
      _isUpdatingPushSetting = false;
    });

    _showPlaceholderMessage(
      isEnabled
          ? 'Push notifications are enabled.'
          : value
          ? 'Notification permission is required to enable push alerts.'
          : 'Push notifications are turned off.',
    );
  }

  Future<void> _updateInAppNotifications(bool value) async {
    await NotificationModule.preferencesService.setInAppEnabled(value);
    if (!mounted) {
      return;
    }

    setState(() {
      _inAppNotifications = value;
    });

    _showPlaceholderMessage(
      value
          ? 'In-app notifications are enabled.'
          : 'In-app notifications are turned off.',
    );
  }

  Future<void> _sendTestNotification() async {
    if (_isSendingTestNotification) {
      return;
    }

    if (kIsWeb) {
      _showPlaceholderMessage(
        'Test notifications are available only on Android and iOS.',
      );
      return;
    }

    setState(() {
      _isSendingTestNotification = true;
    });

    final didShow = await NotificationModule.pushNotificationService
        .showTestNotification();

    if (!mounted) {
      return;
    }

    setState(() {
      _isSendingTestNotification = false;
    });

    _showPlaceholderMessage(
      didShow
          ? 'Test notification sent.'
          : 'Enable in-app notifications to send a test notification.',
    );
  }

  Future<void> _seedDatabase() async {
    if (_isSeedingDatabase) {
      return;
    }

    setState(() {
      _isSeedingDatabase = true;
    });

    try {
      await seedDatabase(clearExisting: true);
      if (!mounted) {
        return;
      }
      _showPlaceholderMessage(
        'Database cleared and seeded successfully with the latest schema.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showPlaceholderMessage(
        'Unable to clear and seed the database. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSeedingDatabase = false;
        });
      }
    }
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
      body: _isLoadingPreferences
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                const SectionHeader(title: 'Notifications'),
                const SizedBox(height: 10),
                ToggleTile(
                  title: 'Push Notifications',
                  subtitle: 'Receive real-time alerts',
                  leadingIcon: Icons.notifications_active_outlined,
                  value: _pushNotifications,
                  onChanged: _isUpdatingPushSetting
                      ? (_) {}
                      : _updatePushNotifications,
                ),
                const SizedBox(height: 12),
                ToggleTile(
                  title: 'In-App Notifications',
                  subtitle: 'Show notifications inside app',
                  leadingIcon: Icons.notifications_none_rounded,
                  value: _inAppNotifications,
                  onChanged: _updateInAppNotifications,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSendingTestNotification
                        ? null
                        : _sendTestNotification,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      _isSendingTestNotification
                          ? 'Sending...'
                          : 'Send Test Notification',
                    ),
                  ),
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
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSeedingDatabase ? null : _seedDatabase,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      _isSeedingDatabase
                          ? 'Seeding Database...'
                          : 'Seed Database',
                    ),
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
  const _ValuePill({required this.label});

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
