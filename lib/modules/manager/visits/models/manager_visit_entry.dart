import 'package:cloud_firestore/cloud_firestore.dart';

class ManagerVisitQuestion {
  const ManagerVisitQuestion({
    required this.question,
    required this.answer,
    this.note = '',
  });

  final String question;
  final bool? answer;
  final String note;

  String get answerLabel {
    if (answer == true) {
      return 'Yes';
    }
    if (answer == false) {
      return 'No';
    }
    return 'Pending';
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'question': question,
      'answer': answer,
      'note': note,
    };
  }

  static ManagerVisitQuestion fromMap(Object? value) {
    if (value is Map) {
      final map = value.map(
        (key, mapValue) => MapEntry(key.toString(), mapValue),
      );
      return ManagerVisitQuestion(
        question: (map['question'] as String? ?? '').trim(),
        answer: map['answer'] as bool?,
        note: (map['note'] as String? ?? '').trim(),
      );
    }
    return ManagerVisitQuestion(question: '$value'.trim(), answer: true);
  }
}

class ManagerVisitEntry {
  const ManagerVisitEntry({
    required this.id,
    required this.siteId,
    required this.siteName,
    required this.managerId,
    required this.managerName,
    required this.visitType,
    required this.scheduledAt,
    required this.status,
    required this.notes,
    required this.imageUrls,
    this.imageStoragePaths = const <String>[],
    required this.questions,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String siteId;
  final String siteName;
  final String managerId;
  final String managerName;
  final String visitType;
  final DateTime scheduledAt;
  final String status;
  final String notes;
  final List<String> imageUrls;
  final List<String> imageStoragePaths;
  final List<ManagerVisitQuestion> questions;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  bool get canEditToday {
    final now = DateTime.now();
    return scheduledAt.year == now.year &&
        scheduledAt.month == now.month &&
        scheduledAt.day == now.day;
  }

  ManagerVisitEntry copyWith({
    String? id,
    String? siteId,
    String? siteName,
    String? managerId,
    String? managerName,
    String? visitType,
    DateTime? scheduledAt,
    String? status,
    String? notes,
    List<String>? imageUrls,
    List<String>? imageStoragePaths,
    List<ManagerVisitQuestion>? questions,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return ManagerVisitEntry(
      id: id ?? this.id,
      siteId: siteId ?? this.siteId,
      siteName: siteName ?? this.siteName,
      managerId: managerId ?? this.managerId,
      managerName: managerName ?? this.managerName,
      visitType: visitType ?? this.visitType,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      imageUrls: imageUrls ?? this.imageUrls,
      imageStoragePaths: imageStoragePaths ?? this.imageStoragePaths,
      questions: questions ?? this.questions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    final weekday = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ][scheduledAt.weekday - 1];
    final hour = scheduledAt.hour == 0
        ? 12
        : scheduledAt.hour > 12
        ? scheduledAt.hour - 12
        : scheduledAt.hour;
    final period = scheduledAt.hour >= 12 ? 'PM' : 'AM';
    final timeLabel =
        '${hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')} $period';

    return <String, dynamic>{
      'siteId': siteId,
      'siteName': siteName,
      'managerId': managerId,
      'managerName': managerName,
      'visitType': visitType,
      'date': Timestamp.fromDate(scheduledAt),
      'day': weekday,
      'timeLabel': timeLabel,
      'status': status,
      'notes': notes,
      'imageUrls': imageUrls,
      'imageStoragePaths': imageStoragePaths,
      'questions': questions.map((question) => question.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (createdAt == null) 'createdAt': FieldValue.serverTimestamp(),
      if (deletedAt != null) 'deletedAt': Timestamp.fromDate(deletedAt!),
    };
  }

  static ManagerVisitEntry fromMap(String id, Map<String, dynamic> data) {
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

    List<String> toStringList(Object? value) {
      if (value is Iterable) {
        return value
            .map((item) => '$item'.trim())
            .where((item) => item.isNotEmpty)
            .toList(growable: false);
      }
      return const <String>[];
    }

    List<ManagerVisitQuestion> toQuestionList(
      Object? value,
      List<String> checklist,
    ) {
      if (value is Iterable) {
        return value
            .map(ManagerVisitQuestion.fromMap)
            .where((item) => item.question.isNotEmpty)
            .toList(growable: false);
      }
      return checklist
          .map((item) => ManagerVisitQuestion(question: item, answer: true))
          .toList(growable: false);
    }

    final legacyChecklist = toStringList(data['checklist']);

    return ManagerVisitEntry(
      id: id,
      siteId: (data['siteId'] as String? ?? '').trim(),
      siteName: (data['siteName'] as String? ?? '').trim(),
      managerId: (data['managerId'] as String? ?? '').trim(),
      managerName: (data['managerName'] as String? ?? '').trim(),
      visitType: (data['visitType'] as String? ?? 'Site Visit').trim(),
      scheduledAt: toDateTime(data['date']) ?? DateTime.now(),
      status: (data['status'] as String? ?? 'Pending').trim(),
      notes: (data['notes'] as String? ?? '').trim(),
      imageUrls: toStringList(data['imageUrls']),
      imageStoragePaths: toStringList(data['imageStoragePaths']),
      questions: toQuestionList(data['questions'], legacyChecklist),
      createdAt: toDateTime(data['createdAt']),
      updatedAt: toDateTime(data['updatedAt']),
      deletedAt: toDateTime(data['deletedAt']),
    );
  }
}
