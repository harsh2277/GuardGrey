import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:guardgrey/data/models/app_location.dart';
import 'package:guardgrey/data/models/report_question.dart';

class ReportModel {
  const ReportModel({
    required this.id,
    required this.reportName,
    required this.reportType,
    required this.managerId,
    required this.managerName,
    required this.dateTime,
    required this.location,
    required this.questions,
    required this.imageUrls,
    this.isReadOnly = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String reportName;
  final String reportType;
  final String managerId;
  final String managerName;
  final DateTime dateTime;
  final AppLocation location;
  final List<ReportQuestion> questions;
  final List<String> imageUrls;
  final bool isReadOnly;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'id': id,
      'reportName': reportName,
      'reportType': reportType,
      'managerId': managerId,
      'managerName': managerName,
      'dateTime': Timestamp.fromDate(dateTime),
      'location': location.toMap(),
      'questions': questions
          .map((item) => item.toMap())
          .toList(growable: false),
      'imageUrls': imageUrls,
      'isReadOnly': isReadOnly,
    };
  }

  ReportModel copyWith({
    String? id,
    String? reportName,
    String? reportType,
    String? managerId,
    String? managerName,
    DateTime? dateTime,
    AppLocation? location,
    List<ReportQuestion>? questions,
    List<String>? imageUrls,
    bool? isReadOnly,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReportModel(
      id: id ?? this.id,
      reportName: reportName ?? this.reportName,
      reportType: reportType ?? this.reportType,
      managerId: managerId ?? this.managerId,
      managerName: managerName ?? this.managerName,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      questions: questions ?? this.questions,
      imageUrls: imageUrls ?? this.imageUrls,
      isReadOnly: isReadOnly ?? this.isReadOnly,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
