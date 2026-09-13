import 'package:get/get.dart';
import 'package:abu_zaria_cbt/app/routes/app_routes.dart';
import 'package:abu_zaria_cbt/modules/auth/demo_auth.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:abu_zaria_cbt/main.dart';

void main() {
  testWidgets('render workspace preview', (tester) async {
    await tester.runAsync(() async {
      for (final family in ['Segoe UI', 'Roboto']) {
        final loader = FontLoader(family);
        loader.addFont(
          File(
            'C:/Windows/Fonts/segoeui.ttf',
          ).readAsBytes().then((b) => ByteData.sublistView(b)),
        );
        await loader.load();
      }
      final icons = FontLoader('MaterialIcons');
      icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    });
    await tester.runAsync(
      () => DemoAuth.instance.signIn(
        'Administrator',
        'admin.abu',
        'AbuAdmin123!',
      ),
    );
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(key: key, child: const CenterExamApp()),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('docs/previews').create(recursive: true);
      await File(
        'docs/previews/abu-login.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
    });
    await tester.enterText(find.byType(TextFormField).first, 'ABU/CSC/001');
    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        'docs/previews/abu-fingerprint.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
    });
    Get.offAllNamed(Routes.demo);
    await tester.pumpAndSettle();
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('docs/previews').create(recursive: true);
      await File(
        'docs/previews/abu-overview.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
    });
    expect(tester.takeException(), isNull);
  });
}
