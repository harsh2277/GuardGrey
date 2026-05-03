import 'package:cloud_firestore/cloud_firestore.dart';

class ManagerAttendanceEntry {
  const ManagerAttendanceEntry({
    required this.id,
    required this.managerId,
    required this.managerName,
    required this.status,
    required this.date,
    this.siteId = '',
    this.siteName = '',
    this.latitude,
    this.longitude,
    this.checkInAt,
    this.checkOutAt,
  });

  final String id;
  final String managerId;
  final String managerName;
  final String siteId;
  final String siteName;
  final String status;
  final DateTime date;
  final double? latitude;
  final double? longitude;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;

  bool get isCheckedIn => checkInAt != null && checkOutAt == null;

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'managerId': managerId,
      'managerName': managerName,
      'siteId': siteId,
      'siteName': siteName,
      'status': status,
      'date': Timestamp.fromDate(date),
      'latitude': latitude,
      'longitude': longitude,
      'checkInAt': checkInAt == null ? null : Timestamp.fromDate(checkInAt!),
      'checkOutAt': checkOutAt == null ? null : Timestamp.fromDate(checkOutAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static ManagerAttendanceEntry fromMap(String id, Map<String, dynamic> data) {
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

    return ManagerAttendanceEntry(
      id: id,
      managerId: (data['managerId'] as String? ?? '').trim(),
      managerName: (data['managerName'] as String? ?? '').trim(),
      siteId: (data['siteId'] as String? ?? '').trim(),
      siteName: (data['siteName'] as String? ?? '').trim(),
      status: (data['status'] as String? ?? '').trim(),
      date: toDateTime(data['date']) ?? DateTime.now(),
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      checkInAt: toDateTime(data['checkInAt']),
      checkOutAt: toDateTime(data['checkOutAt']),
    );
  }
}
