import 'dart:async';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/routes/app_routes.dart';
import '../../../data/models/center_exam_models.dart';
import '../../../data/services/center_exam_service.dart';
import '../../../data/services/object_detection_service.dart';
import '../../../data/services/reference_photo_extractor.dart';

class CenterExamPortalController extends GetxController {
  static const _savedCandidateRegNoKey = 'center_exam.saved_candidate_reg_no';

  // Generous fixed window for the whole logged-in session (monitoring starts
  // here at login, not per-exam) — only used to space out identity snapshot
  // checks, not as a hard cutoff, so it doesn't need to match actual exam
  // durations.
  static const _sessionMonitoringSeconds = 4 * 3600;

  final candidate = Rxn<CenterCandidate>();
  final exams = <CenterExam>[].obs;
  final isBootstrapping = false.obs;

  /// Shared for the whole login session: started here so monitoring is
  /// running from the moment a candidate logs in, and reused (re-attached,
  /// not restarted) by the exam screen so the camera isn't opened twice.
  final ObjectDetectionService objectDetector = ObjectDetectionService();
  final _referencePhotoExtractor = ReferencePhotoExtractor();
  String? referencePhotoPath;

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
    unawaited(_startBackgroundMonitoring());
  }

  /// Starts local camera/object-detection monitoring immediately on login
  /// (rather than waiting for the candidate to open an exam) so a phone or
  /// impersonation check is running for their whole time at the
  /// workstation. Flags aren't attributed to any specific exam until one is
  /// opened — the exam screen re-attaches its own audit/popup handling onto
  /// this same running process at that point.
  Future<void> _startBackgroundMonitoring() async {
    final c = candidate.value;
    if (c == null) return;
    referencePhotoPath = await _referencePhotoExtractor.extract(c.photoAsset);
    await objectDetector.start(
      (_) {},
      referencePhotoPath: referencePhotoPath,
      durationSeconds: _sessionMonitoringSeconds,
    );
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
    await objectDetector.stop();
    await _referencePhotoExtractor.dispose();
    referencePhotoPath = null;
    Get.offAllNamed(Routes.centerLogin);
  }

  @override
  void onClose() {
    unawaited(objectDetector.stop());
    unawaited(_referencePhotoExtractor.dispose());
    super.onClose();
  }

  Future<void> _restoreSessionIfNeeded() async {
    if (candidate.value != null) return;

    isBootstrapping.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (candidate.value != null) return;
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
