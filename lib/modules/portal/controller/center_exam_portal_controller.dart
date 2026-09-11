import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/routes/app_routes.dart';
import '../../../data/models/center_exam_models.dart';
import '../../../data/services/center_exam_service.dart';

class CenterExamPortalController extends GetxController {
  static const _savedCandidateRegNoKey = 'center_exam.saved_candidate_reg_no';

  final candidate = Rxn<CenterCandidate>();
  final exams = <CenterExam>[].obs;
  final isBootstrapping = false.obs;

  @override
  void onInit() {
    super.onInit();
    _restoreSessionIfNeeded();
  }

  Future<void> loadCandidateSession(
    CenterLoginResult result, {
    bool persist = true,
  }) async {
    candidate.value = result.candidate;
    exams.assignAll(result.exams);
    if (persist) {
      await _saveCandidateRegNo(result.candidate.registrationNumber);
    }
  }

  List<CenterExam> get dueNow =>
      exams.where((e) => e.status == CenterExamStatus.dueNow).toList();

  List<CenterExam> get upcoming =>
      exams.where((e) => e.status == CenterExamStatus.upcoming).toList();

  List<CenterExam> get completed =>
      exams.where((e) => e.status == CenterExamStatus.completed).toList();

  List<CenterExam> get closed =>
      exams.where((e) => e.status == CenterExamStatus.closed).toList();

  void markExamCompleted(String examId) {
    exams.assignAll(
      exams.map((exam) {
        if (exam.id != examId) return exam;
        return CenterExam(
          id: exam.id,
          courseCode: exam.courseCode,
          courseTitle: exam.courseTitle,
          venue: exam.venue,
          dateLabel: exam.dateLabel,
          startTime: exam.startTime,
          endTime: exam.endTime,
          status: CenterExamStatus.completed,
          durationMinutes: exam.durationMinutes,
          questions: exam.questions,
        );
      }).toList(),
    );
  }

  void startExam(CenterExam exam) {
    Get.toNamed(Routes.centerExamInstruction, arguments: exam);
  }

  Future<void> logout() async {
    candidate.value = null;
    exams.clear();
    await _clearSavedSession();
    Get.offAllNamed(Routes.centerLogin);
  }

  Future<void> _restoreSessionIfNeeded() async {
    if (candidate.value != null) return;

    isBootstrapping.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedRegNo = prefs.getString(_savedCandidateRegNoKey) ?? '';
      if (savedRegNo.trim().isNotEmpty) {
        final restored = CenterExamService.restoreCandidateSession(savedRegNo);
        if (restored != null) {
          await loadCandidateSession(restored, persist: false);
          return;
        }
      }

      if (Get.currentRoute == Routes.centerPortal) {
        Get.offAllNamed(Routes.centerLogin);
      }
    } finally {
      isBootstrapping.value = false;
    }
  }

  Future<void> _saveCandidateRegNo(String regNo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedCandidateRegNoKey, regNo.trim().toUpperCase());
  }

  Future<void> _clearSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedCandidateRegNoKey);
  }
}
