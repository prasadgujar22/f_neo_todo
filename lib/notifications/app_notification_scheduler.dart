export 'notification_scheduler_stub.dart'
    if (dart.library.io) 'notification_scheduler_native.dart'
    if (dart.library.js_interop) 'notification_scheduler_web.dart';
