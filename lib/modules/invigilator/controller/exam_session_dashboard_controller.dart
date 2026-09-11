import 'package:get/get.dart';

import '../../../data/models/exam_session_models.dart';
import '../../../data/services/exam_session_mock_service.dart';

class ExamSessionDashboardController extends GetxController {
  final isLoading = false.obs;
  final session = Rxn<ExamSessionSummary>();

  Future<void> load() async {
    isLoading.value = true;
    try {
      session.value = await ExamSessionMockService.loadCurrentSession();
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  void startSession() {
    final current = session.value;
    if (current == null) return;
    session.value = current.copyWith(state: ExamSessionState.running);
    Get.snackbar(
      'Session Started',
      'Exam session is now running.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void pauseSession() {
    final current = session.value;
    if (current == null) return;
    session.value = current.copyWith(state: ExamSessionState.paused);
    Get.snackbar(
      'Session Paused',
      'Exam session has been paused.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void resumeSession() {
    final current = session.value;
    if (current == null) return;
    session.value = current.copyWith(state: ExamSessionState.running);
    Get.snackbar(
      'Session Resumed',
      'Exam session is running again.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void closeSession() {
    final current = session.value;
    if (current == null) return;
    session.value = current.copyWith(state: ExamSessionState.closed);
    Get.snackbar(
      'Session Closed',
      'Exam session has been closed.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
