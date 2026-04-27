class AttendanceRecord {
  final String id;
  final String name;
  final String status;
  final String date;
  final String checkIn;
  final String checkOut;

  const AttendanceRecord({
    required this.id,
    required this.name,
    required this.status,
    required this.date,
    required this.checkIn,
    required this.checkOut,
  });
}
