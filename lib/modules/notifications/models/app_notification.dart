import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  attendance('attendance'),
  visit('visit'),
  alert('alert');

  const NotificationType(this.value);

  final String value;

  static NotificationType fromValue(String? value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NotificationType.alert,
    );
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.isRead,
  });

  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime? createdAt;
  final bool isRead;

  factory AppNotification.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final createdAt = data['createdAt'];

    return AppNotification(
      id: doc.id,
      title: (data['title'] as String?)?.trim().isNotEmpty == true
          ? data['title'] as String
          : 'Notification',
      message: (data['message'] as String?) ?? '',
      type: NotificationType.fromValue(data['type'] as String?),
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
      isRead: data['isRead'] as bool? ?? false,
    );
  }
}
