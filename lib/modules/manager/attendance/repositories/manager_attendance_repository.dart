import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:guardgrey/data/models/site_model.dart';
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
        .where('managerId', isEqualTo: managerId.trim())
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ManagerAttendanceEntry.fromMap(doc.id, doc.data()))
              .toList(growable: false),
        );
  }

  Future<void> checkIn({
    required String managerId,
    required String managerName,
    required SiteModel site,
  }) async {
    final now = DateTime.now();
    final id =
        'attendance_${managerId}_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final status = now.hour > 9 || (now.hour == 9 && now.minute > 15)
        ? 'Late'
        : 'Present';

    await _attendance.doc(id).set(<String, dynamic>{
      'managerId': managerId,
      'managerName': managerName,
      'siteId': site.id,
      'siteName': site.name,
      'status': status,
      'date': Timestamp.fromDate(DateTime(now.year, now.month, now.day)),
      'checkInAt': Timestamp.fromDate(now),
      'checkOutAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> checkOut(ManagerAttendanceEntry entry) async {
    await _attendance.doc(entry.id).set(<String, dynamic>{
      'checkOutAt': Timestamp.fromDate(DateTime.now()),
      'status': entry.status == 'Late' ? 'Late' : 'Present',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
