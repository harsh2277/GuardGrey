class AttendanceRecord {
  final String id;
  final String managerId;
  final String name;
  final String siteId;
  final String siteName;
  final String status;
  final String date;
  final String checkIn;
  final String checkOut;

  const AttendanceRecord({
    required this.id,
    required this.managerId,
    required this.name,
    required this.siteId,
    required this.siteName,
    required this.status,
    required this.date,
    required this.checkIn,
    required this.checkOut,
  });
}
