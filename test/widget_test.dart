import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:abu_zaria_cbt/main.dart';
import 'package:abu_zaria_cbt/modules/demo/demo_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    DemoStore.instance.role = 'Administrator';
  });
  tearDown(() => Get.reset());
  Future<void> boot(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const CenterExamApp());
    await tester.pumpAndSettle();
  }

  testWidgets('desktop navigation renders all administration screens', (
    tester,
  ) async {
    await boot(tester, const Size(1440, 1000));
    expect(find.text('Examination overview'), findsOneWidget);
    for (final page in [
      'Examinations',
      'Question bank',
      'Candidates',
      'Hall monitoring',
      'Attendance',
      'Results',
      'Incidents',
      'Settings',
      'Help & guidance',
    ]) {
      await tester.tap(find.widgetWithText(ListTile, page));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: page);
    }
  });
  testWidgets('mobile navigation and publication across roles', (tester) async {
    await boot(tester, const Size(390, 844));
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Open navigation'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Results'));
    await tester.pumpAndSettle();
    if (!DemoStore.instance.showResults) {
      await tester.tap(find.text('Publish demo results'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byTooltip('Switch demo role'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Student').last);
    await tester.pumpAndSettle();
    expect(find.text('Practice examination'), findsOneWidget);
    await tester.tap(find.byTooltip('Open navigation'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'My results'));
    await tester.pumpAndSettle();
    expect(find.text('82 / 100'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('exam form validates and draft can be published', (tester) async {
    await boot(tester, const Size(1440, 1000));
    await tester.tap(find.text('Create examination'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create draft'));
    await tester.pumpAndSettle();
    expect(find.text('This field is required'), findsNWidgets(2));
    await tester.enterText(find.byType(TextFormField).at(0), 'TEST 101');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'UI workflow test',
    );
    await tester.tap(find.text('Create draft'));
    await tester.pumpAndSettle();
    expect(DemoStore.instance.exams.last.status, 'Draft');
    await tester.enterText(find.byType(TextField).first, 'TEST 101');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Manage TEST 101'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Publish schedule'));
    await tester.pumpAndSettle();
    expect(DemoStore.instance.exams.last.status, 'Scheduled');
    expect(tester.takeException(), isNull);
    DemoStore.instance.exams.removeLast();
  });
  testWidgets('check-in and incident actions update shared state', (
    tester,
  ) async {
    await boot(tester, const Size(1440, 1000));
    final candidate = DemoStore.instance.candidates[1];
    candidate.checkedIn = false;
    await tester.tap(find.widgetWithText(ListTile, 'Attendance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check in').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verify & check in'));
    await tester.pumpAndSettle();
    expect(candidate.checkedIn, isTrue);
    await tester.tap(find.widgetWithText(ListTile, 'Incidents'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resolve').first);
    await tester.pumpAndSettle();
    expect(DemoStore.instance.incidents.first.resolved, isTrue);
    expect(tester.takeException(), isNull);
  });
}
