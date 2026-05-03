import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:guardgrey/modules/manager/visits/models/manager_visit_entry.dart';

class ManagerVisitRepository {
  ManagerVisitRepository._({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static final ManagerVisitRepository instance = ManagerVisitRepository._();

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _visits =>
      _firestore.collection('site_visits');

  Stream<List<ManagerVisitEntry>> watchManagerVisits(String managerId) {
    if (managerId.trim().isEmpty) {
      return Stream<List<ManagerVisitEntry>>.value(const <ManagerVisitEntry>[]);
    }

    return _visits
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ManagerVisitEntry.fromMap(doc.id, doc.data()))
              .where((visit) => visit.managerId == managerId.trim())
              .where((visit) => !visit.isDeleted)
              .toList(growable: false),
        );
  }

  Stream<List<ManagerVisitEntry>> watchSiteVisits({
    required String managerId,
    required String siteId,
  }) {
    return watchManagerVisits(managerId).map(
      (visits) => visits
          .where((visit) => visit.siteId == siteId.trim())
          .toList(growable: false),
    );
  }

  Stream<ManagerVisitEntry?> watchVisit(String visitId) {
    return _visits.doc(visitId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      return ManagerVisitEntry.fromMap(
        snapshot.id,
        snapshot.data() ?? const <String, dynamic>{},
      );
    });
  }

  Future<void> saveVisit(ManagerVisitEntry visit) async {
    await _visits
        .doc(visit.id)
        .set(visit.toFirestore(), SetOptions(merge: true));
  }

  Future<void> softDeleteVisit(String visitId) async {
    await _visits.doc(visitId).set(<String, dynamic>{
      'deletedAt': FieldValue.serverTimestamp(),
      'status': 'Deleted',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
