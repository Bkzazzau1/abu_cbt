import 'package:abu_zaria_cbt/modules/auth/demo_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:abu_zaria_cbt/main.dart';
import 'package:abu_zaria_cbt/app/routes/app_routes.dart';
import 'package:abu_zaria_cbt/data/services/center_exam_service.dart';
import 'package:abu_zaria_cbt/modules/portal/controller/center_exam_portal_controller.dart';
import 'package:abu_zaria_cbt/modules/exam/controller/center_exam_run_controller.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => Get.reset());
  Future<void> boot(WidgetTester tester, Size size) async {
    await tester.runAsync(
      () => Future.value(DemoAuth.instance.beginStudentSession('ABU/CSC/001')),
    );
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const CenterExamApp());
    await tester.pumpAndSettle();
    final portal = Get.put(CenterExamPortalController(), permanent: true);
    await portal.loadCandidateSession(
      CenterExamService.restoreCandidateSession('ABU/CSC/001')!,
      persist: false,
    );
    Get.toNamed(Routes.centerPortal);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'candidate completes preflight and retains answers while navigating',
    (tester) async {
      await boot(tester, const Size(1440, 1000));
      expect(
        find.text('Your next exam starts with preparation.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Start a practice session'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Continue to confirmation'));
      await tester.tap(find.text('Continue to confirmation'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Begin examination'),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Begin examination'));
      await tester.tap(find.text('Begin examination'));
      await tester.pumpAndSettle();
      final run = Get.find<CenterExamRunController>();
      final firstSingle = run.exam.value!.questions.indexWhere(
        (q) => q.options.isNotEmpty,
      );
      run.jumpTo(firstSingle);
      await tester.pump();
      final option = run.currentQuestion.options.first;
      await tester.ensureVisible(find.text(option));
      await tester.tap(find.text(option));
      await tester.pump();
      expect(run.currentAnswer.selectedIndexes, contains(0));
      await tester.tap(find.text('Flag for review'));
      await tester.pump();
      expect(run.isFlagged(firstSingle), isTrue);
      run.jumpTo((firstSingle + 1) % run.totalQuestions);
      run.jumpTo(firstSingle);
      await tester.pump();
      expect(run.currentAnswer.selectedIndexes, contains(0));
      await tester.tap(find.text('Review & submit'));
      await tester.pumpAndSettle();
      expect(find.text('Review your responses'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('practice portal and every seeded question fit a phone', (
    tester,
  ) async {
    await boot(tester, const Size(390, 844));
    expect(tester.takeException(), isNull);
    final exam = Get.find<CenterExamPortalController>().exams.first;
    Get.toNamed(Routes.centerExamRun, arguments: exam);
    await tester.pumpAndSettle();
    final run = Get.find<CenterExamRunController>();
    for (var i = 0; i < run.totalQuestions; i++) {
      run.jumpTo(i);
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: 'Question ${i + 1}: ${run.currentQuestion.type}',
      );
    }
    await tester.tap(find.text('Questions'));
    await tester.pumpAndSettle();
    expect(find.text('QUESTION NAVIGATOR'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
