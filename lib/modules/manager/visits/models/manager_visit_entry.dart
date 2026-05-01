import 'package:cloud_firestore/cloud_firestore.dart';

class ManagerVisitEntry {
  const ManagerVisitEntry({
    required this.id,
    required this.siteId,
    required this.siteName,
    required this.managerId,
    required this.managerName,
    required this.scheduledAt,
    required this.status,
    required this.notes,
    required this.imageUrls,
    required this.checklist,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String siteId;
  final String siteName;
  final String managerId;
  final String managerName;
  final DateTime scheduledAt;
  final String status;
  final String notes;
  final List<String> imageUrls;
  final List<String> checklist;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  bool get canEditToday {
    final now = DateTime.now();
    return scheduledAt.year == now.year &&
        scheduledAt.month == now.month &&
        scheduledAt.day == now.day;
  }

  ManagerVisitEntry copyWith({
    String? id,
    String? siteId,
    String? siteName,
    String? managerId,
    String? managerName,
    DateTime? scheduledAt,
    String? status,
    String? notes,
    List<String>? imageUrls,
    List<String>? checklist,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return ManagerVisitEntry(
      id: id ?? this.id,
      siteId: siteId ?? this.siteId,
      siteName: siteName ?? this.siteName,
      managerId: managerId ?? this.managerId,
      managerName: managerName ?? this.managerName,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      imageUrls: imageUrls ?? this.imageUrls,
      checklist: checklist ?? this.checklist,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    final weekday = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ][scheduledAt.weekday - 1];
    final hour = scheduledAt.hour == 0
        ? 12
        : scheduledAt.hour > 12
        ? scheduledAt.hour - 12
        : scheduledAt.hour;
    final period = scheduledAt.hour >= 12 ? 'PM' : 'AM';
    final timeLabel =
        '${hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')} $period';

    return <String, dynamic>{
      'siteId': siteId,
      'siteName': siteName,
      'managerId': managerId,
      'managerName': managerName,
      'date': Timestamp.fromDate(scheduledAt),
      'day': weekday,
      'timeLabel': timeLabel,
      'status': status,
      'notes': notes,
      'imageUrls': imageUrls,
      'checklist': checklist,
      'updatedAt': FieldValue.serverTimestamp(),
      if (createdAt == null) 'createdAt': FieldValue.serverTimestamp(),
      if (deletedAt != null) 'deletedAt': Timestamp.fromDate(deletedAt!),
    };
  }

  static ManagerVisitEntry fromMap(String id, Map<String, dynamic> data) {
    DateTime? toDateTime(Object? value) {
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is DateTime) {
        return value;
      }
      if (value is String && value.trim().isNotEmpty) {
        return DateTime.tryParse(value.trim());
      }
      return null;
    }

    List<String> toStringList(Object? value) {
      if (value is Iterable) {
        return value
            .map((item) => '$item'.trim())
            .where((item) => item.isNotEmpty)
            .toList(growable: false);
      }
      return const <String>[];
    }

    return ManagerVisitEntry(
      id: id,
      siteId: (data['siteId'] as String? ?? '').trim(),
      siteName: (data['siteName'] as String? ?? '').trim(),
      managerId: (data['managerId'] as String? ?? '').trim(),
      managerName: (data['managerName'] as String? ?? '').trim(),
      scheduledAt: toDateTime(data['date']) ?? DateTime.now(),
      status: (data['status'] as String? ?? 'Pending').trim(),
      notes: (data['notes'] as String? ?? '').trim(),
      imageUrls: toStringList(data['imageUrls']),
      checklist: toStringList(data['checklist']),
      createdAt: toDateTime(data['createdAt']),
      updatedAt: toDateTime(data['updatedAt']),
      deletedAt: toDateTime(data['deletedAt']),
    );
  }
}
