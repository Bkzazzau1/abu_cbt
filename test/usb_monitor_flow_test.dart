import 'dart:async';

import 'package:abu_zaria_cbt/app/routes/app_routes.dart';
import 'package:abu_zaria_cbt/data/models/invigilator_models.dart';
import 'package:abu_zaria_cbt/data/models/workstation_presence_models.dart';
import 'package:abu_zaria_cbt/data/services/center_exam_service.dart';
import 'package:abu_zaria_cbt/data/services/hall_network_risk_service.dart';
import 'package:abu_zaria_cbt/data/services/object_detection_service.dart';
import 'package:abu_zaria_cbt/data/services/usb_monitor_service.dart';
import 'package:abu_zaria_cbt/data/services/workstation_presence_ws_service.dart';
import 'package:abu_zaria_cbt/modules/exam/controller/center_exam_run_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeUsbMonitor extends UsbMonitorService {
  void Function(String)? emit;
  int starts = 0;
  int stops = 0;

  @override
  Future<void> start(void Function(String) onFlag) async {
    starts++;
    emit = onFlag;
  }

  @override
  void stop() {
    stops++;
    emit = null;
  }
}

class CapturingPresence extends WorkstationPresenceWsService {
  final sent = <WorkstationPresenceRecord>[];
  final firstSent = Completer<void>();
  @override
  Future<void> connectWorkstation() async {}
  @override
  void sendHeartbeat(WorkstationPresenceRecord payload) {
    sent.add(payload);
    if (!firstSent.isCompleted) firstSent.complete();
  }
}

class FakeObjectDetector extends ObjectDetectionService {
  void Function(String)? emit;
  int starts = 0;
  int stops = 0;

  @override
  Future<void> start(
    void Function(String) onFlag, {
    void Function(String)? onStatus,
    EvidenceCallback? onEvidence,
    String? referencePhotoPath,
    int? durationSeconds,
  }) async {
    starts++;
    emit = onFlag;
    onStatus?.call('Active');
  }

  @override
  Future<void> stop() async {
    stops++;
    emit = null;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
  });
  tearDown(() => Get.reset());

  for (final ending in ['close', 'expiry', 'submit']) {
    testWidgets('USB and object audit, telemetry and lifecycle: $ending', (
      tester,
    ) async {
      final monitor = FakeUsbMonitor();
      final detector = FakeObjectDetector();
      final presence =
          Get.put<WorkstationPresenceWsService>(CapturingPresence())
              as CapturingPresence;
      final controller = CenterExamRunController(
        usbMonitor: monitor,
        objectDetector: detector,
        assessHall: ({required hallName}) async => HallIpRiskAssessment(
          ipAddress: '192.168.10.2',
          expectedRanges: ['192.168.10.0/24'],
          matchesExpectedRange: true,
        ),
      );
      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/',
          getPages: [
            GetPage(name: '/', page: () => const Scaffold()),
            GetPage(
              name: Routes.centerExamSubmit,
              page: () => const Scaffold(),
            ),
            GetPage(
              name: '/exam',
              page: () => const Scaffold(),
              binding: BindingsBuilder(() {
                Get.put(controller);
              }),
            ),
          ],
        ),
      );
      Get.toNamed(
        '/exam',
        arguments: CenterExamService.restoreCandidateSession(
          'ABU/CSC/001',
        )!.exams.first,
      );
      await tester.pumpAndSettle();
      expect(monitor.starts, 1);
      expect(detector.starts, 1);
      expect(controller.objectDetectionStatus.value, 'Active');
      expect(controller.exam.value, isNotNull);
      const event =
          'USB device connected at 2026-09-14T12:00:00Z: USB-test. Officer review required.';
      monitor.emit!(event);
      const objectEvent =
          'Possible phone detected at 2026-09-14T12:00:00Z (85% model confidence). Officer review required.';
      detector.emit!(objectEvent);
      await tester.runAsync(
        () => presence.firstSent.future.timeout(const Duration(seconds: 5)),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      final key = prefs.getKeys().singleWhere(
        (key) => key.startsWith('usb.audit.'),
      );
      expect(prefs.getStringList(key), contains(event));
      final objectKey = prefs.getKeys().singleWhere(
        (key) => key.startsWith('objects.audit.'),
      );
      expect(prefs.getStringList(objectKey), contains(objectEvent));
      expect(presence.sent.last.riskFlagged, isTrue);
      expect(presence.sent.last.riskReasons, contains(event));
      expect(presence.sent.last.riskReasons, contains(objectEvent));
      final wire = WorkstationPresenceRecord.fromJson(
        presence.sent.last.toJson(),
      );
      expect(wire.riskReasons, contains(event));
      if (ending == 'expiry') {
        controller.secondsLeft.value = 1;
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
        expect(monitor.stops, 1);
        Get.back<void>(); // Time-expiry dialog.
        Get.back<void>(); // Exam route.
      } else if (ending == 'submit') {
        controller.requestSubmit();
        await tester.pumpAndSettle();
        await tester.tap(find.text('Submit practice'));
        await tester.pumpAndSettle();
        expect(presence.sent.last.usageState, WorkstationUsageState.submitted);
        expect(presence.sent.last.riskReasons, contains(event));
      } else {
        Get.back<void>();
      }
      await tester.pumpAndSettle();
      expect(monitor.stops, greaterThanOrEqualTo(1));
      expect(monitor.emit, isNull);
      expect(detector.stops, greaterThanOrEqualTo(1));
      expect(detector.emit, isNull);
      expect(controller.objectDetectionStatus.value, 'Stopped');
      await tester.pumpWidget(const SizedBox());
    });
  }
}
