import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:guardgrey/data/models/app_location.dart';
import 'package:guardgrey/data/models/field_visit_model.dart';
import 'package:guardgrey/data/models/manager_live_location_model.dart';
import 'package:guardgrey/data/repositories/firestore_repository_utils.dart';
import 'package:guardgrey/data/sources/firebase/guard_grey_firestore_seed_source.dart';

class FieldVisitRepository {
  FieldVisitRepository._({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static final FieldVisitRepository instance = FieldVisitRepository._();

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _fieldVisits =>
      _firestore.collection(GuardGreyFirestoreSchema.fieldVisits);
  CollectionReference<Map<String, dynamic>> get _liveLocations =>
      _firestore.collection(GuardGreyFirestoreSchema.managerLiveLocation);

  Stream<List<FieldVisitModel>> watchFieldVisits() {
    return _fieldVisits
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _fieldVisitFromMap(doc.id, doc.data()))
              .toList(growable: false),
        );
  }

  Stream<FieldVisitModel?> watchFieldVisit(String id) {
    return _fieldVisits.doc(id).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      return _fieldVisitFromMap(
        snapshot.id,
        snapshot.data() ?? const <String, dynamic>{},
      );
    });
  }

  Future<void> saveFieldVisit(FieldVisitModel visit) async {
    final docRef = _fieldVisits.doc(visit.id);
    await docRef.set({
      ...visit.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteFieldVisit(String id) => _fieldVisits.doc(id).delete();

  Future<void> saveManagerLiveLocation(
    ManagerLiveLocationModel location,
  ) async {
    await _liveLocations
        .doc(location.managerId)
        .set(location.toFirestore(), SetOptions(merge: true));
  }

  FieldVisitModel _fieldVisitFromMap(String id, Map<String, dynamic> data) {
    return FieldVisitModel(
      id: id,
      managerId: (data['managerId'] as String? ?? '').trim(),
      managerName: (data['managerName'] as String? ?? '').trim(),
      phone: (data['phone'] as String? ?? '').trim(),
      profileImage: (data['profileImage'] as String? ?? '').trim(),
      visitType: (data['visitType'] as String? ?? 'Field Visit').trim(),
      siteName: (data['siteName'] as String? ?? '').trim(),
      notes: ((data['notes'] ?? data['description']) as String? ?? '').trim(),
      status: (data['status'] as String? ?? 'Submitted').trim(),
      location: AppLocation.fromMap(mapValue(data['location'])),
      imageUrls: stringList(data['imageUrls']),
      dateTime: toDateTime(data['dateTime']) ?? DateTime.now(),
      createdAt: toDateTime(data['createdAt']),
    );
  }
}
