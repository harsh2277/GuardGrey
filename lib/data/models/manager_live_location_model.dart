import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:guardgrey/data/models/app_location.dart';

class ManagerLiveLocationModel {
  const ManagerLiveLocationModel({
    required this.managerId,
    required this.managerName,
    required this.lat,
    required this.lng,
    required this.lastUpdated,
    required this.checkInLocation,
    required this.branchImage,
    required this.helplineNumber,
    required this.whatsappNumber,
  });

  final String managerId;
  final String managerName;
  final double lat;
  final double lng;
  final DateTime lastUpdated;
  final AppLocation checkInLocation;
  final String branchImage;
  final String helplineNumber;
  final String whatsappNumber;

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'managerId': managerId,
      'managerName': managerName,
      'lat': lat,
      'lng': lng,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'checkInLocation': checkInLocation.toMap(),
      'branchImage': branchImage,
      'helplineNumber': helplineNumber,
      'whatsappNumber': whatsappNumber,
    };
  }
}
