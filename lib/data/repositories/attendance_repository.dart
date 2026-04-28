import 'package:guardgrey/data/models/attendance_record.dart';
import 'package:guardgrey/data/repositories/guard_grey_repository.dart';

class AttendanceRepository {
  AttendanceRepository._();

  static final AttendanceRepository instance = AttendanceRepository._();

  final GuardGreyRepository _repository = GuardGreyRepository.instance;

  Stream<List<AttendanceRecord>> watchAttendance() =>
      _repository.watchAttendance();
}
