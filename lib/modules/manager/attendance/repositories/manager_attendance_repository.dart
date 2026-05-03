import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:guardgrey/modules/manager/attendance/models/manager_attendance_entry.dart';

class ManagerAttendanceRepository {
  ManagerAttendanceRepository._({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static final ManagerAttendanceRepository instance =
      ManagerAttendanceRepository._();

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _attendance =>
      _firestore.collection('attendance');

  Stream<List<ManagerAttendanceEntry>> watchAttendance(String managerId) {
    if (managerId.trim().isEmpty) {
      return Stream<List<ManagerAttendanceEntry>>.value(
        const <ManagerAttendanceEntry>[],
      );
    }

    return _attendance
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ManagerAttendanceEntry.fromMap(doc.id, doc.data()))
              .where((entry) => entry.managerId == managerId.trim())
              .toList(growable: false),
        );
  }

  Future<void> checkIn({
    required String managerId,
    required String managerName,
    double? latitude,
    double? longitude,
  }) async {
    final now = DateTime.now();
    final id =
        'attendance_${managerId}_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final status = now.hour > 9 || (now.hour == 9 && now.minute > 15)
        ? 'Late'
        : 'Present';
    final todayDoc = await _attendance.doc(id).get();
    if (todayDoc.exists) {
      final existing = ManagerAttendanceEntry.fromMap(
        todayDoc.id,
        todayDoc.data() ?? const <String, dynamic>{},
      );
      if (existing.checkInAt != null) {
        throw StateError('Check-in already exists for today.');
      }
    }

    await _attendance.doc(id).set(<String, dynamic>{
      'managerId': managerId,
      'managerName': managerName,
      'siteId': '',
      'siteName': '',
      'status': status,
      'date': Timestamp.fromDate(DateTime(now.year, now.month, now.day)),
      'latitude': latitude,
      'longitude': longitude,
      'checkInAt': Timestamp.fromDate(now),
      'checkOutAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> checkOut(ManagerAttendanceEntry entry) async {
    if (entry.checkInAt == null) {
      throw StateError('Check-in is required before check-out.');
    }
    if (entry.checkOutAt != null) {
      throw StateError('Check-out already recorded.');
    }
    await _attendance.doc(entry.id).set(<String, dynamic>{
      'checkOutAt': Timestamp.fromDate(DateTime.now()),
      'status': entry.status == 'Late' ? 'Late' : 'Present',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
