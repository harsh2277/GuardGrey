import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:guardgrey/modules/manager/leave/models/manager_leave_request.dart';

class ManagerLeaveRepository {
  ManagerLeaveRepository._({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static final ManagerLeaveRepository instance = ManagerLeaveRepository._();

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _leaves =>
      _firestore.collection('manager_leaves');

  Stream<List<ManagerLeaveRequest>> watchLeaves(String managerId) {
    if (managerId.trim().isEmpty) {
      return Stream<List<ManagerLeaveRequest>>.value(
        const <ManagerLeaveRequest>[],
      );
    }

    return _leaves
        .where('managerId', isEqualTo: managerId.trim())
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ManagerLeaveRequest.fromMap(doc.id, doc.data()))
              .toList(growable: false),
        );
  }

  Future<void> saveLeave(ManagerLeaveRequest request) async {
    await _leaves
        .doc(request.id)
        .set(request.toFirestore(), SetOptions(merge: true));
  }

  Future<void> deleteLeave(String leaveId) => _leaves.doc(leaveId).delete();
}
