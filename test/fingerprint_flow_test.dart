import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:abu_zaria_cbt/main.dart';
import 'package:abu_zaria_cbt/modules/auth/demo_auth.dart';
import 'package:abu_zaria_cbt/modules/auth/fingerprint_reader.dart';

void main() {
  setUp(() {
    DemoAuth.instance.account = null;
    DemoAuth.instance.student = null;
  });

  tearDown(() => Get.reset());

  test('student login uses university registration record only', () async {
    final auth = DemoAuth.instance;

    expect(await auth.signIn('Student', 'ABU/CSC/001', 'cbt001'), isFalse);
    expect(auth.beginStudentSession('UNKNOWN'), isFalse);
    expect(auth.beginStudentSession('ABU/CSC/001'), isTrue);
    expect(auth.account?.role, 'Student');
    expect(auth.student?.candidate.registrationNumber, 'ABU/CSC/001');
  });

  testWidgets('registration number login opens examination dashboard', (
    tester,
  ) async {
    await tester.pumpWidget(const CenterExamApp());
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Password'), findsNothing);

    await tester.enterText(find.byType(TextFormField), 'UNKNOWN');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Registration number not found.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'ABU/CSC/001');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('STUDENT EXAMINATION DASHBOARD'), findsOneWidget);
    expect(find.text('CURRENT EXAMINATION'), findsOneWidget);
    expect(find.text('START EXAMINATION'), findsOneWidget);
    expect(find.textContaining('fingerprint', findRichText: true), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('fingerprint reader exposes match, mismatch and unavailable outcomes', () async {
    final reader = DemoFingerprintReader();

    reader.outcome = FingerprintResult.matched;
    expect(await reader.verify('ABU/CSC/001'), FingerprintResult.matched);

    reader.outcome = FingerprintResult.notMatched;
    expect(await reader.verify('ABU/CSC/001'), FingerprintResult.notMatched);

    reader.outcome = FingerprintResult.unavailable;
    expect(await reader.verify('ABU/CSC/001'), FingerprintResult.unavailable);
  });
}
