import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:guardgrey/data/models/app_location.dart';

class FieldVisitModel {
  const FieldVisitModel({
    required this.id,
    required this.managerId,
    required this.managerName,
    required this.clientEmail,
    required this.phone,
    required this.profileImage,
    required this.visitType,
    required this.siteName,
    required this.notes,
    required this.status,
    required this.location,
    required this.imageUrls,
    required this.dateTime,
    this.createdAt,
  });

  final String id;
  final String managerId;
  final String managerName;
  final String clientEmail;
  final String phone;
  final String profileImage;
  final String visitType;
  final String siteName;
  final String notes;
  final String status;
  final AppLocation location;
  final List<String> imageUrls;
  final DateTime dateTime;
  final DateTime? createdAt;

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'id': id,
      'managerId': managerId,
      'managerName': managerName,
      'clientEmail': clientEmail,
      'phone': phone,
      'profileImage': profileImage,
      'visitType': visitType,
      'siteName': siteName,
      'notes': notes,
      'description': notes,
      'status': status,
      'location': location.toMap(),
      'imageUrls': imageUrls,
      'dateTime': Timestamp.fromDate(dateTime),
    };
  }
}
