import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreFieldDefinition {
  const FirestoreFieldDefinition({
    required this.name,
    required this.type,
    required this.required,
    required this.source,
    this.relationship,
  });

  final String name;
  final String type;
  final bool required;
  final String source;
  final String? relationship;
}

class FirestoreCollectionDefinition {
  const FirestoreCollectionDefinition({
    required this.name,
    required this.sourceScreens,
    required this.fields,
    this.notes = '',
  });

  final String name;
  final List<String> sourceScreens;
  final List<FirestoreFieldDefinition> fields;
  final String notes;
}

class GuardGreyFirestoreSchema {
  GuardGreyFirestoreSchema._();

  static const String branches = 'branches';
  static const String clients = 'clients';
  static const String managers = 'managers';
  static const String sites = 'sites';
  static const String attendance = 'attendance';
  static const String siteVisits = 'site_visits';
  static const String reports = 'reports';
  static const String fieldVisits = 'field_visits';
  static const String managerLeaves = 'manager_leaves';
  static const String managerLiveLocation = 'manager_live_location';
  static const String notifications = 'notifications';
  static const String adminNotificationTokens = 'admin_notification_tokens';

  static const List<FirestoreCollectionDefinition> collections = [
    FirestoreCollectionDefinition(
      name: branches,
      sourceScreens: [
        'BranchesScreen',
        'AddBranchScreen',
        'BranchDetailScreen',
      ],
      fields: [
        FirestoreFieldDefinition(
          name: 'name',
          type: 'string',
          required: true,
          source: 'Branch Name',
        ),
        FirestoreFieldDefinition(
          name: 'city',
          type: 'string',
          required: true,
          source: 'City / Location',
        ),
        FirestoreFieldDefinition(
          name: 'address',
          type: 'string',
          required: true,
          source: 'Location',
        ),
        FirestoreFieldDefinition(
          name: 'buildingFloor',
          type: 'string',
          required: false,
          source: 'Building / Floor',
        ),
        FirestoreFieldDefinition(
          name: 'latitude',
          type: 'double?',
          required: false,
          source: 'Location picker coordinates',
        ),
        FirestoreFieldDefinition(
          name: 'longitude',
          type: 'double?',
          required: false,
          source: 'Location picker coordinates',
        ),
        FirestoreFieldDefinition(
          name: 'siteIds',
          type: 'List<String>',
          required: true,
          source: 'Assign Sites',
          relationship: 'One branch -> many sites',
        ),
        FirestoreFieldDefinition(
          name: 'createdAt',
          type: 'Timestamp',
          required: true,
          source: 'Branch detail metadata',
        ),
        FirestoreFieldDefinition(
          name: 'updatedAt',
          type: 'Timestamp',
          required: true,
          source: 'Branch detail metadata',
        ),
      ],
      notes:
          'List and detail screens search and display name, city, address, and assigned site count.',
    ),
    FirestoreCollectionDefinition(
      name: clients,
      sourceScreens: ['ClientsScreen', 'AddClientScreen', 'ClientDetailScreen'],
      fields: [
        FirestoreFieldDefinition(
          name: 'name',
          type: 'string',
          required: true,
          source: 'Client Name',
        ),
        FirestoreFieldDefinition(
          name: 'email',
          type: 'string',
          required: true,
          source: 'Email ID',
        ),
        FirestoreFieldDefinition(
          name: 'phone',
          type: 'string',
          required: true,
          source: 'Mobile Number',
        ),
        FirestoreFieldDefinition(
          name: 'branchId',
          type: 'string',
          required: true,
          source: 'Assign Branch',
          relationship: 'Many clients -> one branch',
        ),
        FirestoreFieldDefinition(
          name: 'siteIds',
          type: 'List<String>',
          required: true,
          source: 'Assign Sites',
          relationship: 'Client-specific selected sites',
        ),
        FirestoreFieldDefinition(
          name: 'createdAt',
          type: 'Timestamp',
          required: true,
          source: 'Operational metadata',
        ),
        FirestoreFieldDefinition(
          name: 'updatedAt',
          type: 'Timestamp',
          required: true,
          source: 'Operational metadata',
        ),
      ],
      notes:
          'Client details and list cards depend on contact information, branch, and assigned site count.',
    ),
    FirestoreCollectionDefinition(
      name: managers,
      sourceScreens: [
        'ManagersListScreen',
        'AddManagerScreen',
        'ManagerDetailScreen',
      ],
      fields: [
        FirestoreFieldDefinition(
          name: 'name',
          type: 'string',
          required: true,
          source: 'Manager Name',
        ),
        FirestoreFieldDefinition(
          name: 'email',
          type: 'string',
          required: true,
          source: 'Email ID',
        ),
        FirestoreFieldDefinition(
          name: 'phone',
          type: 'string',
          required: true,
          source: 'Mobile Number',
        ),
        FirestoreFieldDefinition(
          name: 'profileImage',
          type: 'string?',
          required: false,
          source: 'Manager profile avatar',
        ),
        FirestoreFieldDefinition(
          name: 'siteIds',
          type: 'List<String>',
          required: true,
          source: 'Assign Sites',
          relationship: 'Manager can supervise many sites',
        ),
        FirestoreFieldDefinition(
          name: 'createdAt',
          type: 'Timestamp',
          required: true,
          source: 'Operational metadata',
        ),
        FirestoreFieldDefinition(
          name: 'updatedAt',
          type: 'Timestamp',
          required: true,
          source: 'Operational metadata',
        ),
      ],
      notes:
          'Search and detail screens only surface identity, contact data, and assigned sites.',
    ),
    FirestoreCollectionDefinition(
      name: sites,
      sourceScreens: ['SitesScreen', 'AddSiteScreen', 'SiteDetailScreen'],
      fields: [
        FirestoreFieldDefinition(
          name: 'name',
          type: 'string',
          required: true,
          source: 'Site Name',
        ),
        FirestoreFieldDefinition(
          name: 'clientId',
          type: 'string',
          required: true,
          source: 'Select Client',
          relationship: 'Many sites -> one client',
        ),
        FirestoreFieldDefinition(
          name: 'branchId',
          type: 'string',
          required: true,
          source: 'Select Branch',
          relationship: 'Many sites -> one branch',
        ),
        FirestoreFieldDefinition(
          name: 'managerId',
          type: 'string',
          required: true,
          source: 'Assign Manager',
          relationship: 'Many sites -> one primary manager',
        ),
        FirestoreFieldDefinition(
          name: 'location',
          type: 'string',
          required: true,
          source: 'Derived from Location / Address',
        ),
        FirestoreFieldDefinition(
          name: 'address',
          type: 'string',
          required: true,
          source: 'Address',
        ),
        FirestoreFieldDefinition(
          name: 'buildingFloor',
          type: 'string',
          required: false,
          source: 'Building / Floor',
        ),
        FirestoreFieldDefinition(
          name: 'latitude',
          type: 'double?',
          required: false,
          source: 'Location picker coordinates',
        ),
        FirestoreFieldDefinition(
          name: 'longitude',
          type: 'double?',
          required: false,
          source: 'Location picker coordinates',
        ),
        FirestoreFieldDefinition(
          name: 'description',
          type: 'string',
          required: false,
          source: 'Description',
        ),
        FirestoreFieldDefinition(
          name: 'isActive',
          type: 'bool',
          required: true,
          source: 'Site list status dot',
        ),
        FirestoreFieldDefinition(
          name: 'createdAt',
          type: 'Timestamp',
          required: true,
          source: 'Created date shown on detail screen',
        ),
        FirestoreFieldDefinition(
          name: 'updatedAt',
          type: 'Timestamp',
          required: true,
          source: 'Last updated shown on detail screen',
        ),
      ],
      notes:
          'Site is the central linking entity across branch, client, manager, attendance, and visits.',
    ),
    FirestoreCollectionDefinition(
      name: attendance,
      sourceScreens: [
        'AttendanceScreen',
        'AttendanceTable',
        'Cloud Function onAttendanceWritten',
      ],
      fields: [
        FirestoreFieldDefinition(
          name: 'managerId',
          type: 'string',
          required: true,
          source: 'Relationship inferred from manager attendance rows',
          relationship: 'Many attendance records -> one manager',
        ),
        FirestoreFieldDefinition(
          name: 'managerName',
          type: 'string',
          required: true,
          source: 'Attendance table Name column',
        ),
        FirestoreFieldDefinition(
          name: 'siteId',
          type: 'string?',
          required: false,
          source: 'Notification flow site context',
          relationship: 'Many attendance records -> one site',
        ),
        FirestoreFieldDefinition(
          name: 'siteName',
          type: 'string?',
          required: false,
          source: 'Notification message content',
        ),
        FirestoreFieldDefinition(
          name: 'status',
          type: 'string',
          required: true,
          source: 'Attendance table Status column',
        ),
        FirestoreFieldDefinition(
          name: 'date',
          type: 'Timestamp',
          required: true,
          source: 'Attendance table Date column',
        ),
        FirestoreFieldDefinition(
          name: 'checkInAt',
          type: 'Timestamp?',
          required: false,
          source: 'Attendance table Check-In column',
        ),
        FirestoreFieldDefinition(
          name: 'checkOutAt',
          type: 'Timestamp?',
          required: false,
          source: 'Attendance table Check-Out column',
        ),
        FirestoreFieldDefinition(
          name: 'updatedAt',
          type: 'Timestamp',
          required: true,
          source: 'Operational metadata and notification trigger',
        ),
      ],
      notes:
          'Cloud Function already listens to attendance writes and derives notifications from status/check-in/check-out changes.',
    ),
    FirestoreCollectionDefinition(
      name: siteVisits,
      sourceScreens: [
        'SiteDetailScreen',
        'VisitTable',
        'Cloud Function onSiteVisitCreated',
      ],
      fields: [
        FirestoreFieldDefinition(
          name: 'siteId',
          type: 'string',
          required: true,
          source: 'Visit History tab',
          relationship: 'Many visits -> one site',
        ),
        FirestoreFieldDefinition(
          name: 'siteName',
          type: 'string',
          required: true,
          source: 'Notification message content',
        ),
        FirestoreFieldDefinition(
          name: 'managerId',
          type: 'string',
          required: true,
          source: 'Visit origin inferred from manager activity',
          relationship: 'Many visits -> one manager',
        ),
        FirestoreFieldDefinition(
          name: 'managerName',
          type: 'string',
          required: true,
          source: 'Site detail search and notification flow',
        ),
        FirestoreFieldDefinition(
          name: 'date',
          type: 'Timestamp',
          required: true,
          source: 'Visit table Date column',
        ),
        FirestoreFieldDefinition(
          name: 'day',
          type: 'string',
          required: true,
          source: 'Visit table Day column',
        ),
        FirestoreFieldDefinition(
          name: 'timeLabel',
          type: 'string',
          required: true,
          source: 'Visit table Time column',
        ),
        FirestoreFieldDefinition(
          name: 'status',
          type: 'string',
          required: true,
          source: 'Visit table Status column',
        ),
        FirestoreFieldDefinition(
          name: 'notes',
          type: 'string',
          required: false,
          source: 'Site detail visit search',
        ),
        FirestoreFieldDefinition(
          name: 'createdAt',
          type: 'Timestamp',
          required: true,
          source: 'Operational metadata',
        ),
      ],
      notes:
          'Visit history is displayed under each site and already powers the visit notification function.',
    ),
    FirestoreCollectionDefinition(
      name: reports,
      sourceScreens: [
        'ReportsScreen',
        'ReportFormScreen',
        'ReportDetailScreen',
      ],
      fields: [
        FirestoreFieldDefinition(
          name: 'id',
          type: 'string',
          required: true,
          source: 'Document and payload identifier',
        ),
        FirestoreFieldDefinition(
          name: 'reportName',
          type: 'string',
          required: true,
          source: 'Report name',
        ),
        FirestoreFieldDefinition(
          name: 'reportType',
          type: 'string',
          required: true,
          source: 'Report type selector',
        ),
        FirestoreFieldDefinition(
          name: 'managerId',
          type: 'string',
          required: true,
          source: 'Assigned manager',
          relationship: 'Many reports -> one manager',
        ),
        FirestoreFieldDefinition(
          name: 'managerName',
          type: 'string',
          required: true,
          source: 'Manager display data',
        ),
        FirestoreFieldDefinition(
          name: 'dateTime',
          type: 'Timestamp',
          required: true,
          source: 'Report date and time',
        ),
        FirestoreFieldDefinition(
          name: 'location',
          type: 'map(lat,lng,address)',
          required: true,
          source: 'Auto-fetched manager location',
        ),
        FirestoreFieldDefinition(
          name: 'questions',
          type: 'List<Map<String,String>>',
          required: true,
          source: 'Dynamic questions array',
        ),
        FirestoreFieldDefinition(
          name: 'imageUrls',
          type: 'List<String>',
          required: false,
          source: 'Firebase Storage URLs',
        ),
        FirestoreFieldDefinition(
          name: 'createdAt',
          type: 'Timestamp',
          required: true,
          source: 'Operational metadata',
        ),
        FirestoreFieldDefinition(
          name: 'updatedAt',
          type: 'Timestamp',
          required: true,
          source: 'Operational metadata',
        ),
      ],
      notes:
          'Structured reporting module used by admins for training, site visits, and night visits.',
    ),
    FirestoreCollectionDefinition(
      name: fieldVisits,
      sourceScreens: [
        'FieldVisitListScreen',
        'FieldVisitFormScreen',
        'FieldVisitDetailScreen',
      ],
      fields: [
        FirestoreFieldDefinition(
          name: 'id',
          type: 'string',
          required: true,
          source: 'Document and payload identifier',
        ),
        FirestoreFieldDefinition(
          name: 'managerId',
          type: 'string',
          required: true,
          source: 'Current signed-in manager',
          relationship: 'Many field visits -> one manager',
        ),
        FirestoreFieldDefinition(
          name: 'managerName',
          type: 'string',
          required: true,
          source: 'Manager snapshot',
        ),
        FirestoreFieldDefinition(
          name: 'phone',
          type: 'string',
          required: true,
          source: 'Manager snapshot',
        ),
        FirestoreFieldDefinition(
          name: 'profileImage',
          type: 'string',
          required: false,
          source: 'Manager snapshot',
        ),
        FirestoreFieldDefinition(
          name: 'siteName',
          type: 'string',
          required: true,
          source: 'Manual site entry',
        ),
        FirestoreFieldDefinition(
          name: 'description',
          type: 'string',
          required: true,
          source: 'Visit description',
        ),
        FirestoreFieldDefinition(
          name: 'location',
          type: 'map(lat,lng,address)',
          required: true,
          source: 'Map picker result',
        ),
        FirestoreFieldDefinition(
          name: 'imageUrls',
          type: 'List<String>',
          required: false,
          source: 'Firebase Storage URLs',
        ),
        FirestoreFieldDefinition(
          name: 'dateTime',
          type: 'Timestamp',
          required: true,
          source: 'Visit date and time',
        ),
        FirestoreFieldDefinition(
          name: 'createdAt',
          type: 'Timestamp',
          required: true,
          source: 'Operational metadata',
        ),
      ],
      notes:
          'Field visits remain separate from site visits and capture richer media and location data.',
    ),
    FirestoreCollectionDefinition(
      name: managerLeaves,
      sourceScreens: ['ManagerLeaveScreen', 'ManagerLeaveFormScreen'],
      fields: [
        FirestoreFieldDefinition(
          name: 'managerId',
          type: 'string',
          required: true,
          source: 'Current signed-in manager',
          relationship: 'Many leave requests -> one manager',
        ),
        FirestoreFieldDefinition(
          name: 'managerName',
          type: 'string',
          required: true,
          source: 'Manager identity on leave list',
        ),
        FirestoreFieldDefinition(
          name: 'leaveType',
          type: 'string',
          required: true,
          source: 'Leave type selector',
        ),
        FirestoreFieldDefinition(
          name: 'fromDate',
          type: 'Timestamp',
          required: true,
          source: 'Leave start date',
        ),
        FirestoreFieldDefinition(
          name: 'toDate',
          type: 'Timestamp',
          required: true,
          source: 'Leave end date',
        ),
        FirestoreFieldDefinition(
          name: 'reason',
          type: 'string',
          required: true,
          source: 'Leave request reason',
        ),
        FirestoreFieldDefinition(
          name: 'status',
          type: 'string',
          required: true,
          source: 'Pending / Approved / Rejected chip',
        ),
        FirestoreFieldDefinition(
          name: 'createdAt',
          type: 'Timestamp',
          required: true,
          source: 'Operational metadata',
        ),
        FirestoreFieldDefinition(
          name: 'updatedAt',
          type: 'Timestamp',
          required: true,
          source: 'Operational metadata',
        ),
      ],
      notes:
          'Supports the manager leave module with editable pending requests and historical status display.',
    ),
    FirestoreCollectionDefinition(
      name: managerLiveLocation,
      sourceScreens: ['LiveTrackingScreen'],
      fields: [
        FirestoreFieldDefinition(
          name: 'managerId',
          type: 'string',
          required: true,
          source: 'Location owner',
          relationship: 'One manager -> one live location document',
        ),
        FirestoreFieldDefinition(
          name: 'managerName',
          type: 'string',
          required: true,
          source: 'Manager display data',
        ),
        FirestoreFieldDefinition(
          name: 'lat',
          type: 'double',
          required: true,
          source: 'Map marker latitude',
        ),
        FirestoreFieldDefinition(
          name: 'lng',
          type: 'double',
          required: true,
          source: 'Map marker longitude',
        ),
        FirestoreFieldDefinition(
          name: 'lastUpdated',
          type: 'Timestamp',
          required: true,
          source: 'Last sync timestamp',
        ),
        FirestoreFieldDefinition(
          name: 'checkInLocation',
          type: 'map(lat,lng,address)',
          required: true,
          source: 'Reference check-in location',
        ),
        FirestoreFieldDefinition(
          name: 'branchImage',
          type: 'string',
          required: false,
          source: 'Branch illustration URL',
        ),
        FirestoreFieldDefinition(
          name: 'helplineNumber',
          type: 'string',
          required: true,
          source: 'Emergency contact',
        ),
        FirestoreFieldDefinition(
          name: 'whatsappNumber',
          type: 'string',
          required: true,
          source: 'WhatsApp contact',
        ),
      ],
      notes: 'Admin live tracking map consumes this collection in real time.',
    ),
    FirestoreCollectionDefinition(
      name: notifications,
      sourceScreens: ['NotificationsScreen', 'NotificationRepository'],
      fields: [
        FirestoreFieldDefinition(
          name: 'title',
          type: 'string',
          required: true,
          source: 'Notification list title',
        ),
        FirestoreFieldDefinition(
          name: 'message',
          type: 'string',
          required: true,
          source: 'Notification list message',
        ),
        FirestoreFieldDefinition(
          name: 'type',
          type: 'string',
          required: true,
          source: 'Notification icon and color state',
        ),
        FirestoreFieldDefinition(
          name: 'createdAt',
          type: 'Timestamp',
          required: true,
          source: 'Notification ordering and relative time',
        ),
        FirestoreFieldDefinition(
          name: 'isRead',
          type: 'bool',
          required: true,
          source: 'Unread state and badge count',
        ),
        FirestoreFieldDefinition(
          name: 'readAt',
          type: 'Timestamp?',
          required: false,
          source: 'Mark as read action',
        ),
        FirestoreFieldDefinition(
          name: 'sourceCollection',
          type: 'string?',
          required: false,
          source: 'Cloud Function provenance',
        ),
        FirestoreFieldDefinition(
          name: 'sourceId',
          type: 'string?',
          required: false,
          source: 'Cloud Function provenance',
        ),
      ],
      notes:
          'This collection is already live in the app via NotificationRepository.watchNotifications().',
    ),
    FirestoreCollectionDefinition(
      name: adminNotificationTokens,
      sourceScreens: ['PushNotificationService', 'NotificationRepository'],
      fields: [
        FirestoreFieldDefinition(
          name: 'token',
          type: 'string',
          required: true,
          source: 'FCM registration token',
        ),
        FirestoreFieldDefinition(
          name: 'role',
          type: 'string',
          required: true,
          source: 'NotificationRepository.upsertAdminToken',
        ),
        FirestoreFieldDefinition(
          name: 'platform',
          type: 'string',
          required: true,
          source: 'NotificationRepository.upsertAdminToken',
        ),
        FirestoreFieldDefinition(
          name: 'notificationsEnabled',
          type: 'bool',
          required: true,
          source: 'Settings / push notification state',
        ),
        FirestoreFieldDefinition(
          name: 'updatedAt',
          type: 'Timestamp',
          required: true,
          source: 'NotificationRepository.upsertAdminToken',
        ),
      ],
      notes:
          'Operational collection for push delivery; intentionally not populated by seedDatabase().',
    ),
  ];
}

class GuardGreyCollectionRefs {
  GuardGreyCollectionRefs({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get branches =>
      _firestore.collection(GuardGreyFirestoreSchema.branches);

  CollectionReference<Map<String, dynamic>> get clients =>
      _firestore.collection(GuardGreyFirestoreSchema.clients);

  CollectionReference<Map<String, dynamic>> get managers =>
      _firestore.collection(GuardGreyFirestoreSchema.managers);

  CollectionReference<Map<String, dynamic>> get sites =>
      _firestore.collection(GuardGreyFirestoreSchema.sites);

  CollectionReference<Map<String, dynamic>> get attendance =>
      _firestore.collection(GuardGreyFirestoreSchema.attendance);

  CollectionReference<Map<String, dynamic>> get siteVisits =>
      _firestore.collection(GuardGreyFirestoreSchema.siteVisits);

  CollectionReference<Map<String, dynamic>> get reports =>
      _firestore.collection(GuardGreyFirestoreSchema.reports);

  CollectionReference<Map<String, dynamic>> get fieldVisits =>
      _firestore.collection(GuardGreyFirestoreSchema.fieldVisits);

  CollectionReference<Map<String, dynamic>> get managerLeaves =>
      _firestore.collection(GuardGreyFirestoreSchema.managerLeaves);

  CollectionReference<Map<String, dynamic>> get managerLiveLocation =>
      _firestore.collection(GuardGreyFirestoreSchema.managerLiveLocation);

  CollectionReference<Map<String, dynamic>> get notifications =>
      _firestore.collection(GuardGreyFirestoreSchema.notifications);

  CollectionReference<Map<String, dynamic>> get adminNotificationTokens =>
      _firestore.collection(GuardGreyFirestoreSchema.adminNotificationTokens);
}

class GuardGreyFirestoreCrud {
  GuardGreyFirestoreCrud({FirebaseFirestore? firestore})
    : _refs = GuardGreyCollectionRefs(firestore: firestore);

  final GuardGreyCollectionRefs _refs;

  Future<void> upsertBranch(String id, Map<String, dynamic> data) =>
      _refs.branches.doc(id).set(data, SetOptions(merge: true));

  Future<void> upsertClient(String id, Map<String, dynamic> data) =>
      _refs.clients.doc(id).set(data, SetOptions(merge: true));

  Future<void> upsertManager(String id, Map<String, dynamic> data) =>
      _refs.managers.doc(id).set(data, SetOptions(merge: true));

  Future<void> upsertSite(String id, Map<String, dynamic> data) =>
      _refs.sites.doc(id).set(data, SetOptions(merge: true));

  Future<void> upsertAttendance(String id, Map<String, dynamic> data) =>
      _refs.attendance.doc(id).set(data, SetOptions(merge: true));

  Future<void> upsertSiteVisit(String id, Map<String, dynamic> data) =>
      _refs.siteVisits.doc(id).set(data, SetOptions(merge: true));

  Future<void> upsertReport(String id, Map<String, dynamic> data) =>
      _refs.reports.doc(id).set(data, SetOptions(merge: true));

  Future<void> upsertFieldVisit(String id, Map<String, dynamic> data) =>
      _refs.fieldVisits.doc(id).set(data, SetOptions(merge: true));

  Future<void> upsertManagerLeave(String id, Map<String, dynamic> data) =>
      _refs.managerLeaves.doc(id).set(data, SetOptions(merge: true));

  Future<void> upsertManagerLiveLocation(
    String id,
    Map<String, dynamic> data,
  ) => _refs.managerLiveLocation.doc(id).set(data, SetOptions(merge: true));

  Future<void> upsertNotification(String id, Map<String, dynamic> data) =>
      _refs.notifications.doc(id).set(data, SetOptions(merge: true));
}

Future<void> seedDatabase({
  FirebaseFirestore? firestore,
  bool clearExisting = false,
  bool includeReports = true,
  bool includeVisits = true,
  bool includeLiveTracking = true,
}) async {
  final db = firestore ?? FirebaseFirestore.instance;
  final refs = GuardGreyCollectionRefs(firestore: db);

  debugPrint('Seeding started...');
  debugPrint('Using Firestore app: ${db.app.name}');

  if (clearExisting) {
    debugPrint('Clearing existing seed collections...');
    await _clearSeedCollections(refs);
  }

  final ahmedabadCreatedAt = _ts(2026, 1, 12, 9, 30);
  final rajkotCreatedAt = _ts(2026, 2, 3, 10, 0);
  final suratCreatedAt = _ts(2026, 3, 18, 11, 20);
  final vadodaraCreatedAt = _ts(2026, 3, 22, 8, 45);
  final now = _ts(2026, 4, 28, 9, 0);

  final branches = <String, Map<String, dynamic>>{
    'branch_ahmedabad': {
      'name': 'Ahmedabad',
      'city': 'Ahmedabad',
      'address': 'Ashram Road, Navrangpura, Ahmedabad, Gujarat 380009',
      'buildingFloor': 'Commerce House, Ground Floor',
      'latitude': 23.0395,
      'longitude': 72.5315,
      'siteIds': [
        'site_mall_security',
        'site_office_building',
        'site_warehouse_gate',
      ],
      'createdAt': ahmedabadCreatedAt,
      'updatedAt': now,
    },
    'branch_rajkot': {
      'name': 'Rajkot',
      'city': 'Rajkot',
      'address': 'Kalawad Road, Nana Mava, Rajkot, Gujarat 360005',
      'buildingFloor': 'Silver Heights, 2nd Floor',
      'latitude': 22.2901,
      'longitude': 70.7853,
      'siteIds': ['site_corporate_park', 'site_hospital_campus'],
      'createdAt': rajkotCreatedAt,
      'updatedAt': now,
    },
    'branch_surat': {
      'name': 'Surat',
      'city': 'Surat',
      'address': 'Ring Road, Sahara Darwaja, Surat, Gujarat 395002',
      'buildingFloor': 'Textile Hub, 3rd Floor',
      'latitude': 21.1702,
      'longitude': 72.8311,
      'siteIds': ['site_logistics_hub'],
      'createdAt': suratCreatedAt,
      'updatedAt': now,
    },
    'branch_vadodara': {
      'name': 'Vadodara',
      'city': 'Vadodara',
      'address': 'RC Dutt Road, Alkapuri, Vadodara, Gujarat 390007',
      'buildingFloor': 'Centre Point, 4th Floor',
      'latitude': 22.3072,
      'longitude': 73.1812,
      'siteIds': ['site_industrial_plant'],
      'createdAt': vadodaraCreatedAt,
      'updatedAt': now,
    },
  };

  final clients = <String, Map<String, dynamic>>{
    'client_alpha_retail': {
      'name': 'Alpha Retail',
      'branchId': 'branch_ahmedabad',
      'siteIds': ['site_mall_security', 'site_industrial_plant'],
      'email': 'ops@alpharetail.com',
      'phone': '+91 98250 22001',
      'createdAt': _ts(2026, 1, 10, 12, 0),
      'updatedAt': now,
    },
    'client_pinnacle_offices': {
      'name': 'Pinnacle Offices',
      'branchId': 'branch_ahmedabad',
      'siteIds': ['site_office_building', 'site_corporate_park'],
      'email': 'admin@pinnacleoffices.com',
      'phone': '+91 98250 22002',
      'createdAt': _ts(2026, 1, 14, 11, 10),
      'updatedAt': now,
    },
    'client_careplus_health': {
      'name': 'CarePlus Health',
      'branchId': 'branch_rajkot',
      'siteIds': ['site_hospital_campus'],
      'email': 'support@careplushealth.com',
      'phone': '+91 98250 22003',
      'createdAt': _ts(2026, 2, 6, 13, 25),
      'updatedAt': now,
    },
    'client_prime_logistics': {
      'name': 'Prime Logistics',
      'branchId': 'branch_surat',
      'siteIds': ['site_warehouse_gate', 'site_logistics_hub'],
      'email': 'control@primelogistics.com',
      'phone': '+91 98250 22004',
      'createdAt': _ts(2026, 1, 18, 16, 5),
      'updatedAt': now,
    },
  };

  final managers = <String, Map<String, dynamic>>{
    'manager_ravi_patel': {
      'name': 'Ravi Patel',
      'email': 'ravi.patel@guardgrey.com',
      'phone': '+91 98765 11001',
      'profileImage': 'https://i.pravatar.cc/300?img=12',
      'siteIds': ['site_mall_security', 'site_industrial_plant'],
      'createdAt': _ts(2026, 1, 5, 9, 0),
      'updatedAt': now,
    },
    'manager_heena_shah': {
      'name': 'Heena Shah',
      'email': 'heena.shah@guardgrey.com',
      'phone': '+91 98765 11002',
      'profileImage': 'https://i.pravatar.cc/300?img=32',
      'siteIds': ['site_office_building'],
      'createdAt': _ts(2026, 1, 6, 9, 30),
      'updatedAt': now,
    },
    'manager_amit_joshi': {
      'name': 'Amit Joshi',
      'email': 'amit.joshi@guardgrey.com',
      'phone': '+91 98765 11003',
      'profileImage': 'https://i.pravatar.cc/300?img=15',
      'siteIds': ['site_warehouse_gate', 'site_logistics_hub'],
      'createdAt': _ts(2026, 1, 7, 10, 0),
      'updatedAt': now,
    },
    'manager_sneha_trivedi': {
      'name': 'Sneha Trivedi',
      'email': 'sneha.trivedi@guardgrey.com',
      'phone': '+91 98765 11004',
      'profileImage': 'https://i.pravatar.cc/300?img=47',
      'siteIds': ['site_corporate_park'],
      'createdAt': _ts(2026, 1, 8, 10, 20),
      'updatedAt': now,
    },
    'manager_kunal_mehta': {
      'name': 'Kunal Mehta',
      'email': 'kunal.mehta@guardgrey.com',
      'phone': '+91 98765 11005',
      'profileImage': 'https://i.pravatar.cc/300?img=68',
      'siteIds': ['site_hospital_campus'],
      'createdAt': _ts(2026, 1, 9, 10, 40),
      'updatedAt': now,
    },
    'manager_guardpulse_demo': {
      'name': 'Manager Demo',
      'email': 'manager123@gmail.com',
      'phone': '+91 98765 22001',
      'profileImage': 'https://i.pravatar.cc/300?img=23',
      'siteIds': [
        'site_mall_security',
        'site_logistics_hub',
        'site_corporate_park',
      ],
      'createdAt': _ts(2026, 1, 10, 11, 15),
      'updatedAt': now,
    },
  };

  final sites = <String, Map<String, dynamic>>{
    'site_mall_security': {
      'name': 'Mall Security',
      'clientId': 'client_alpha_retail',
      'branchId': 'branch_ahmedabad',
      'managerId': 'manager_ravi_patel',
      'location': 'Satellite, Ahmedabad',
      'address': 'Alpha One Mall, Satellite, Ahmedabad',
      'buildingFloor': 'Alpha One Mall, Lower Ground Floor',
      'latitude': 23.0273,
      'longitude': 72.5069,
      'description': 'Retail security point with day and night shift coverage.',
      'createdAt': _ts(2026, 1, 12, 9, 15),
      'updatedAt': _ts(2026, 4, 26, 18, 0),
      'isActive': true,
    },
    'site_office_building': {
      'name': 'Office Building',
      'clientId': 'client_pinnacle_offices',
      'branchId': 'branch_ahmedabad',
      'managerId': 'manager_heena_shah',
      'location': 'Prahlad Nagar, Ahmedabad',
      'address': 'Pinnacle Business Park, Prahlad Nagar, Ahmedabad',
      'buildingFloor': 'Pinnacle Business Park, 8th Floor',
      'latitude': 23.0115,
      'longitude': 72.5108,
      'description':
          'Corporate tower access management and patrol supervision.',
      'createdAt': _ts(2026, 1, 14, 10, 50),
      'updatedAt': _ts(2026, 4, 25, 17, 30),
      'isActive': true,
    },
    'site_warehouse_gate': {
      'name': 'Warehouse Gate',
      'clientId': 'client_prime_logistics',
      'branchId': 'branch_ahmedabad',
      'managerId': 'manager_amit_joshi',
      'location': 'Naroda, Ahmedabad',
      'address': 'Naroda GIDC Entry Gate, Ahmedabad',
      'buildingFloor': 'Warehouse Block A, Ground Floor',
      'latitude': 23.0716,
      'longitude': 72.6760,
      'description': 'Inbound and outbound vehicle log monitoring.',
      'createdAt': _ts(2026, 1, 18, 8, 40),
      'updatedAt': _ts(2026, 4, 24, 12, 20),
      'isActive': false,
    },
    'site_corporate_park': {
      'name': 'Corporate Park',
      'clientId': 'client_pinnacle_offices',
      'branchId': 'branch_rajkot',
      'managerId': 'manager_sneha_trivedi',
      'location': 'Kalawad Road, Rajkot',
      'address': 'Corporate Avenue, Kalawad Road, Rajkot',
      'buildingFloor': 'Corporate Avenue, 5th Floor',
      'latitude': 22.2868,
      'longitude': 70.7687,
      'description': 'Corporate campus security desk and visitor control.',
      'createdAt': _ts(2026, 2, 3, 11, 35),
      'updatedAt': _ts(2026, 4, 26, 16, 5),
      'isActive': true,
    },
    'site_hospital_campus': {
      'name': 'Hospital Campus',
      'clientId': 'client_careplus_health',
      'branchId': 'branch_rajkot',
      'managerId': 'manager_kunal_mehta',
      'location': '150 Feet Ring Road, Rajkot',
      'address': 'Lifeline Hospital Campus, Rajkot',
      'buildingFloor': 'OPD Wing, Ground Floor',
      'latitude': 22.2927,
      'longitude': 70.7794,
      'description': 'Emergency gate and OPD entry coverage with 24/7 staff.',
      'createdAt': _ts(2026, 2, 6, 7, 55),
      'updatedAt': _ts(2026, 4, 23, 9, 40),
      'isActive': true,
    },
    'site_logistics_hub': {
      'name': 'Logistics Hub',
      'clientId': 'client_prime_logistics',
      'branchId': 'branch_surat',
      'managerId': 'manager_amit_joshi',
      'location': 'Sachin, Surat',
      'address': 'Freight Terminal, Sachin, Surat',
      'buildingFloor': 'Dispatch Building, 1st Floor',
      'latitude': 21.0877,
      'longitude': 72.8811,
      'description': 'Large dispatch yard with delivery gate checkpoints.',
      'createdAt': _ts(2026, 3, 18, 14, 5),
      'updatedAt': _ts(2026, 4, 22, 11, 15),
      'isActive': true,
    },
    'site_industrial_plant': {
      'name': 'Industrial Plant',
      'clientId': 'client_alpha_retail',
      'branchId': 'branch_vadodara',
      'managerId': 'manager_ravi_patel',
      'location': 'Makarpura, Vadodara',
      'address': 'Plant 4, Makarpura Industrial Estate, Vadodara',
      'buildingFloor': 'Plant 4, Security Mezzanine',
      'latitude': 22.2772,
      'longitude': 73.1937,
      'description': 'Manufacturing floor perimeter and plant gate security.',
      'createdAt': _ts(2026, 3, 22, 9, 20),
      'updatedAt': _ts(2026, 4, 21, 15, 25),
      'isActive': true,
    },
  };

  final attendance = <String, Map<String, dynamic>>{
    'attendance_ravi_2026_04_27': {
      'managerId': 'manager_ravi_patel',
      'managerName': 'Ravi Patel',
      'siteId': 'site_mall_security',
      'siteName': 'Mall Security',
      'status': 'Present',
      'date': _ts(2026, 4, 27),
      'checkInAt': _ts(2026, 4, 27, 8, 55),
      'checkOutAt': _ts(2026, 4, 27, 18, 10),
      'updatedAt': _ts(2026, 4, 27, 18, 10),
    },
    'attendance_heena_2026_04_27': {
      'managerId': 'manager_heena_shah',
      'managerName': 'Heena Shah',
      'siteId': 'site_office_building',
      'siteName': 'Office Building',
      'status': 'Present',
      'date': _ts(2026, 4, 27),
      'checkInAt': _ts(2026, 4, 27, 9, 5),
      'checkOutAt': _ts(2026, 4, 27, 18, 0),
      'updatedAt': _ts(2026, 4, 27, 18, 0),
    },
    'attendance_amit_2026_04_27': {
      'managerId': 'manager_amit_joshi',
      'managerName': 'Amit Joshi',
      'siteId': 'site_logistics_hub',
      'siteName': 'Logistics Hub',
      'status': 'Absent',
      'date': _ts(2026, 4, 27),
      'checkInAt': null,
      'checkOutAt': null,
      'updatedAt': _ts(2026, 4, 27, 9, 10),
    },
    'attendance_sneha_2026_04_27': {
      'managerId': 'manager_sneha_trivedi',
      'managerName': 'Sneha Trivedi',
      'siteId': 'site_corporate_park',
      'siteName': 'Corporate Park',
      'status': 'Present',
      'date': _ts(2026, 4, 27),
      'checkInAt': _ts(2026, 4, 27, 8, 48),
      'checkOutAt': _ts(2026, 4, 27, 17, 52),
      'updatedAt': _ts(2026, 4, 27, 17, 52),
    },
    'attendance_kunal_2026_04_27': {
      'managerId': 'manager_kunal_mehta',
      'managerName': 'Kunal Mehta',
      'siteId': 'site_hospital_campus',
      'siteName': 'Hospital Campus',
      'status': 'Absent',
      'date': _ts(2026, 4, 27),
      'checkInAt': null,
      'checkOutAt': null,
      'updatedAt': _ts(2026, 4, 27, 8, 30),
    },
    'attendance_guardpulse_demo_2026_04_28': {
      'managerId': 'manager_guardpulse_demo',
      'managerName': 'Manager Demo',
      'siteId': 'site_mall_security',
      'siteName': 'Mall Security',
      'status': 'Present',
      'date': _ts(2026, 4, 28),
      'checkInAt': _ts(2026, 4, 28, 8, 58),
      'checkOutAt': _ts(2026, 4, 28, 18, 4),
      'updatedAt': _ts(2026, 4, 28, 18, 4),
    },
  };

  final siteVisits = <String, Map<String, dynamic>>{
    'visit_mall_2026_04_26': {
      'siteId': 'site_mall_security',
      'siteName': 'Mall Security',
      'managerId': 'manager_ravi_patel',
      'managerName': 'Ravi Patel',
      'date': _ts(2026, 4, 26, 9, 15),
      'day': 'Sunday',
      'timeLabel': '09:15 AM',
      'status': 'Completed',
      'notes': 'Routine morning inspection completed.',
      'imageUrls': [
        'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=1200&q=80',
      ],
      'checklist': [
        'Uniform checked',
        'Logbook reviewed',
        'Supervisor briefing done',
      ],
      'createdAt': _ts(2026, 4, 26, 9, 15),
    },
    'visit_mall_2026_04_25': {
      'siteId': 'site_mall_security',
      'siteName': 'Mall Security',
      'managerId': 'manager_heena_shah',
      'managerName': 'Heena Shah',
      'date': _ts(2026, 4, 25, 18, 40),
      'day': 'Saturday',
      'timeLabel': '06:40 PM',
      'status': 'Completed',
      'notes': 'Shift handoff reviewed with supervisor.',
      'imageUrls': [
        'https://images.unsplash.com/photo-1497366754035-f200968a6e72?auto=format&fit=crop&w=1200&q=80',
      ],
      'checklist': ['Logbook reviewed', 'Supervisor briefing done'],
      'createdAt': _ts(2026, 4, 25, 18, 40),
    },
    'visit_office_2026_04_26': {
      'siteId': 'site_office_building',
      'siteName': 'Office Building',
      'managerId': 'manager_amit_joshi',
      'managerName': 'Amit Joshi',
      'date': _ts(2026, 4, 26, 11, 0),
      'day': 'Sunday',
      'timeLabel': '11:00 AM',
      'status': 'In Progress',
      'notes': 'Visitor desk escalation reviewed.',
      'imageUrls': [
        'https://images.unsplash.com/photo-1517048676732-d65bc937f952?auto=format&fit=crop&w=1200&q=80',
      ],
      'checklist': ['Uniform checked'],
      'createdAt': _ts(2026, 4, 26, 11, 0),
    },
    'visit_corporate_2026_04_24': {
      'siteId': 'site_corporate_park',
      'siteName': 'Corporate Park',
      'managerId': 'manager_sneha_trivedi',
      'managerName': 'Sneha Trivedi',
      'date': _ts(2026, 4, 24, 16, 20),
      'day': 'Friday',
      'timeLabel': '04:20 PM',
      'status': 'Completed',
      'notes': 'Parking access issue resolved.',
      'imageUrls': [
        'https://images.unsplash.com/photo-1520607162513-77705c0f0d4a?auto=format&fit=crop&w=1200&q=80',
      ],
      'checklist': ['Uniform checked', 'Logbook reviewed'],
      'createdAt': _ts(2026, 4, 24, 16, 20),
    },
    'visit_hospital_2026_04_23': {
      'siteId': 'site_hospital_campus',
      'siteName': 'Hospital Campus',
      'managerId': 'manager_kunal_mehta',
      'managerName': 'Kunal Mehta',
      'date': _ts(2026, 4, 23, 8, 10),
      'day': 'Thursday',
      'timeLabel': '08:10 AM',
      'status': 'Scheduled',
      'notes': '',
      'imageUrls': [
        'https://images.unsplash.com/photo-1517502884422-41eaead166d4?auto=format&fit=crop&w=1200&q=80',
      ],
      'checklist': ['Supervisor briefing done'],
      'createdAt': _ts(2026, 4, 23, 8, 10),
    },
    'visit_guardpulse_demo_2026_04_28_1': {
      'siteId': 'site_mall_security',
      'siteName': 'Mall Security',
      'managerId': 'manager_guardpulse_demo',
      'managerName': 'Manager Demo',
      'date': _ts(2026, 4, 28, 10, 30),
      'day': 'Monday',
      'timeLabel': '10:30 AM',
      'status': 'Completed',
      'notes':
          'Completed supervisor floor round, reviewed parking gate roster, and captured proof images.',
      'imageUrls': [
        'https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&w=1200&q=80',
      ],
      'checklist': [
        'Uniform checked',
        'Logbook reviewed',
        'Supervisor briefing done',
      ],
      'createdAt': _ts(2026, 4, 28, 10, 30),
    },
    'visit_guardpulse_demo_2026_04_29_1': {
      'siteId': 'site_logistics_hub',
      'siteName': 'Logistics Hub',
      'managerId': 'manager_guardpulse_demo',
      'managerName': 'Manager Demo',
      'date': _ts(2026, 4, 29, 15, 0),
      'day': 'Tuesday',
      'timeLabel': '03:00 PM',
      'status': 'Pending',
      'notes':
          'Scheduled dispatch-bay inspection and evening shift handover verification.',
      'imageUrls': [
        'https://images.unsplash.com/photo-1504307651254-35680f356dfd?auto=format&fit=crop&w=1200&q=80',
      ],
      'checklist': ['Uniform checked', 'Logbook reviewed'],
      'createdAt': _ts(2026, 4, 28, 18, 15),
    },
  };

  final notifications = <String, Map<String, dynamic>>{
    'notification_attendance_1': {
      'title': 'Manager Checked In',
      'message': 'Ravi Patel checked in at Mall Security.',
      'type': 'attendance',
      'sourceCollection': 'attendance',
      'sourceId': 'attendance_ravi_2026_04_27',
      'createdAt': _ts(2026, 4, 27, 8, 56),
      'isRead': false,
      'readAt': null,
    },
    'notification_attendance_2': {
      'title': 'Attendance Updated',
      'message': 'Amit Joshi attendance was updated to Absent.',
      'type': 'attendance',
      'sourceCollection': 'attendance',
      'sourceId': 'attendance_amit_2026_04_27',
      'createdAt': _ts(2026, 4, 27, 9, 11),
      'isRead': true,
      'readAt': _ts(2026, 4, 27, 9, 45),
    },
    'notification_visit_1': {
      'title': 'Site Visit Submitted',
      'message': 'Sneha Trivedi submitted a site visit for Corporate Park.',
      'type': 'visit',
      'sourceCollection': 'site_visits',
      'sourceId': 'visit_corporate_2026_04_24',
      'createdAt': _ts(2026, 4, 24, 16, 21),
      'isRead': false,
      'readAt': null,
    },
  };

  final reports = <String, Map<String, dynamic>>{
    'report_training_2026_04_26': {
      'id': 'report_training_2026_04_26',
      'reportName': 'Quarterly Response Training',
      'reportType': 'training',
      'managerId': 'manager_ravi_patel',
      'managerName': 'Ravi Patel',
      'dateTime': _ts(2026, 4, 26, 10, 0),
      'location': {
        'lat': 23.0395,
        'lng': 72.5315,
        'address': 'Ashram Road, Navrangpura, Ahmedabad, Gujarat 380009',
      },
      'questions': [
        {
          'question': 'Were all guards present for the briefing?',
          'description': 'Attendance was verified before drills started.',
        },
        {
          'question': 'Was evacuation protocol demonstrated?',
          'description': 'Two supervised drill runs were completed.',
        },
      ],
      'imageUrls': [
        'https://images.unsplash.com/photo-1517048676732-d65bc937f952?auto=format&fit=crop&w=1200&q=80',
      ],
      'createdAt': _ts(2026, 4, 26, 10, 5),
      'updatedAt': _ts(2026, 4, 26, 10, 35),
    },
    'report_night_visit_2026_04_24': {
      'id': 'report_night_visit_2026_04_24',
      'reportName': 'Night Shift Compliance Review',
      'reportType': 'night_visit',
      'managerId': 'manager_heena_shah',
      'managerName': 'Heena Shah',
      'dateTime': _ts(2026, 4, 24, 22, 15),
      'location': {
        'lat': 23.0115,
        'lng': 72.5108,
        'address': 'Pinnacle Business Park, Prahlad Nagar, Ahmedabad',
      },
      'questions': [
        {
          'question': 'Were entry logs updated on time?',
          'description': 'Night reception desk logs matched shift timeline.',
        },
        {
          'question': 'Were patrol checkpoints completed?',
          'description':
              'All checkpoints were acknowledged in the shift sheet.',
        },
      ],
      'imageUrls': [
        'https://images.unsplash.com/photo-1497366754035-f200968a6e72?auto=format&fit=crop&w=1200&q=80',
      ],
      'createdAt': _ts(2026, 4, 24, 22, 20),
      'updatedAt': _ts(2026, 4, 24, 22, 40),
    },
  };

  final fieldVisits = <String, Map<String, dynamic>>{
    'field_visit_2026_04_27_ravi': {
      'id': 'field_visit_2026_04_27_ravi',
      'managerId': 'manager_ravi_patel',
      'managerName': 'Ravi Patel',
      'phone': '+91 98765 11001',
      'profileImage': 'https://i.pravatar.cc/300?img=12',
      'siteName': 'Alpha One Mall Parking Bay',
      'description':
          'Reviewed parking access bottleneck and briefed night rotation staff.',
      'location': {
        'lat': 23.0273,
        'lng': 72.5069,
        'address': 'Alpha One Mall, Satellite, Ahmedabad',
      },
      'imageUrls': [
        'https://images.unsplash.com/photo-1517502884422-41eaead166d4?auto=format&fit=crop&w=1200&q=80',
      ],
      'dateTime': _ts(2026, 4, 27, 14, 20),
      'createdAt': _ts(2026, 4, 27, 14, 20),
    },
    'field_visit_2026_04_25_sneha': {
      'id': 'field_visit_2026_04_25_sneha',
      'managerId': 'manager_sneha_trivedi',
      'managerName': 'Sneha Trivedi',
      'phone': '+91 98765 11004',
      'profileImage': 'https://i.pravatar.cc/300?img=47',
      'siteName': 'Corporate Avenue Visitor Gate',
      'description':
          'Inspected visitor queue control and verified badge scanner downtime notes.',
      'location': {
        'lat': 22.2868,
        'lng': 70.7687,
        'address': 'Corporate Avenue, Kalawad Road, Rajkot',
      },
      'imageUrls': [
        'https://images.unsplash.com/photo-1520607162513-77705c0f0d4a?auto=format&fit=crop&w=1200&q=80',
      ],
      'dateTime': _ts(2026, 4, 25, 16, 5),
      'createdAt': _ts(2026, 4, 25, 16, 5),
    },
    'field_visit_2026_04_28_guardpulse_demo': {
      'id': 'field_visit_2026_04_28_guardpulse_demo',
      'managerId': 'manager_guardpulse_demo',
      'managerName': 'Manager Demo',
      'phone': '+91 98765 22001',
      'profileImage': 'https://i.pravatar.cc/300?img=23',
      'siteName': 'Logistics Hub Perimeter',
      'description':
          'Surprise perimeter review after truck queue escalation. Confirmed lighting coverage and updated the dispatch gate note register.',
      'location': {
        'lat': 21.0877,
        'lng': 72.8811,
        'address': 'Freight Terminal, Sachin, Surat',
      },
      'imageUrls': [
        'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=1200&q=80',
      ],
      'dateTime': _ts(2026, 4, 28, 13, 40),
      'createdAt': _ts(2026, 4, 28, 13, 40),
    },
  };

  final managerLiveLocations = <String, Map<String, dynamic>>{
    'manager_ravi_patel': {
      'managerId': 'manager_ravi_patel',
      'managerName': 'Ravi Patel',
      'lat': 23.0285,
      'lng': 72.5082,
      'lastUpdated': _ts(2026, 4, 28, 17, 35),
      'checkInLocation': {
        'lat': 23.0273,
        'lng': 72.5069,
        'address': 'Alpha One Mall, Satellite, Ahmedabad',
      },
      'branchImage':
          'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=1200&q=80',
      'helplineNumber': '+91 1800 123 4455',
      'whatsappNumber': '+91 98765 90001',
    },
    'manager_heena_shah': {
      'managerId': 'manager_heena_shah',
      'managerName': 'Heena Shah',
      'lat': 23.0122,
      'lng': 72.5121,
      'lastUpdated': _ts(2026, 4, 28, 17, 20),
      'checkInLocation': {
        'lat': 23.0115,
        'lng': 72.5108,
        'address': 'Pinnacle Business Park, Prahlad Nagar, Ahmedabad',
      },
      'branchImage':
          'https://images.unsplash.com/photo-1497366811353-6870744d04b2?auto=format&fit=crop&w=1200&q=80',
      'helplineNumber': '+91 1800 123 4455',
      'whatsappNumber': '+91 98765 90002',
    },
    'manager_sneha_trivedi': {
      'managerId': 'manager_sneha_trivedi',
      'managerName': 'Sneha Trivedi',
      'lat': 22.2853,
      'lng': 70.7705,
      'lastUpdated': _ts(2026, 4, 28, 16, 55),
      'checkInLocation': {
        'lat': 22.2868,
        'lng': 70.7687,
        'address': 'Corporate Avenue, Kalawad Road, Rajkot',
      },
      'branchImage':
          'https://images.unsplash.com/photo-1494526585095-c41746248156?auto=format&fit=crop&w=1200&q=80',
      'helplineNumber': '+91 1800 123 4455',
      'whatsappNumber': '+91 98765 90004',
    },
    'manager_guardpulse_demo': {
      'managerId': 'manager_guardpulse_demo',
      'managerName': 'Manager Demo',
      'lat': 23.0281,
      'lng': 72.5076,
      'lastUpdated': _ts(2026, 4, 28, 17, 42),
      'checkInLocation': {
        'lat': 23.0273,
        'lng': 72.5069,
        'address': 'Alpha One Mall, Satellite, Ahmedabad',
      },
      'branchImage':
          'https://images.unsplash.com/photo-1497366811353-6870744d04b2?auto=format&fit=crop&w=1200&q=80',
      'helplineNumber': '+91 1800 123 4455',
      'whatsappNumber': '+91 98765 22001',
    },
  };

  final managerLeaves = <String, Map<String, dynamic>>{
    'leave_guardpulse_demo_pending': {
      'managerId': 'manager_guardpulse_demo',
      'managerName': 'Manager Demo',
      'leaveType': 'Casual Leave',
      'fromDate': _ts(2026, 5, 3),
      'toDate': _ts(2026, 5, 4),
      'reason':
          'Requested personal leave for two days after scheduled site handover.',
      'status': 'Pending',
      'createdAt': _ts(2026, 4, 28, 18, 30),
      'updatedAt': _ts(2026, 4, 28, 18, 30),
    },
    'leave_guardpulse_demo_approved': {
      'managerId': 'manager_guardpulse_demo',
      'managerName': 'Manager Demo',
      'leaveType': 'Sick Leave',
      'fromDate': _ts(2026, 4, 10),
      'toDate': _ts(2026, 4, 11),
      'reason':
          'Recovered after medical rest and shared shift coverage before absence.',
      'status': 'Approved',
      'createdAt': _ts(2026, 4, 8, 9, 10),
      'updatedAt': _ts(2026, 4, 8, 17, 45),
    },
  };

  final batch = db.batch();

  debugPrint('Creating branches...');
  for (final entry in branches.entries) {
    batch.set(refs.branches.doc(entry.key), entry.value);
  }

  debugPrint('Creating clients...');
  for (final entry in clients.entries) {
    batch.set(refs.clients.doc(entry.key), entry.value);
  }

  debugPrint('Creating managers...');
  for (final entry in managers.entries) {
    batch.set(refs.managers.doc(entry.key), entry.value);
  }

  debugPrint('Creating sites...');
  for (final entry in sites.entries) {
    batch.set(refs.sites.doc(entry.key), entry.value);
  }

  debugPrint('Creating attendance records...');
  for (final entry in attendance.entries) {
    batch.set(refs.attendance.doc(entry.key), entry.value);
  }

  debugPrint('Creating site visits...');
  for (final entry in siteVisits.entries) {
    batch.set(refs.siteVisits.doc(entry.key), entry.value);
  }

  if (includeReports) {
    debugPrint('Creating reports...');
    for (final entry in reports.entries) {
      batch.set(refs.reports.doc(entry.key), entry.value);
    }
  }

  if (includeVisits) {
    debugPrint('Creating field visits...');
    for (final entry in fieldVisits.entries) {
      batch.set(refs.fieldVisits.doc(entry.key), entry.value);
    }
  }

  if (includeLiveTracking) {
    debugPrint('Creating manager live locations...');
    for (final entry in managerLiveLocations.entries) {
      batch.set(refs.managerLiveLocation.doc(entry.key), entry.value);
    }
  }

  debugPrint('Creating manager leave requests...');
  for (final entry in managerLeaves.entries) {
    batch.set(refs.managerLeaves.doc(entry.key), entry.value);
  }

  debugPrint('Creating notifications...');
  for (final entry in notifications.entries) {
    batch.set(refs.notifications.doc(entry.key), entry.value);
  }

  try {
    await batch.commit();
    debugPrint('Seeding completed');
  } catch (error) {
    debugPrint('Seeding failed: $error');
    rethrow;
  }
}

Future<void> _clearSeedCollections(GuardGreyCollectionRefs refs) async {
  await Future.wait([
    _deleteAllDocs(refs.notifications),
    _deleteAllDocs(refs.managerLeaves),
    _deleteAllDocs(refs.managerLiveLocation),
    _deleteAllDocs(refs.fieldVisits),
    _deleteAllDocs(refs.reports),
    _deleteAllDocs(refs.siteVisits),
    _deleteAllDocs(refs.attendance),
    _deleteAllDocs(refs.sites),
    _deleteAllDocs(refs.managers),
    _deleteAllDocs(refs.clients),
    _deleteAllDocs(refs.branches),
  ]);
}

Future<void> _deleteAllDocs(
  CollectionReference<Map<String, dynamic>> collection,
) async {
  final snapshot = await collection.get();
  if (snapshot.docs.isEmpty) {
    return;
  }

  final batch = collection.firestore.batch();
  for (final doc in snapshot.docs) {
    batch.delete(doc.reference);
  }
  await batch.commit();
}

Timestamp _ts(int year, int month, int day, [int hour = 0, int minute = 0]) {
  return Timestamp.fromDate(DateTime(year, month, day, hour, minute));
}
