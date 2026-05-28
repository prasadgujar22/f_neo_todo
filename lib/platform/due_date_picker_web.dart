import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

bool get isNativeWebDueDatePickerAvailable {
  final userAgent = web.window.navigator.userAgent;
  final isSafari =
      userAgent.contains('Safari') &&
      !userAgent.contains('Chrome') &&
      !userAgent.contains('Chromium') &&
      !userAgent.contains('CriOS') &&
      !userAgent.contains('FxiOS') &&
      !userAgent.contains('Edg');
  final isMobileAppleSafari =
      userAgent.contains('iPhone') ||
      userAgent.contains('iPad') ||
      userAgent.contains('iPod') ||
      (userAgent.contains('Macintosh') &&
          web.window.navigator.maxTouchPoints > 1);
  if (isSafari && !isMobileAppleSafari) return false;

  final input = web.document.createElement('input') as web.HTMLInputElement
    ..type = 'datetime-local';
  final supportsDateTimeLocal = input.type == 'datetime-local';
  if (!supportsDateTimeLocal) return false;

  final hasPickerApi = input.hasProperty('showPicker'.toJS).toDart;
  final isTouchDevice = web.window.navigator.maxTouchPoints > 0;
  return hasPickerApi || isTouchDevice;
}

Future<DateTime?> chooseNativeWebDueDate({
  required DateTime initialDate,
  required DateTime minimumDate,
  required DateTime maximumDate,
}) async {
  final body = web.document.body;
  if (body == null) return null;

  final input = web.document.createElement('input') as web.HTMLInputElement
    ..type = 'datetime-local'
    ..value = _formatInputDateTime(initialDate)
    ..min = _formatInputDateTime(minimumDate)
    ..max = _formatInputDateTime(maximumDate);

  input.style
    ..position = 'fixed'
    ..left = '0'
    ..bottom = '0'
    ..width = '1px'
    ..height = '1px'
    ..opacity = '0'
    ..pointerEvents = 'none';

  body.appendChild(input);
  final completer = Completer<DateTime?>();
  var latestDate = _parseInputDateTime(input.value);

  void finish(DateTime? value) {
    if (completer.isCompleted) return;
    input.remove();
    completer.complete(value);
  }

  input.addEventListener(
    'input',
    ((web.Event _) {
      latestDate = _parseInputDateTime(input.value);
    }).toJS,
  );
  input.addEventListener(
    'change',
    ((web.Event _) {
      latestDate = _parseInputDateTime(input.value);
    }).toJS,
  );
  input.addEventListener(
    'blur',
    ((web.Event _) {
      Timer(const Duration(milliseconds: 120), () => finish(latestDate));
    }).toJS,
  );
  input.addEventListener('cancel', ((web.Event _) => finish(null)).toJS);
  input.addEventListener(
    'keydown',
    ((web.KeyboardEvent event) {
      if (event.key == 'Enter') finish(_parseInputDateTime(input.value));
      if (event.key == 'Escape') finish(null);
    }).toJS,
  );

  input.focus();
  if (input.hasProperty('showPicker'.toJS).toDart) {
    input.callMethod('showPicker'.toJS);
  } else {
    input.click();
  }

  return completer.future.timeout(
    const Duration(minutes: 2),
    onTimeout: () {
      input.remove();
      return null;
    },
  );
}

String _formatInputDateTime(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}T'
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}

DateTime? _parseInputDateTime(String value) {
  if (value.isEmpty) return null;
  return DateTime.tryParse(value);
}
