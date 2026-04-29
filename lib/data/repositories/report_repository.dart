import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:guardgrey/data/models/app_location.dart';
import 'package:guardgrey/data/models/report_model.dart';
import 'package:guardgrey/data/models/report_question.dart';
import 'package:guardgrey/data/repositories/firestore_repository_utils.dart';
import 'package:guardgrey/data/sources/firebase/guard_grey_firestore_seed_source.dart';

class ReportRepository {
  ReportRepository._({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static final ReportRepository instance = ReportRepository._();

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection(GuardGreyFirestoreSchema.reports);

  Stream<List<ReportModel>> watchReports() {
    return _reports
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _fromMap(doc.id, doc.data()))
              .toList(growable: false),
        );
  }

  Stream<ReportModel?> watchReport(String id) {
    return _reports.doc(id).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      return _fromMap(
        snapshot.id,
        snapshot.data() ?? const <String, dynamic>{},
      );
    });
  }

  Future<void> saveReport(ReportModel report) async {
    final docRef = _reports.doc(report.id);
    final previous = await docRef.get();
    await docRef.set({
      ...report.toFirestore(),
      if (!previous.exists) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteReport(String id) => _reports.doc(id).delete();

  ReportModel _fromMap(String id, Map<String, dynamic> data) {
    final questions = (data['questions'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map>()
        .map(
          (item) => ReportQuestion.fromMap(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList(growable: false);
    return ReportModel(
      id: id,
      reportName: (data['reportName'] as String? ?? '').trim(),
      reportType: (data['reportType'] as String? ?? '').trim(),
      managerId: (data['managerId'] as String? ?? '').trim(),
      managerName: (data['managerName'] as String? ?? '').trim(),
      dateTime: toDateTime(data['dateTime']) ?? DateTime.now(),
      location: AppLocation.fromMap(mapValue(data['location'])),
      questions: questions,
      imageUrls: stringList(data['imageUrls']),
      createdAt: toDateTime(data['createdAt']),
      updatedAt: toDateTime(data['updatedAt']),
    );
  }
}
