import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

// The native HTML5 datetime-local input always anchors to the input
// element's screen position. Because the input is a hidden 1×1 px element,
// the picker always appears in the wrong corner. Returning false routes
// every browser to the in-app CupertinoDatePicker dialog instead.
bool get isNativeWebDueDatePickerAvailable => false;

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
