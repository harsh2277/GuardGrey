import 'package:guardgrey/data/models/app_notification.dart';
import 'package:guardgrey/data/repositories/notification_repository.dart';
import 'package:guardgrey/features/auth/models/app_role.dart';

class NotificationTriggerService {
  NotificationTriggerService(this._repository);

  final NotificationRepository _repository;

  Future<void> notifyManagerCheckedIn({
    required String managerName,
    String? siteName,
  }) {
    final siteLabel = siteName == null || siteName.trim().isEmpty
        ? ''
        : ' at $siteName';
    return _repository.createNotification(
      title: 'Manager Checked In',
      message: '$managerName checked in$siteLabel.',
      type: NotificationType.attendance,
      recipientKeys: <String>[
        NotificationRepository.roleRecipientKey(AppRole.admin),
      ],
    );
  }

  Future<void> notifyManagerCheckedOut({
    required String managerName,
    String? siteName,
  }) {
    final siteLabel = siteName == null || siteName.trim().isEmpty
        ? ''
        : ' from $siteName';
    return _repository.createNotification(
      title: 'Manager Checked Out',
      message: '$managerName checked out$siteLabel.',
      type: NotificationType.attendance,
      recipientKeys: <String>[
        NotificationRepository.roleRecipientKey(AppRole.admin),
      ],
    );
  }

  Future<void> notifySiteVisitSubmitted({
    required String managerName,
    required String siteName,
  }) {
    return _repository.createNotification(
      title: 'Site Visit Submitted',
      message: '$managerName submitted a site visit for $siteName.',
      type: NotificationType.visit,
      recipientKeys: <String>[
        NotificationRepository.roleRecipientKey(AppRole.admin),
      ],
    );
  }

  Future<void> notifyAttendanceUpdated({
    required String managerName,
    required String status,
  }) {
    return _repository.createNotification(
      title: 'Attendance Updated',
      message: '$managerName attendance was updated to $status.',
      type: NotificationType.attendance,
      recipientKeys: <String>[
        NotificationRepository.roleRecipientKey(AppRole.admin),
      ],
    );
  }
}
