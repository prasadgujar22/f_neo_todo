import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'notification_models.dart';

class AppNotificationScheduler {
  AppNotificationScheduler() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final Set<String> _scheduledTodoIds = <String>{};
  NotificationPermissionState _permissionState =
      NotificationPermissionState.unknown;
  bool _initialized = false;

  NotificationCapability get capability =>
      NotificationCapability.nativeScheduled;
  NotificationPermissionState get permissionState => _permissionState;

  Future<void> initialize() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    await _setLocalTimezone();

    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initializationSettings = InitializationSettings(
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: LinuxInitializationSettings(defaultActionName: 'Open Neo To-Do'),
      windows: WindowsInitializationSettings(
        appName: 'Neo To-Do',
        appUserModelId: 'app.neotodo.neoTodoFlutter',
        guid: '0f9267e5-0f37-4a1f-8f87-98b65b9e93cc',
      ),
    );

    await _plugin.initialize(settings: initializationSettings);
    _initialized = true;
  }

  Future<NotificationPermissionState> requestPermission() async {
    await initialize();

    if (defaultTargetPlatform == TargetPlatform.macOS) {
      final implementation = _plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >();
      final granted = await implementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      _permissionState = granted == true
          ? NotificationPermissionState.granted
          : NotificationPermissionState.denied;
      return _permissionState;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final implementation = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final granted = await implementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      _permissionState = granted == true
          ? NotificationPermissionState.granted
          : NotificationPermissionState.denied;
      return _permissionState;
    }

    _permissionState = NotificationPermissionState.granted;
    return _permissionState;
  }

  Future<void> schedule(TodoNotificationRequest request) async {
    await initialize();
    if (_permissionState != NotificationPermissionState.granted) return;
    if (!request.dueDate.isAfter(DateTime.now())) return;

    await cancel(request.todoId);

    await _plugin.zonedSchedule(
      id: request.notificationId,
      title: request.title,
      body: request.body,
      scheduledDate: tz.TZDateTime.from(request.dueDate, tz.local),
      notificationDetails: const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: request.token,
    );
    _scheduledTodoIds.add(request.todoId);
  }

  Future<void> cancel(String todoId) async {
    await initialize();
    await _plugin.cancel(id: stableNotificationId(todoId));
    _scheduledTodoIds.remove(todoId);
  }

  Future<void> reconcile(Iterable<TodoNotificationRequest> requests) async {
    await initialize();
    final nextRequests = requests.toList();
    final nextIds = nextRequests.map((request) => request.todoId).toSet();
    for (final oldId in _scheduledTodoIds.difference(nextIds).toList()) {
      await cancel(oldId);
    }
    for (final request in nextRequests) {
      await schedule(request);
    }
  }

  Future<void> _setLocalTimezone() async {
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.local);
    }
  }
}
