import 'package:cloud_firestore/cloud_firestore.dart';

class ManagerLeaveRequest {
  const ManagerLeaveRequest({
    required this.id,
    required this.managerId,
    required this.managerName,
    required this.leaveType,
    required this.fromDate,
    required this.toDate,
    required this.reason,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String managerId;
  final String managerName;
  final String leaveType;
  final DateTime fromDate;
  final DateTime toDate;
  final String reason;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get canManage => status.trim().toLowerCase() == 'pending';

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'managerId': managerId,
      'managerName': managerName,
      'leaveType': leaveType,
      'fromDate': Timestamp.fromDate(fromDate),
      'toDate': Timestamp.fromDate(toDate),
      'reason': reason,
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
      if (createdAt == null) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  static ManagerLeaveRequest fromMap(String id, Map<String, dynamic> data) {
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

    return ManagerLeaveRequest(
      id: id,
      managerId: (data['managerId'] as String? ?? '').trim(),
      managerName: (data['managerName'] as String? ?? '').trim(),
      leaveType: (data['leaveType'] as String? ?? '').trim(),
      fromDate: toDateTime(data['fromDate']) ?? DateTime.now(),
      toDate: toDateTime(data['toDate']) ?? DateTime.now(),
      reason: (data['reason'] as String? ?? '').trim(),
      status: (data['status'] as String? ?? 'Pending').trim(),
      createdAt: toDateTime(data['createdAt']),
      updatedAt: toDateTime(data['updatedAt']),
    );
  }
}
