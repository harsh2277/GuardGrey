import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreferencesService {
  static const String _pushNotificationsKey = 'push_notifications_enabled';
  static const String _inAppNotificationsKey = 'in_app_notifications_enabled';

  SharedPreferences? _preferences;

  Future<void> initialize() async {
    _preferences ??= await SharedPreferences.getInstance();
  }

  bool get isPushEnabled =>
      _preferences?.getBool(_pushNotificationsKey) ?? false;

  bool get isInAppEnabled =>
      _preferences?.getBool(_inAppNotificationsKey) ?? true;

  Future<void> setPushEnabled(bool isEnabled) async {
    await initialize();
    await _preferences!.setBool(_pushNotificationsKey, isEnabled);
  }

  Future<void> setInAppEnabled(bool isEnabled) async {
    await initialize();
    await _preferences!.setBool(_inAppNotificationsKey, isEnabled);
  }
}
