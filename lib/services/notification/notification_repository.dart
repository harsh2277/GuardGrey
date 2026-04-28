import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:guardgrey/modules/notifications/models/app_notification.dart';

class NotificationRepository {
  NotificationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _notificationsCollection =>
      _firestore.collection('notifications');

  CollectionReference<Map<String, dynamic>> get _adminTokensCollection =>
      _firestore.collection('admin_notification_tokens');

  Stream<List<AppNotification>> watchNotifications() {
    return _notificationsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(AppNotification.fromFirestore)
              .toList(growable: false),
        );
  }

  Stream<int> watchUnreadCount() {
    return _notificationsCollection
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

  Future<void> markAllAsRead() async {
    final unreadNotifications = await _notificationsCollection
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
    bool isRead = false,
  }) {
    return _notificationsCollection.add({
      'title': title,
      'message': message,
      'type': type.value,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': isRead,
    });
  }

  Future<void> upsertAdminToken({
    required String token,
    required bool notificationsEnabled,
    required String platform,
    String role = 'admin',
  }) {
    return _adminTokensCollection.doc(token).set({
      'token': token,
      'role': role,
      'platform': platform,
      'notificationsEnabled': notificationsEnabled,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> disableAdminToken(String token, {String? platform}) {
    return _adminTokensCollection.doc(token).set({
      'token': token,
      'role': 'admin',
      if (platform != null) 'platform': platform,
      'notificationsEnabled': false,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
