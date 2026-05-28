import 'notification_models.dart';

class AppNotificationScheduler {
  NotificationCapability get capability => NotificationCapability.unsupported;
  NotificationPermissionState get permissionState =>
      NotificationPermissionState.unsupported;

  Future<void> initialize() async {}

  Future<NotificationPermissionState> requestPermission() async {
    return NotificationPermissionState.unsupported;
  }

  Future<void> schedule(TodoNotificationRequest request) async {}

  Future<void> cancel(String todoId) async {}

  Future<void> reconcile(Iterable<TodoNotificationRequest> requests) async {}
}
