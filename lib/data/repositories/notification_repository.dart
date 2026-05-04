import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:guardgrey/data/models/app_notification.dart';
import 'package:guardgrey/features/auth/models/app_role.dart';
import 'package:guardgrey/modules/manager/common/services/manager_session_service.dart';

class NotificationRepository {
  NotificationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _notificationsCollection =>
      _firestore.collection('notifications');

  CollectionReference<Map<String, dynamic>> get _playerIdsCollection =>
      _firestore.collection('manager_notification_tokens');

  static String roleRecipientKey(AppRole role) => 'role:${role.name}';
  static String userRecipientKey(String userId) => 'user:${userId.trim()}';

  Stream<List<AppNotification>> watchNotifications(String recipientKey) {
    return _notificationsCollection
        .where('recipientKeys', arrayContains: recipientKey)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(AppNotification.fromFirestore)
              .toList(growable: false),
        );
  }

  Stream<int> watchUnreadCount(String recipientKey) {
    return _notificationsCollection
        .where('recipientKeys', arrayContains: recipientKey)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> markAsRead(String notificationId) {
    return _notificationsCollection.doc(notificationId).set({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> markAllAsRead(String recipientKey) async {
    final unreadNotifications = await _notificationsCollection
        .where('recipientKeys', arrayContains: recipientKey)
        .where('isRead', isEqualTo: false)
        .get();

    if (unreadNotifications.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();
    for (final doc in unreadNotifications.docs) {
      batch.set(doc.reference, {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  Future<void> createNotification({
    required String title,
    required String message,
    required NotificationType type,
    required List<String> recipientKeys,
    bool isRead = false,
  }) {
    return _notificationsCollection.add({
      'title': title,
      'message': message,
      'type': type.value,
      'recipientKeys': recipientKeys,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': isRead,
    });
  }

  Future<void> upsertToken({
    required String playerId,
    required bool notificationsEnabled,
    required AppRole role,
    required List<String> recipientKeys,
    required String userId,
  }) {
    return _playerIdsCollection.doc(userId).set({
      'playerId': playerId,
      'role': role.name,
      'userId': userId,
      'recipientKeys': recipientKeys,
      'notificationsEnabled': notificationsEnabled,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> disableToken({
    AppRole? role,
    required String userId,
    List<String>? recipientKeys,
  }) {
    final resolvedRole = role ?? AppRole.admin;
    return _playerIdsCollection.doc(userId).set({
      'playerId': null,
      'role': resolvedRole.name,
      'userId': userId,
      'recipientKeys': recipientKeys ?? const <String>[],
      'notificationsEnabled': false,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String?> fetchPlayerId(String userId) async {
    final snapshot = await _playerIdsCollection.doc(userId.trim()).get();
    if (!snapshot.exists) {
      return null;
    }
    final data = snapshot.data() ?? const <String, dynamic>{};
    final playerId = (data['playerId'] as String?)?.trim();
    final isEnabled = data['notificationsEnabled'] as bool? ?? true;
    if (playerId == null || playerId.isEmpty || !isEnabled) {
      return null;
    }
    return playerId;
  }

  Future<List<String>> fetchPlayerIdsByRole(AppRole role) async {
    final snapshot = await _playerIdsCollection
        .where('role', isEqualTo: role.name)
        .where('notificationsEnabled', isEqualTo: true)
        .get();
    return snapshot.docs
        .map((doc) => (doc.data()['playerId'] as String?)?.trim() ?? '')
        .where((playerId) => playerId.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  Future<NotificationAudience?> resolveAudience() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return null;
    }

    final manager = await ManagerSessionService.instance.fetchCurrentManager();
    if (manager != null) {
      return NotificationAudience(
        role: AppRole.manager,
        userId: manager.id,
        recipientKeys: <String>[
          roleRecipientKey(AppRole.manager),
          userRecipientKey(manager.id),
        ],
      );
    }

    return NotificationAudience(
      role: AppRole.admin,
      userId: user.uid,
      recipientKeys: <String>[
        roleRecipientKey(AppRole.admin),
        userRecipientKey(user.uid),
      ],
    );
  }
}

class NotificationAudience {
  const NotificationAudience({
    required this.role,
    required this.userId,
    required this.recipientKeys,
  });

  final AppRole role;
  final String userId;
  final List<String> recipientKeys;
}
