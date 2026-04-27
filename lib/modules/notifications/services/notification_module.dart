import 'notification_preferences_service.dart';
import 'notification_repository.dart';
import 'notification_trigger_service.dart';
import 'push_notification_service.dart';

class NotificationModule {
  NotificationModule._();

  static final NotificationRepository repository = NotificationRepository();
  static final NotificationPreferencesService preferencesService =
      NotificationPreferencesService();
  static final NotificationTriggerService triggerService =
      NotificationTriggerService(repository);
  static final PushNotificationService pushNotificationService =
      PushNotificationService(
        repository: repository,
        preferencesService: preferencesService,
      );

  static Future<void> initialize() async {
    await preferencesService.initialize();
    await pushNotificationService.initialize();
  }
}
