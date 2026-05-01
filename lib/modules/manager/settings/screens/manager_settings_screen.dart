import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/core/widgets/list_tile.dart';
import 'package:guardgrey/core/widgets/section_header.dart';
import 'package:guardgrey/features/notifications/services/notification_preferences_service.dart';

class ManagerSettingsScreen extends StatefulWidget {
  const ManagerSettingsScreen({super.key});

  @override
  State<ManagerSettingsScreen> createState() => _ManagerSettingsScreenState();
}

class _ManagerSettingsScreenState extends State<ManagerSettingsScreen> {
  final NotificationPreferencesService _preferences =
      NotificationPreferencesService();
  bool _isLoading = true;
  bool _pushEnabled = false;
  bool _inAppEnabled = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _preferences.initialize();
    if (!mounted) {
      return;
    }
    setState(() {
      _pushEnabled = _preferences.isPushEnabled;
      _inAppEnabled = _preferences.isInAppEnabled;
      _isLoading = false;
    });
  }

  Future<void> _togglePush(bool value) async {
    setState(() {
      _pushEnabled = value;
    });
    await _preferences.setPushEnabled(value);
  }

  Future<void> _toggleInApp(bool value) async {
    setState(() {
      _inAppEnabled = value;
    });
    await _preferences.setInAppEnabled(value);
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                const SectionHeader(title: 'Notifications'),
                const SizedBox(height: 12),
                AppListTile(
                  title: 'Push Notifications',
                  subtitle: 'Receive manager alerts on this device',
                  leadingIcon: Icons.notifications_active_outlined,
                  trailing: Switch(
                    value: _pushEnabled,
                    onChanged: _togglePush,
                    activeThumbColor: AppColors.primary600,
                  ),
                ),
                const SizedBox(height: 12),
                AppListTile(
                  title: 'In-App Notifications',
                  subtitle: 'Show alerts inside the manager console',
                  leadingIcon: Icons.campaign_outlined,
                  trailing: Switch(
                    value: _inAppEnabled,
                    onChanged: _toggleInApp,
                    activeThumbColor: AppColors.primary600,
                  ),
                ),
                const SizedBox(height: 18),
                const SectionHeader(title: 'App'),
                const SizedBox(height: 12),
                const AppListTile(
                  title: 'GuardPulse',
                  subtitle: 'Manager workspace',
                  leadingIcon: Icons.shield_outlined,
                ),
                const SizedBox(height: 12),
                const AppListTile(
                  title: 'Version',
                  subtitle: '1.0.0',
                  leadingIcon: Icons.info_outline_rounded,
                ),
              ],
            ),
    );
  }
}
