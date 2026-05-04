import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'package:guardgrey/data/models/app_notification.dart';
import 'package:guardgrey/data/repositories/notification_repository.dart';
import 'package:guardgrey/features/auth/models/app_role.dart';
import 'notification_preferences_service.dart';

class PushNotificationService {
  static const String _oneSignalAppId = '3515bf0b-a8af-483a-927a-4e2fd59d6cbd';
  static const String _restApiKey = String.fromEnvironment(
    'ONESIGNAL_REST_API_KEY',
    defaultValue:
        'os_v2_app_guk36c5iv5edvet2jyx5lhlmxved4slluoyunumgodzpaipnxvj6g7y7hwaardl5fapaejv5syvzqkrhkjsovfz72biw4v4vwyergni',
  );
  static const String _notificationsEndpoint =
      'https://onesignal.com/api/v1/notifications';

  PushNotificationService({
    required NotificationRepository repository,
    required NotificationPreferencesService preferencesService,
  }) : _repository = repository,
       _preferencesService = preferencesService;

  final NotificationRepository _repository;
  final NotificationPreferencesService _preferencesService;

  bool get _isSupportedMobilePlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> initialize() async {
    if (!_isSupportedMobilePlatform) {
      return;
    }

    OneSignal.initialize(_oneSignalAppId);
    final granted = await OneSignal.Notifications.requestPermission(true);
    await _preferencesService.setPushEnabled(granted);
    await syncPushNotificationState();
  }

  Future<bool> setPushNotificationsEnabled(bool isEnabled) async {
    if (!_isSupportedMobilePlatform) {
      await _preferencesService.setPushEnabled(false);
      return false;
    }

    await _preferencesService.setPushEnabled(isEnabled);
    if (!isEnabled) {
      final audience = await _repository.resolveAudience();
      if (audience != null) {
        await _repository.disableToken(
          role: audience.role,
          userId: audience.userId,
          recipientKeys: audience.recipientKeys,
        );
      }
      return false;
    }

    final isAuthorized = await OneSignal.Notifications.requestPermission(true);
    if (!isAuthorized) {
      await _preferencesService.setPushEnabled(false);
      return false;
    }

    await syncPushNotificationState();
    return true;
  }

  Future<void> syncPushNotificationState() async {
    if (!_isSupportedMobilePlatform) {
      await _preferencesService.setPushEnabled(false);
      return;
    }

    final audience = await _repository.resolveAudience();
    if (audience == null || FirebaseAuth.instance.currentUser == null) {
      return;
    }

    if (!_preferencesService.isPushEnabled ||
        !OneSignal.Notifications.permission) {
      await _repository.disableToken(
        role: audience.role,
        userId: audience.userId,
        recipientKeys: audience.recipientKeys,
      );
      return;
    }

    final playerId = OneSignal.User.pushSubscription.id;
    debugPrint('OneSignal player ID: $playerId');
    if (playerId == null || playerId.trim().isEmpty) {
      return;
    }

    await _repository.upsertToken(
      playerId: playerId,
      notificationsEnabled: true,
      role: audience.role,
      userId: audience.userId,
      recipientKeys: audience.recipientKeys,
    );
  }

  Future<bool> showTestNotification() async {
    final audience = await _repository.resolveAudience();
    if (!_isSupportedMobilePlatform || audience == null) {
      return false;
    }

    final playerId = await _repository.fetchPlayerId(audience.userId);
    if (playerId == null) {
      return false;
    }

    return _sendNotificationRequest(
      playerIds: <String>[playerId],
      title: 'Test Notification',
      message: 'This is a test message',
    );
  }

  Future<void> notifyManagerSiteAssigned({
    required String managerId,
    required String siteName,
  }) async {
    final playerId = await _repository.fetchPlayerId(managerId);
    debugPrint('Manager player ID for assignment: $playerId');
    if (playerId == null) {
      return;
    }

    await _repository.createNotification(
      title: 'New Site Assigned',
      message: 'You have been assigned a new site: $siteName.',
      type: NotificationType.alert,
      recipientKeys: <String>[
        NotificationRepository.userRecipientKey(managerId),
      ],
    );

    await _sendNotificationRequest(
      playerIds: <String>[playerId],
      title: 'New Site Assigned',
      message: 'You have been assigned a new site',
    );
  }

  Future<void> notifyAdminsVisitSubmitted({
    required String managerName,
    required String siteName,
  }) async {
    final playerIds = await _repository.fetchPlayerIdsByRole(AppRole.admin);
    debugPrint('Admin player IDs for visit submit: $playerIds');
    if (playerIds.isEmpty) {
      return;
    }

    await _repository.createNotification(
      title: 'Visit Submitted',
      message: '$managerName has submitted a site visit for $siteName.',
      type: NotificationType.visit,
      recipientKeys: <String>[
        NotificationRepository.roleRecipientKey(AppRole.admin),
      ],
    );

    await _sendNotificationRequest(
      playerIds: playerIds,
      title: 'Visit Submitted',
      message: 'Manager has submitted a site visit',
    );
  }

  Future<bool> _sendNotificationRequest({
    required List<String> playerIds,
    required String title,
    required String message,
  }) async {
    if (playerIds.isEmpty) {
      return false;
    }

    if (_restApiKey == 'YOUR_REST_API_KEY') {
      debugPrint('OneSignal REST API key is not configured.');
      return false;
    }

    final payload = <String, dynamic>{
      'app_id': _oneSignalAppId,
      'include_player_ids': playerIds,
      'headings': <String, String>{'en': title},
      'contents': <String, String>{'en': message},
    };

    try {
      final response = await http.post(
        Uri.parse(_notificationsEndpoint),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Basic $_restApiKey',
        },
        body: jsonEncode(payload),
      );
      debugPrint('OneSignal response: ${response.statusCode} ${response.body}');
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (error) {
      debugPrint('OneSignal notification failed: $error');
      return false;
    }
  }
}
