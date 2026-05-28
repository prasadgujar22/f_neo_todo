enum NotificationCapability { nativeScheduled, webWhileOpen, unsupported }

enum NotificationPermissionState { unknown, granted, denied, unsupported }

class TodoNotificationRequest {
  const TodoNotificationRequest({
    required this.todoId,
    required this.title,
    required this.body,
    required this.dueDate,
  });

  final String todoId;
  final String title;
  final String body;
  final DateTime dueDate;

  String get token => '$todoId:${dueDate.toIso8601String()}';
  int get notificationId => stableNotificationId(todoId);
}

int stableNotificationId(String value) {
  var hash = 0x811c9dc5;
  for (final codeUnit in value.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash == 0 ? 1 : hash;
}
