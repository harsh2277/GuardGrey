import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/features/notifications/services/notification_module.dart';

class PermissionService {
  PermissionService._();

  static const String _permissionsAskedKey = 'app_permissions_asked';
  static final PermissionService instance = PermissionService._();

  SharedPreferences? _preferences;

  Future<void> handleAppPermissions(BuildContext context) async {
    await _initialize();
    if (!context.mounted) {
      return;
    }
    if (_preferences!.getBool(_permissionsAskedKey) ?? false) {
      return;
    }

    try {
      await _requestLocationPermission(context);
      await _requestNotificationPermission();
    } finally {
      await _preferences!.setBool(_permissionsAskedKey, true);
    }
  }

  Future<void> _initialize() async {
    _preferences ??= await SharedPreferences.getInstance();
  }

  Future<void> _requestLocationPermission(BuildContext context) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        _showSnackBar(context, 'Enable location services');
      }
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (!context.mounted) {
      return;
    }

    if (permission == LocationPermission.denied) {
      _showSnackBar(
        context,
        'Location permission denied. You can enable it later in settings.',
      );
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      await _showOpenSettingsDialog(
        context: context,
        title: 'Location permission needed',
        message:
            'Location access is permanently denied. Open settings to enable it.',
        onOpenSettings: Geolocator.openAppSettings,
      );
    }
  }

  Future<void> _requestNotificationPermission() async {
    final isAuthorized = await NotificationModule.pushNotificationService
        .setPushNotificationsEnabled(true);
    await NotificationModule.preferencesService.setPushEnabled(isAuthorized);
    if (isAuthorized) {
      await NotificationModule.pushNotificationService
          .syncPushNotificationState();
    }
  }

  Future<void> _showOpenSettingsDialog({
    required BuildContext context,
    required String title,
    required String message,
    required Future<bool> Function() onOpenSettings,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title, style: AppTextStyles.title),
          content: Text(message, style: AppTextStyles.bodyMedium),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Later'),
            ),
            TextButton(
              onPressed: () async {
                await onOpenSettings();
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.neutral900,
        content: Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
