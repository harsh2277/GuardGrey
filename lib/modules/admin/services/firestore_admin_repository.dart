import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/attendance_record.dart';
import '../models/branch_model.dart';
import '../models/client_model.dart';
import '../models/manager_model.dart';
import '../models/site_model.dart';
import '../models/visit_model.dart';
import 'firestore_seed_service.dart';

class FirestoreAdminRepository {
  FirestoreAdminRepository._({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  static final FirestoreAdminRepository instance =
      FirestoreAdminRepository._();

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _branches =>
      _firestore.collection(GuardGreyFirestoreSchema.branches);
  CollectionReference<Map<String, dynamic>> get _clients =>
      _firestore.collection(GuardGreyFirestoreSchema.clients);
  CollectionReference<Map<String, dynamic>> get _managers =>
      _firestore.collection(GuardGreyFirestoreSchema.managers);
  CollectionReference<Map<String, dynamic>> get _sites =>
      _firestore.collection(GuardGreyFirestoreSchema.sites);
  CollectionReference<Map<String, dynamic>> get _attendance =>
      _firestore.collection(GuardGreyFirestoreSchema.attendance);
  CollectionReference<Map<String, dynamic>> get _siteVisits =>
      _firestore.collection(GuardGreyFirestoreSchema.siteVisits);

  Stream<List<BranchModel>> watchBranches() {
    return _branches.orderBy('name').snapshots().map(
          (snapshot) => snapshot.docs
              .map(_branchFromDoc)
              .toList(growable: false),
        );
  }

  Stream<BranchModel?> watchBranch(String id) {
    return _branches.doc(id).snapshots().map(_branchFromSnapshot);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchBranchDocument(String id) {
    return _branches.doc(id).snapshots();
  }

  Stream<List<ClientModel>> watchClients() {
    return _clients.orderBy('name').snapshots().map(
          (snapshot) => snapshot.docs
              .map(_clientFromDoc)
              .toList(growable: false),
        );
  }

  Stream<ClientModel?> watchClient(String id) {
    return _clients.doc(id).snapshots().map(_clientFromSnapshot);
  }

  Stream<List<ManagerModel>> watchManagers() {
    return _managers.orderBy('name').snapshots().map(
          (snapshot) => snapshot.docs
              .map(_managerFromDoc)
              .toList(growable: false),
        );
  }

  Stream<ManagerModel?> watchManager(String id) {
    return _managers.doc(id).snapshots().map(_managerFromSnapshot);
  }

  Stream<List<SiteModel>> watchSites() {
    return _sites.orderBy('name').snapshots().map(
          (snapshot) => snapshot.docs
              .map(_siteFromDoc)
              .toList(growable: false),
        );
  }

  Stream<SiteModel?> watchSite(String id) {
    return _sites.doc(id).snapshots().map(_siteFromSnapshot);
  }

  Stream<List<AttendanceRecord>> watchAttendance() {
    return _attendance.orderBy('date', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
              .map(_attendanceFromDoc)
              .toList(growable: false),
        );
  }

  Stream<List<VisitModel>> watchSiteVisits(String siteId) {
    return _siteVisits
        .where('siteId', isEqualTo: siteId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(_visitFromDoc)
              .toList(growable: false),
        );
  }

  Future<List<BranchModel>> fetchBranches() async {
    final snapshot = await _branches.orderBy('name').get();
    return snapshot.docs.map(_branchFromDoc).toList(growable: false);
  }

  Future<List<ClientModel>> fetchClients() async {
    final snapshot = await _clients.orderBy('name').get();
    return snapshot.docs.map(_clientFromDoc).toList(growable: false);
  }

  Future<List<ManagerModel>> fetchManagers() async {
    final snapshot = await _managers.orderBy('name').get();
    return snapshot.docs.map(_managerFromDoc).toList(growable: false);
  }

  Future<List<SiteModel>> fetchSites() async {
    final snapshot = await _sites.orderBy('name').get();
    return snapshot.docs.map(_siteFromDoc).toList(growable: false);
  }

  Future<void> saveBranch(BranchModel branch) async {
    final docRef = _branches.doc(branch.id);
    final previous = await docRef.get();
    final previousModel = _branchFromSnapshot(previous);
    final previousSiteIds = previousModel?.siteIds.toSet() ?? <String>{};
    final nextSiteIds = branch.siteIds.toSet();
    final removedSiteIds = previousSiteIds.difference(nextSiteIds);

    final batch = _firestore.batch();
    batch.set(
      docRef,
      {
        'name': branch.name,
        'city': branch.city,
        'address': branch.address,
        'latitude': branch.latitude,
        'longitude': branch.longitude,
        'siteIds': branch.siteIds,
        if (!previous.exists) 'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    for (final siteId in branch.siteIds) {
      batch.set(
        _sites.doc(siteId),
        {
          'branchId': branch.id,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    for (final siteId in removedSiteIds) {
      batch.set(
        _sites.doc(siteId),
        {
          'branchId': '',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  Future<void> deleteBranch(String branchId) async {
    final docRef = _branches.doc(branchId);
    final snapshot = await docRef.get();
    final branch = _branchFromSnapshot(snapshot);
    final batch = _firestore.batch();

    for (final siteId in branch?.siteIds ?? const <String>[]) {
      batch.set(
        _sites.doc(siteId),
        {
          'branchId': '',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    batch.delete(docRef);
    await batch.commit();
  }

  Future<void> saveClient(ClientModel client) async {
    final docRef = _clients.doc(client.id);
    final previous = await docRef.get();
    final previousModel = _clientFromSnapshot(previous);
    final previousSiteIds = previousModel?.siteIds.toSet() ?? <String>{};
    final nextSiteIds = client.siteIds.toSet();
    final removedSiteIds = previousSiteIds.difference(nextSiteIds);

    final batch = _firestore.batch();
    batch.set(
      docRef,
      {
        'name': client.name,
        'email': client.email,
        'phone': client.phone,
        'branchId': client.branchId,
        'siteIds': client.siteIds,
        if (!previous.exists) 'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    for (final siteId in client.siteIds) {
      batch.set(
        _sites.doc(siteId),
        {
          'clientId': client.id,
          'branchId': client.branchId,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    for (final siteId in removedSiteIds) {
      batch.set(
        _sites.doc(siteId),
        {
          'clientId': '',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  Future<void> deleteClient(String clientId) async {
    final docRef = _clients.doc(clientId);
    final snapshot = await docRef.get();
    final client = _clientFromSnapshot(snapshot);
    final batch = _firestore.batch();

    for (final siteId in client?.siteIds ?? const <String>[]) {
      batch.set(
        _sites.doc(siteId),
        {
          'clientId': '',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    batch.delete(docRef);
    await batch.commit();
  }

  Future<void> saveManager(ManagerModel manager) async {
    final docRef = _managers.doc(manager.id);
    final previous = await docRef.get();
    final previousModel = _managerFromSnapshot(previous);
    final previousSiteIds = previousModel?.siteIds.toSet() ?? <String>{};
    final nextSiteIds = manager.siteIds.toSet();
    final removedSiteIds = previousSiteIds.difference(nextSiteIds);

    final batch = _firestore.batch();
    batch.set(
      docRef,
      {
        'name': manager.name,
        'email': manager.email,
        'phone': manager.phone,
        'siteIds': manager.siteIds,
        if (!previous.exists) 'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    for (final siteId in manager.siteIds) {
      batch.set(
        _sites.doc(siteId),
        {
          'managerId': manager.id,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    for (final siteId in removedSiteIds) {
      batch.set(
        _sites.doc(siteId),
        {
          'managerId': '',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  Future<void> deleteManager(String managerId) async {
    final docRef = _managers.doc(managerId);
    final snapshot = await docRef.get();
    final manager = _managerFromSnapshot(snapshot);
    final batch = _firestore.batch();

    for (final siteId in manager?.siteIds ?? const <String>[]) {
      batch.set(
        _sites.doc(siteId),
        {
          'managerId': '',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    batch.delete(docRef);
    await batch.commit();
  }

  Future<void> saveSite(SiteModel site) async {
    final docRef = _sites.doc(site.id);
    final previous = await docRef.get();
    final previousModel = _siteFromSnapshot(previous);

    final batch = _firestore.batch();
    batch.set(
      docRef,
      {
        'name': site.name,
        'clientId': site.clientId,
        'branchId': site.branchId,
        'managerId': site.managerId,
        'location': site.location,
        'address': site.address,
        'latitude': site.latitude,
        'longitude': site.longitude,
        'description': site.description,
        'isActive': site.isActive,
        if (!previous.exists) 'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    _syncSiteMembership(
      batch: batch,
      collection: _branches,
      previousOwnerId: previousModel?.branchId,
      nextOwnerId: site.branchId,
      siteId: site.id,
    );
    _syncSiteMembership(
      batch: batch,
      collection: _clients,
      previousOwnerId: previousModel?.clientId,
      nextOwnerId: site.clientId,
      siteId: site.id,
    );
    _syncSiteMembership(
      batch: batch,
      collection: _managers,
      previousOwnerId: previousModel?.managerId,
      nextOwnerId: site.managerId,
      siteId: site.id,
    );

    await batch.commit();
  }

  Future<void> deleteSite(String siteId) async {
    final docRef = _sites.doc(siteId);
    final snapshot = await docRef.get();
    final site = _siteFromSnapshot(snapshot);
    final batch = _firestore.batch();

    if (site != null) {
      _syncSiteMembership(
        batch: batch,
        collection: _branches,
        previousOwnerId: site.branchId,
        nextOwnerId: '',
        siteId: site.id,
      );
      _syncSiteMembership(
        batch: batch,
        collection: _clients,
        previousOwnerId: site.clientId,
        nextOwnerId: '',
        siteId: site.id,
      );
      _syncSiteMembership(
        batch: batch,
        collection: _managers,
        previousOwnerId: site.managerId,
        nextOwnerId: '',
        siteId: site.id,
      );
    }

    final visitSnapshot =
        await _siteVisits.where('siteId', isEqualTo: siteId).get();
    for (final visitDoc in visitSnapshot.docs) {
      batch.delete(visitDoc.reference);
    }

    batch.delete(docRef);
    await batch.commit();
  }

  void _syncSiteMembership({
    required WriteBatch batch,
    required CollectionReference<Map<String, dynamic>> collection,
    required String? previousOwnerId,
    required String nextOwnerId,
    required String siteId,
  }) {
    final normalizedPrevious = (previousOwnerId ?? '').trim();
    final normalizedNext = nextOwnerId.trim();

    if (normalizedPrevious.isNotEmpty &&
        normalizedPrevious != normalizedNext) {
      batch.set(
        collection.doc(normalizedPrevious),
        {
          'siteIds': FieldValue.arrayRemove([siteId]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    if (normalizedNext.isNotEmpty) {
      batch.set(
        collection.doc(normalizedNext),
        {
          'siteIds': FieldValue.arrayUnion([siteId]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
  }

  BranchModel _branchFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return _branchFromMap(doc.id, doc.data());
  }

  BranchModel? _branchFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    if (!snapshot.exists) {
      return null;
    }
    return _branchFromMap(snapshot.id, snapshot.data() ?? const {});
  }

  BranchModel _branchFromMap(String id, Map<String, dynamic> data) {
    return BranchModel(
      id: id,
      name: (data['name'] as String? ?? '').trim(),
      city: (data['city'] as String? ?? '').trim(),
      address: (data['address'] as String? ?? '').trim(),
      siteIds: _stringList(data['siteIds']),
      latitude: _toDouble(data['latitude']),
      longitude: _toDouble(data['longitude']),
    );
  }

  ClientModel _clientFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return _clientFromMap(doc.id, doc.data());
  }

  ClientModel? _clientFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    if (!snapshot.exists) {
      return null;
    }
    return _clientFromMap(snapshot.id, snapshot.data() ?? const {});
  }

  ClientModel _clientFromMap(String id, Map<String, dynamic> data) {
    return ClientModel(
      id: id,
      name: (data['name'] as String? ?? '').trim(),
      branchId: (data['branchId'] as String? ?? '').trim(),
      siteIds: _stringList(data['siteIds']),
      email: (data['email'] as String? ?? '').trim(),
      phone: (data['phone'] as String? ?? '').trim(),
    );
  }

  ManagerModel _managerFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return _managerFromMap(doc.id, doc.data());
  }

  ManagerModel? _managerFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    if (!snapshot.exists) {
      return null;
    }
    return _managerFromMap(snapshot.id, snapshot.data() ?? const {});
  }

  ManagerModel _managerFromMap(String id, Map<String, dynamic> data) {
    return ManagerModel(
      id: id,
      name: (data['name'] as String? ?? '').trim(),
      email: (data['email'] as String? ?? '').trim(),
      phone: (data['phone'] as String? ?? '').trim(),
      siteIds: _stringList(data['siteIds']),
    );
  }

  SiteModel _siteFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return _siteFromMap(doc.id, doc.data());
  }

  SiteModel? _siteFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    if (!snapshot.exists) {
      return null;
    }
    return _siteFromMap(snapshot.id, snapshot.data() ?? const {});
  }

  SiteModel _siteFromMap(String id, Map<String, dynamic> data) {
    final createdAt = _toDateTime(data['createdAt']);
    final updatedAt = _toDateTime(data['updatedAt']);
    final address = (data['address'] as String? ?? '').trim();
    final location = (data['location'] as String? ?? '').trim();

    return SiteModel(
      id: id,
      name: (data['name'] as String? ?? '').trim(),
      clientId: (data['clientId'] as String? ?? '').trim(),
      branchId: (data['branchId'] as String? ?? '').trim(),
      managerId: (data['managerId'] as String? ?? '').trim(),
      location: location.isNotEmpty ? location : address,
      address: address,
      latitude: _toDouble(data['latitude']),
      longitude: _toDouble(data['longitude']),
      description: (data['description'] as String? ?? '').trim(),
      createdDate: createdAt == null ? '' : formatDate(createdAt),
      lastUpdated: updatedAt == null ? '' : formatDate(updatedAt),
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  AttendanceRecord _attendanceFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return AttendanceRecord(
      id: doc.id,
      name: (data['managerName'] as String? ?? data['name'] as String? ?? '')
          .trim(),
      status: (data['status'] as String? ?? '').trim(),
      date: formatDate(_toDateTime(data['date'])),
      checkIn: formatTimeOrDash(_toDateTime(data['checkInAt'])),
      checkOut: formatTimeOrDash(_toDateTime(data['checkOutAt'])),
    );
  }

  VisitModel _visitFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return VisitModel(
      id: doc.id,
      siteId: (data['siteId'] as String? ?? '').trim(),
      managerName: (data['managerName'] as String? ?? '').trim(),
      date: formatDate(_toDateTime(data['date'])),
      day: (data['day'] as String? ?? '').trim(),
      time: (data['timeLabel'] as String? ?? '').trim(),
      notes: (data['notes'] as String? ?? '').trim(),
      status: (data['status'] as String? ?? '').trim(),
    );
  }

  List<String> _stringList(Object? value) {
    if (value is Iterable) {
      return value
          .map((item) => '$item'.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }

  double? _toDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String && value.trim().isNotEmpty) {
      return double.tryParse(value.trim());
    }
    return null;
  }

  static DateTime? _toDateTime(Object? value) {
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

  static String formatDate(DateTime? date) {
    if (date == null) {
      return '';
    }

    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day.toString().padLeft(2, '0')} '
        '${months[date.month - 1]} ${date.year}';
  }

  static String formatTimeOrDash(DateTime? date) {
    if (date == null) {
      return '-';
    }

    final hour = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')} $period';
  }
}
