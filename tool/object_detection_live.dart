// Hardware acceptance entry point. Uses the production exam controller and UI.
// Run only for a supervised camera test; no authentication routes are changed.
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:abu_zaria_cbt/app/routes/app_routes.dart';
import 'package:abu_zaria_cbt/data/models/center_exam_models.dart';
import 'package:abu_zaria_cbt/data/services/center_exam_service.dart';
import 'package:abu_zaria_cbt/data/services/workstation_presence_ws_service.dart';
import 'package:abu_zaria_cbt/modules/demo/abu_demo_theme.dart';
import 'package:abu_zaria_cbt/modules/exam/controller/center_exam_run_controller.dart';
import 'package:abu_zaria_cbt/modules/practice/practice_run_view.dart';

void startHardwareTest() {
  final source = CenterExamService.restoreCandidateSession(
    'ABU/CSC/001',
  )!.exams.first;
  Get.toNamed(
    Routes.centerExamRun,
    arguments: CenterExam(
      id: 'detector-hardware-test',
      courseCode: 'TEST',
      courseTitle: 'Detector hardware test',
      venue: 'Local workstation',
      dateLabel: DateTime.now().toIso8601String(),
      startTime: '',
      endTime: '',
      status: CenterExamStatus.dueNow,
      durationMinutes: 5,
      questions: source.questions,
    ),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final observer = WorkstationPresenceWsService();
  observer.incoming.listen((event) {
    final record = event.record;
    if (record?.examTitle.contains('Detector hardware test') ?? false) {
      debugPrint('DETECTOR_OFFICER ${jsonEncode(record!.toJson())}');
    }
  });
  await observer.connectInvigilator(centerName: 'ABU');
  runApp(
    GetMaterialApp(
      theme: abuDemoTheme(),
      initialRoute: '/',
      onReady: () {
        if (const bool.fromEnvironment('DETECTOR_AUTOSTART')) {
          startHardwareTest();
        }
      },
      getPages: [
        GetPage(
          name: '/',
          page: () => Scaffold(
            appBar: AppBar(
              title: const Text('Object detection — live camera test'),
            ),
            body: Center(
              child: FilledButton(
                onPressed: startHardwareTest,
                child: const Text('Start live camera test'),
              ),
            ),
          ),
        ),
        GetPage(
          name: Routes.centerExamRun,
          binding: BindingsBuilder(() {
            final controller = Get.put(CenterExamRunController());
            ever(
              controller.objectDetectionStatus,
              (value) => debugPrint('DETECTOR_STATUS $value'),
            );
            ever(
              controller.objectDetectionFlags,
              (value) => debugPrint('DETECTOR_FLAGS ${jsonEncode(value)}'),
            );
          }),
          page: () => const _LiveExam(),
        ),
        GetPage(
          name: Routes.centerExamSubmit,
          page: () =>
              const Scaffold(body: Center(child: Text('Test submitted'))),
        ),
      ],
    ),
  );
}

class _LiveExam extends StatefulWidget {
  const _LiveExam();
  @override
  State<_LiveExam> createState() => _LiveExamState();
}

class _LiveExamState extends State<_LiveExam> {
  Timer? _deadline;
  @override
  void initState() {
    super.initState();
    _deadline = Timer(const Duration(minutes: 3), () => Get.offAllNamed('/'));
  }

  @override
  void dispose() {
    _deadline?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Supervised detector test · stops after 3 minutes'),
      actions: [
        TextButton(
          onPressed: () => Get.offAllNamed('/'),
          child: const Text('Stop camera test'),
        ),
      ],
    ),
    body: const PracticeRunView(),
  );
}
