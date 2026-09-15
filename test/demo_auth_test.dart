import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:abu_zaria_cbt/main.dart';
import 'package:abu_zaria_cbt/app/routes/app_routes.dart';
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
}
