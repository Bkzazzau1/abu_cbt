import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:abu_zaria_cbt/main.dart';
import 'package:abu_zaria_cbt/app/routes/app_routes.dart';
import 'package:abu_zaria_cbt/data/services/invigilator_session.dart';
import 'package:abu_zaria_cbt/modules/auth/demo_auth.dart';
import 'package:abu_zaria_cbt/modules/portal/controller/center_exam_portal_controller.dart';

void main() {
  setUp(() {
    DemoAuth.instance.account = null;
    DemoAuth.instance.student = null;
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() => Get.reset());
  test('credentials cannot be used under another role', () async {
    final auth = DemoAuth.instance;
    expect(
      await auth.signIn('Administrator', 'ABU/CSC/001', 'cbt001'),
      isFalse,
    );
    expect(
      await auth.signIn('Invigilator', 'admin.abu', 'AbuAdmin123!'),
      isFalse,
    );
    expect(await auth.signIn('Student', 'ABU/CSC/001', 'wrong'), isFalse);
    expect(auth.account, isNull);
    expect(
      await auth.signIn('Invigilator', 'invigilator.b', 'invB123'),
      isTrue,
    );
    expect(auth.account!.name, 'Musa Ibrahim');
    expect(auth.student, isNull);
  });
  test(
    'different students receive their own identity and course sessions',
    () async {
      final auth = DemoAuth.instance;
      expect(auth.beginStudentSession('ABU/CSC/001'), isTrue);
      expect(auth.student!.candidate.fullName, 'Zainab Musa');
      expect(auth.beginStudentSession('ABU/MTH/004'), isTrue);
      expect(auth.student!.candidate.registrationNumber, 'ABU/MTH/004');
      expect(auth.student!.candidate.fullName, 'Ibrahim Bashir Yahaya');
      expect(auth.student!.exams, isNotEmpty);
    },
  );
  testWidgets(
    'login is required, student cannot open staff routes, logout clears session',
    (tester) async {
      await tester.pumpWidget(const CenterExamApp());
      await tester.pumpAndSettle();
      Get.toNamed(Routes.demo);
      await tester.pumpAndSettle();
      expect(Get.currentRoute, Routes.centerLogin);
      await tester.runAsync(
        () =>
            Future.value(DemoAuth.instance.beginStudentSession('ABU/MTH/004')),
      );
      await DemoAuth.instance.openWorkspace();
      await tester.pumpAndSettle();
      expect(find.text('Ibrahim Bashir Yahaya'), findsWidgets);
      expect(find.text('Zainab Musa'), findsNothing);
      Get.toNamed(Routes.invigilatorDashboard);
      await tester.pumpAndSettle();
      expect(Get.currentRoute, Routes.centerPortal);
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(DemoAuth.instance.account, isNull);
      expect(DemoAuth.instance.student, isNull);
      expect(Get.isRegistered<CenterExamPortalController>(), isFalse);
      expect(Get.currentRoute, Routes.centerLogin);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'invigilator sign-in opens the real invigilator dashboard, not the '
    'shared admin/invigilator demo workspace',
    (tester) async {
      // This is a Windows-desktop-only app; the default test surface
      // (≈800x600, phone-sized) is narrower than any window a real user
      // would actually run it at, and the dashboard's AppBar overflows
      // there without reflecting a real bug — a live check at 1280x720+
      // showed no overflow. Match a realistic desktop window instead.
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const CenterExamApp());
      await tester.pumpAndSettle();

      expect(
        await DemoAuth.instance.signIn(
          'Invigilator',
          'chief.invigilator',
          'chief123',
        ),
        isTrue,
      );
      await DemoAuth.instance.openWorkspace();
      await tester.pumpAndSettle();

      expect(Get.currentRoute, Routes.invigilatorDashboard);
      expect(InvigilatorSession.currentName, 'Chief Invigilator');
      expect(tester.takeException(), isNull);
    },
  );
}
