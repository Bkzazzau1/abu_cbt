import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:abu_zaria_cbt/main.dart';
import 'package:abu_zaria_cbt/modules/auth/demo_auth.dart';
import 'package:abu_zaria_cbt/modules/auth/fingerprint_reader.dart';
import 'package:abu_zaria_cbt/modules/auth/view/fingerprint_login_view.dart';
import 'package:abu_zaria_cbt/data/services/center_exam_service.dart';

void main() {
  setUp(() {
    DemoAuth.instance.account = null;
    DemoAuth.instance.student = null;
  });
  tearDown(() => Get.reset());
  test(
    'student passwords and unsuccessful verification cannot grant access',
    () async {
      final auth = DemoAuth.instance;
      expect(await auth.signIn('Student', 'ABU/CSC/001', 'cbt001'), isFalse);
      expect(
        auth.completeStudentFingerprint(
          'ABU/CSC/001',
          FingerprintResult.notMatched,
        ),
        isFalse,
      );
      expect(
        auth.completeStudentFingerprint(
          'ABU/CSC/001',
          FingerprintResult.unavailable,
        ),
        isFalse,
      );
      expect(
        auth.completeStudentFingerprint('UNKNOWN', FingerprintResult.matched),
        isFalse,
      );
      expect(auth.account, isNull);
    },
  );
  testWidgets(
    'registration-only page rejects unknown candidate and cancelling a scan does not sign in',
    (tester) async {
      await tester.pumpWidget(const CenterExamApp());
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Password'), findsNothing);
      await tester.enterText(find.byType(TextFormField), 'UNKNOWN');
      await tester.ensureVisible(find.text('Next'));
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Registration number not found. Check your details and try again.',
        ),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextFormField), 'ABU/CSC/001');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Simulate fingerprint scan'));
      await tester.tap(find.text('Simulate fingerprint scan'));
      await tester.pump();
      await tester.ensureVisible(
        find.text('Use a different registration number'),
      );
      await tester.tap(find.text('Use a different registration number'));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(DemoAuth.instance.account, isNull);
      expect(find.text('Next'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  for (final failed in [
    FingerprintResult.notMatched,
    FingerprintResult.unavailable,
  ]) {
    testWidgets('$failed allows retry but not entry', (tester) async {
      final reader = DemoFingerprintReader()..outcome = failed;
      final candidate = CenterExamService.restoreCandidateSession(
        'ABU/CSC/001',
      )!.candidate;
      await tester.pumpWidget(
        MaterialApp(
          home: FingerprintLoginView(candidate: candidate, reader: reader),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Simulate fingerprint scan'));
      await tester.tap(find.text('Simulate fingerprint scan'));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Retry fingerprint scan'), findsOneWidget);
      expect(find.text('Continue to exams'), findsNothing);
      expect(DemoAuth.instance.account, isNull);
      reader.outcome = FingerprintResult.matched;
      await tester.ensureVisible(find.text('Retry fingerprint scan'));
      await tester.tap(find.text('Retry fingerprint scan'));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Continue to exams'), findsOneWidget);
      expect(DemoAuth.instance.account, isNull);
      expect(tester.takeException(), isNull);
    });
  }
}
