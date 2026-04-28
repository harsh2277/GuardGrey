import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../firebase_options.dart';
import 'notification_preferences_service.dart';
import 'notification_repository.dart';

const AndroidNotificationChannel _adminNotificationsChannel =
    AndroidNotificationChannel(
      'guardgrey_admin_notifications',
      'Admin Notifications',
      description: 'Real-time admin notifications for GuardGrey',
      importance: Importance.high,
    );

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class PushNotificationService {
  PushNotificationService({
    required NotificationRepository repository,
    required NotificationPreferencesService preferencesService,
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotificationsPlugin,
  }) : _repository = repository,
       _preferencesService = preferencesService,
       _messagingOverride = messaging,
       _localNotificationsPlugin =
           localNotificationsPlugin ?? FlutterLocalNotificationsPlugin();

  final NotificationRepository _repository;
  final NotificationPreferencesService _preferencesService;
  final FirebaseMessaging? _messagingOverride;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin;

  FirebaseMessaging get _messaging =>
      _messagingOverride ?? FirebaseMessaging.instance;

  bool get _isSupportedMobilePlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> initialize() async {
    if (!_isSupportedMobilePlatform) {
      return;
    }

    await _initializeLocalNotifications();
    await _configureForegroundHandling();

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    _messaging.onTokenRefresh.listen(_handleTokenRefresh);

    await syncPushNotificationState();
  }

  Future<bool> setPushNotificationsEnabled(bool isEnabled) async {
    if (!_isSupportedMobilePlatform) {
      await _preferencesService.setPushEnabled(false);
      return false;
    }

    await _preferencesService.setPushEnabled(isEnabled);
    if (!isEnabled) {
      final existingToken = await _messaging.getToken();
      if (existingToken != null) {
        await _repository.disableAdminToken(
          existingToken,
          platform: platformLabel,
        );
      }
      await _messaging.deleteToken();
      return false;
    }

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    final isAuthorized =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    if (!isAuthorized) {
      await _preferencesService.setPushEnabled(false);
      return false;
    }

    final token = await _messaging.getToken();
    if (token == null) {
      await _preferencesService.setPushEnabled(false);
      return false;
    }

    await _repository.upsertAdminToken(
      token: token,
      notificationsEnabled: true,
      platform: platformLabel,
    );
    return true;
  }

  Future<void> syncPushNotificationState() async {
    if (!_isSupportedMobilePlatform) {
      await _preferencesService.setPushEnabled(false);
      return;
    }

    if (!_preferencesService.isPushEnabled) {
      final token = await _messaging.getToken();
      if (token != null) {
        await _repository.disableAdminToken(token, platform: platformLabel);
      }
      return;
    }

    final settings = await _messaging.getNotificationSettings();
    final isAuthorized =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    if (!isAuthorized) {
      return;
    }

    final token = await _messaging.getToken();
    if (token == null) {
      return;
    }

    await _repository.upsertAdminToken(
      token: token,
      notificationsEnabled: true,
      platform: platformLabel,
    );
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotificationsPlugin.initialize(initializationSettings);

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_adminNotificationsChannel);
  }

  Future<void> _configureForegroundHandling() {
    return _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (!_isSupportedMobilePlatform) {
      return;
    }

    if (!_preferencesService.isInAppEnabled) {
      return;
    }

    final title =
        message.notification?.title ?? (message.data['title'] as String?);
    final body =
        message.notification?.body ?? (message.data['message'] as String?);

    if (title == null || body == null) {
      return;
    }

    await _localNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _adminNotificationsChannel.id,
          _adminNotificationsChannel.name,
          channelDescription: _adminNotificationsChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<bool> showTestNotification() async {
    if (!_isSupportedMobilePlatform) {
      return false;
    }

    if (!_preferencesService.isInAppEnabled) {
      return false;
    }

    await _localNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      'Test Notification',
      'This is a test message',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _adminNotificationsChannel.id,
          _adminNotificationsChannel.name,
          channelDescription: _adminNotificationsChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );

    return true;
  }

  Future<void> _handleTokenRefresh(String token) async {
    if (!_preferencesService.isPushEnabled) {
      await _repository.disableAdminToken(token, platform: platformLabel);
      return;
    }

    await _repository.upsertAdminToken(
      token: token,
      notificationsEnabled: true,
      platform: platformLabel,
    );
  }

  String get platformLabel {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return 'unsupported';
    }
  }
}
