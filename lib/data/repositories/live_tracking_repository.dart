import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:guardgrey/data/models/app_location.dart';
import 'package:guardgrey/data/models/manager_live_location_model.dart';
import 'package:guardgrey/data/repositories/firestore_repository_utils.dart';
import 'package:guardgrey/data/sources/firebase/guard_grey_firestore_seed_source.dart';

class LiveTrackingRepository {
  LiveTrackingRepository._({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static final LiveTrackingRepository instance = LiveTrackingRepository._();

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _liveLocations =>
      _firestore.collection(GuardGreyFirestoreSchema.managerLiveLocation);

  Stream<List<ManagerLiveLocationModel>> watchManagerLocations() {
    return _liveLocations
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _fromMap(doc.data()))
              .toList(growable: false),
        );
  }

  ManagerLiveLocationModel _fromMap(Map<String, dynamic> data) {
    return ManagerLiveLocationModel(
      managerId: (data['managerId'] as String? ?? '').trim(),
      managerName: (data['managerName'] as String? ?? '').trim(),
      lat: (data['lat'] as num?)?.toDouble() ?? 0,
      lng: (data['lng'] as num?)?.toDouble() ?? 0,
      lastUpdated: toDateTime(data['lastUpdated']) ?? DateTime.now(),
      checkInLocation: AppLocation.fromMap(mapValue(data['checkInLocation'])),
      branchImage: (data['branchImage'] as String? ?? '').trim(),
      helplineNumber: (data['helplineNumber'] as String? ?? '').trim(),
      whatsappNumber: (data['whatsappNumber'] as String? ?? '').trim(),
    );
  }
}
