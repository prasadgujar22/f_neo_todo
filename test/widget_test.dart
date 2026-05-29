import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:neo_todo_flutter/main.dart';

void main() {
  Future<void> pumpDesktopApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const NeoTodoApp());
  }

  testWidgets('loads Neo To-Do shell', (tester) async {
    await pumpDesktopApp(tester);

    expect(find.text('Neo To-Do'), findsOneWidget);
    expect(find.text('Local mode'), findsOneWidget);
    expect(find.text('Due notifications off'), findsOneWidget);
    expect(find.text('Local'), findsOneWidget);
  });

  testWidgets('adds a task from the composer', (tester) async {
    await pumpDesktopApp(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'What needs to be done?'),
      'Draft Flutter notification service',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pump();

    expect(find.text('Draft Flutter notification service'), findsOneWidget);
  });

  Future<void> addTask(WidgetTester tester, String text) async {
    await tester.enterText(
      find.widgetWithText(TextField, 'What needs to be done?'),
      text,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pump();
  }

  testWidgets('edits a task inline', (tester) async {
    await pumpDesktopApp(tester);
    await addTask(tester, 'Port todo domain model to Dart');

    await tester.tap(find.byIcon(Icons.edit_outlined).first);
    await tester.pump();

    await tester.enterText(
      find.byKey(const ValueKey('todo-edit-field')),
      'Port todo model with tests',
    );
    await tester.tap(find.byIcon(Icons.check).first);
    await tester.pump();

    expect(find.text('Port todo model with tests'), findsOneWidget);
    expect(find.text('Port todo domain model to Dart'), findsNothing);
  });

  testWidgets('toggles a task complete', (tester) async {
    await pumpDesktopApp(tester);
    await addTask(tester, 'Wire native notification scheduler');

    await tester.tap(find.byIcon(Icons.radio_button_unchecked).first);
    await tester.pump();

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('creates a group and shows it in the composer', (tester) async {
    await pumpDesktopApp(tester);

    await tester.enterText(find.widgetWithText(TextField, 'New group'), 'Work');
    await tester.tap(find.widgetWithText(OutlinedButton, 'Create'));
    await tester.pump();

    expect(find.text('Work'), findsWidgets);
    expect(find.byIcon(Icons.folder_outlined), findsWidgets);
  });
}
