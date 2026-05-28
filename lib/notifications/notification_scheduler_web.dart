import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'notification_models.dart';

class AppNotificationScheduler {
  final Map<String, Timer> _timers = <String, Timer>{};
  NotificationPermissionState _permissionState =
      NotificationPermissionState.unknown;

  NotificationCapability get capability => NotificationCapability.webWhileOpen;
  NotificationPermissionState get permissionState => _permissionState;

  Future<void> initialize() async {
    if (!_notificationSupported) {
      _permissionState = NotificationPermissionState.unsupported;
      return;
    }
    _permissionState = switch (web.Notification.permission) {
      'granted' => NotificationPermissionState.granted,
      'denied' => NotificationPermissionState.denied,
      _ => NotificationPermissionState.unknown,
    };
  }

  Future<NotificationPermissionState> requestPermission() async {
    await initialize();
    if (!_notificationSupported) {
      _permissionState = NotificationPermissionState.unsupported;
      return _permissionState;
    }

    final permission = await web.Notification.requestPermission().toDart;
    _permissionState = switch (permission.toDart) {
      'granted' => NotificationPermissionState.granted,
      'denied' => NotificationPermissionState.denied,
      _ => NotificationPermissionState.unknown,
    };
    return _permissionState;
  }

  Future<void> schedule(TodoNotificationRequest request) async {
    await initialize();
    await cancel(request.todoId);

    if (_permissionState != NotificationPermissionState.granted) return;
    final delay = request.dueDate.difference(DateTime.now());
    if (delay.isNegative) return;

    _timers[request.todoId] = Timer(delay, () {
      web.Notification(
        request.title,
        web.NotificationOptions(
          body: request.body,
          tag: 'neo-todo-due-${request.todoId}',
          renotify: true,
        ),
      );
      _timers.remove(request.todoId);
    });
  }

  Future<void> cancel(String todoId) async {
    _timers.remove(todoId)?.cancel();
  }

  Future<void> reconcile(Iterable<TodoNotificationRequest> requests) async {
    await initialize();
    final nextRequests = requests.toList();
    final nextIds = nextRequests.map((request) => request.todoId).toSet();

    for (final oldId in _timers.keys.toSet().difference(nextIds)) {
      await cancel(oldId);
    }
    for (final request in nextRequests) {
      await schedule(request);
    }
  }

  bool get _notificationSupported {
    return web.window.hasProperty('Notification'.toJS).toDart;
  }
}
