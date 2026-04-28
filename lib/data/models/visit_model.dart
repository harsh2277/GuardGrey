class VisitModel {
  final String id;
  final String siteId;
  final String managerId;
  final String siteName;
  final String managerName;
  final String date;
  final String day;
  final String time;
  final String notes;
  final String status;

  const VisitModel({
    required this.id,
    required this.siteId,
    required this.managerId,
    required this.siteName,
    required this.managerName,
    required this.date,
    required this.day,
    required this.time,
    this.notes = '',
    required this.status,
  });
}
