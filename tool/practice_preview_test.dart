import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:abu_zaria_cbt/main.dart';
import 'package:abu_zaria_cbt/app/routes/app_routes.dart';
import 'package:abu_zaria_cbt/data/services/center_exam_service.dart';
import 'package:abu_zaria_cbt/modules/portal/controller/center_exam_portal_controller.dart';
import 'package:abu_zaria_cbt/modules/exam/controller/center_exam_run_controller.dart';

void main() {
  testWidgets('render practice screens', (tester) async {
    // This file is a Flutter rendering test, invoked explicitly from tool/.
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(() async {
      for (final family in ['Segoe UI', 'Roboto']) {
        final loader = FontLoader(family);
        loader.addFont(
          File(
            'C:/Windows/Fonts/segoeui.ttf',
          ).readAsBytes().then(ByteData.sublistView),
        );
        await loader.load();
      }
      final icons = FontLoader('MaterialIcons');
      icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    });
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(key: key, child: const CenterExamApp()),
    );
    await tester.pumpAndSettle();
    final portal = Get.put(CenterExamPortalController(), permanent: true);
    await portal.loadCandidateSession(
      CenterExamService.restoreCandidateSession('ABU/CSC/001')!,
      persist: false,
    );
    final exam = portal.exams.first;
    for (final page in [
      (Routes.centerPortal, 'practice-portal'),
      (Routes.centerExamInstruction, 'practice-instructions'),
      (Routes.centerExamRun, 'practice-player'),
    ]) {
      Get.toNamed(page.$1, arguments: exam);
      await tester.pumpAndSettle();
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('docs/previews').create(recursive: true);
        await File(
          'docs/previews/${page.$2}.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
      });
      expect(tester.takeException(), isNull);
    }
    Get.find<CenterExamRunController>().onClose();
    Get.reset();
    await tester.pumpWidget(const SizedBox());
  });
}
