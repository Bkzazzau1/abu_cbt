import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/ks_status_chip.dart';
import '../../../data/models/center_exam_models.dart';
import '../../../data/models/invigilator_models.dart';
import '../../../data/models/workstation_models.dart';
import '../../../data/models/workstation_presence_models.dart';
import '../../../data/services/hall_network_risk_service.dart';
import '../../../data/services/network_health_service.dart';
import '../../../data/services/workstation_presence_ws_service.dart';
import '../../../data/services/workstation_service.dart';
import '../models/whiteboard_models.dart';
import '../../portal/controller/center_exam_portal_controller.dart';

class CenterExamRunController extends GetxController {
  final exam = Rxn<CenterExam>();

  final currentIndex = 0.obs;
  final answers = <String, CenterCandidateAnswer>{}.obs;

  // Current-question working state.
  final selectedIndexes = <int>[].obs;
  final textAnswer = ''.obs;
  final dragAssignments = <String, String>{}.obs;
  final whiteboardStrokeCount = 0.obs;

  // Optional review flag marker for question palette.
  final flaggedQuestionIds = <String>{}.obs;
  final _whiteboardByQuestion = <String, List<WhiteboardStrokeData>>{};

  final secondsLeft = 0.obs;
  final isSubmitted = false.obs;

  // Frontend-only local save/sync flags.
  final hasLocalAutosave = true.obs;
  final submissionQueuedForSync = false.obs;
  final lastLocalSaveLabel = 'Not saved yet'.obs;

  Timer? _timer;
  bool _timeUpDialogShown = false;

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    CenterExam? payload;

    if (arg is CenterExam) {
      payload = arg;
    } else if (arg is Map<String, dynamic> && arg['exam'] is CenterExam) {
      payload = arg['exam'] as CenterExam;
    }

    if (payload != null) {
      exam.value = payload;
      secondsLeft.value = payload.durationMinutes * 60;
      _syncCurrentAnswer();
      _markSaved();
      _startTimer();
      unawaited(_emitInExamHeartbeat());
    }
  }

  CenterQuestion get currentQuestion =>
      exam.value!.questions[currentIndex.value];

  int get totalQuestions => exam.value?.questions.length ?? 0;

  bool get isLastQuestion =>
      totalQuestions > 0 && currentIndex.value == totalQuestions - 1;

  double get progress =>
      totalQuestions == 0 ? 0 : (currentIndex.value + 1) / totalQuestions;

  int get unansweredCount {
    final examValue = exam.value;
    if (examValue == null) return 0;
    return examValue.questions
        .where((q) => !_isQuestionAnswered(q, answers[q.id]))
        .length;
  }

  bool isAnswered(int questionIndex) {
    final examValue = exam.value;
    if (examValue == null) return false;
    if (questionIndex < 0 || questionIndex >= examValue.questions.length) {
      return false;
    }
    final q = examValue.questions[questionIndex];
    return _isQuestionAnswered(q, answers[q.id]);
  }

  bool isFlagged(int questionIndex) {
    final examValue = exam.value;
    if (examValue == null) return false;
    if (questionIndex < 0 || questionIndex >= examValue.questions.length) {
      return false;
    }
    return flaggedQuestionIds.contains(examValue.questions[questionIndex].id);
  }

  void jumpTo(int index) {
    if (exam.value == null) return;
    if (index < 0 || index >= totalQuestions) return;
    currentIndex.value = index;
    _syncCurrentAnswer();
    _markSaved();
  }

  void toggleFlagCurrentQuestion() {
    final id = currentQuestion.id;
    if (flaggedQuestionIds.contains(id)) {
      flaggedQuestionIds.remove(id);
    } else {
      flaggedQuestionIds.add(id);
    }
    _markSaved();
  }

  void pickSingle(int index) {
    selectedIndexes.assignAll([index]);
    _persistCurrentAnswer();
  }

  void toggleMultiple(int index) {
    if (selectedIndexes.contains(index)) {
      selectedIndexes.remove(index);
    } else {
      selectedIndexes.add(index);
      selectedIndexes.sort();
    }
    _persistCurrentAnswer();
  }

  void pickTrueFalse(bool value) {
    pickSingle(value ? 0 : 1);
  }

  void updateTextAnswer(String value) {
    textAnswer.value = value;
    _persistCurrentAnswer();
  }

  void assignDragTarget({
    required String dragItem,
    required String dropTarget,
  }) {
    if (dropTarget.trim().isEmpty) {
      dragAssignments.remove(dragItem);
    } else {
      dragAssignments[dragItem] = dropTarget;
    }
    _persistCurrentAnswer();
  }

  void updateDragAssignments(Map<String, String> assignments) {
    dragAssignments.assignAll(assignments);
    _persistCurrentAnswer();
  }

  void updateWhiteboardStrokeCount(int count) {
    whiteboardStrokeCount.value = count < 0 ? 0 : count;
    _persistCurrentAnswer();
  }

  List<WhiteboardStrokeData> get currentWhiteboardStrokes =>
      List<WhiteboardStrokeData>.from(
        _whiteboardByQuestion[currentQuestion.id] ?? const [],
      );

  void saveCurrentWhiteboardStrokes(List<WhiteboardStrokeData> strokes) {
    if (strokes.isEmpty) {
      _whiteboardByQuestion.remove(currentQuestion.id);
    } else {
      _whiteboardByQuestion[currentQuestion.id] =
          List<WhiteboardStrokeData>.from(strokes);
    }
    updateWhiteboardStrokeCount(strokes.length);
  }

  int? get selectedSingleIndex =>
      selectedIndexes.isEmpty ? null : selectedIndexes.first;

  bool isOptionSelected(int index) => selectedIndexes.contains(index);

  String assignedDragTarget(String dragItem) => dragAssignments[dragItem] ?? '';

  CenterCandidateAnswer get currentAnswer =>
      answers[currentQuestion.id] ??
      CenterCandidateAnswer(questionId: currentQuestion.id);

  void next() {
    if (exam.value == null) return;
    if (currentIndex.value < exam.value!.questions.length - 1) {
      currentIndex.value += 1;
      _syncCurrentAnswer();
      _markSaved();
    }
  }

  void previous() {
    if (currentIndex.value > 0) {
      currentIndex.value -= 1;
      _syncCurrentAnswer();
      _markSaved();
    }
  }

  void _syncCurrentAnswer() {
    final answer = answers[currentQuestion.id];
    selectedIndexes.assignAll(answer?.selectedIndexes ?? const <int>[]);
    textAnswer.value = answer?.textAnswer ?? '';
    dragAssignments.assignAll(
      answer?.dragAssignments ?? const <String, String>{},
    );
    whiteboardStrokeCount.value = answer?.whiteboardStrokeCount ?? 0;
  }

  void _persistCurrentAnswer() {
    final q = currentQuestion;
    final candidateAnswer = CenterCandidateAnswer(
      questionId: q.id,
      selectedIndexes: List<int>.from(selectedIndexes),
      textAnswer: textAnswer.value.trim().isEmpty
          ? null
          : textAnswer.value.trim(),
      dragAssignments: Map<String, String>.from(dragAssignments),
      whiteboardStrokeCount: whiteboardStrokeCount.value,
    );

    if (_isQuestionAnswered(q, candidateAnswer)) {
      answers[q.id] = candidateAnswer;
    } else {
      answers.remove(q.id);
    }
    _markSaved();
  }

  bool _isQuestionAnswered(CenterQuestion q, CenterCandidateAnswer? answer) {
    if (answer == null) return false;

    switch (q.type) {
      case CenterQuestionType.objectiveSingle:
      case CenterQuestionType.objectiveMultiple:
      case CenterQuestionType.trueFalse:
        return answer.selectedIndexes.isNotEmpty;
      case CenterQuestionType.fillBlank:
      case CenterQuestionType.essay:
      case CenterQuestionType.shortAnswer:
        return (answer.textAnswer ?? '').trim().isNotEmpty;
      case CenterQuestionType.dragDrop:
        return answer.dragAssignments.isNotEmpty;
      case CenterQuestionType.whiteboard:
        return answer.whiteboardStrokeCount > 0;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsLeft.value <= 1) {
        _handleTimeUp();
        return;
      }
      secondsLeft.value -= 1;
    });
  }

  void _handleTimeUp() {
    if (isSubmitted.value || _timeUpDialogShown) return;
    _timer?.cancel();
    _timeUpDialogShown = true;

    final cs = Get.theme.colorScheme;
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: GlassCard(
          tone: GlassCardTone.warning,
          showGlow: true,
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.timer_off_outlined, color: Color(0xFFF59E0B)),
                  SizedBox(width: 10),
                  Text(
                    'Session Time Elapsed',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Your exam time has ended. The system will submit your responses now.',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.78),
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              const KsStatusChip(
                label: 'Auto Submit in Progress',
                tone: KsStatusChipTone.warningSoft,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    Get.back();
                    await _finalizeSubmission(autoSubmitted: true);
                  },
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: const Text('Proceed'),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  NetworkHealthStatus get networkStatus {
    if (!Get.isRegistered<NetworkHealthService>()) {
      return NetworkHealthStatus.online;
    }
    return Get.find<NetworkHealthService>().status.value;
  }

  void _markSaved() {
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    lastLocalSaveLabel.value = 'Saved locally at $hh:$mm:$ss';
  }

  int get score {
    final examValue = exam.value;
    if (examValue == null) return 0;

    int total = 0;
    for (final q in examValue.questions) {
      if (!_isAutoMarkable(q)) continue;
      final answer = answers[q.id];
      if (answer == null) continue;
      if (_isAnswerCorrect(q, answer)) {
        total += q.points;
      }
    }
    return total;
  }

  int get totalPossibleAutoScore {
    final examValue = exam.value;
    if (examValue == null) return 0;
    return examValue.questions
        .where(_isAutoMarkable)
        .fold<int>(0, (sum, q) => sum + q.points);
  }

  int get totalPossibleScore {
    final examValue = exam.value;
    if (examValue == null) return 0;
    return examValue.questions.fold<int>(0, (sum, q) => sum + q.points);
  }

  bool get needsReview {
    final examValue = exam.value;
    if (examValue == null) return false;
    return examValue.questions.any(
      (q) => _requiresManualReview(q) && _isQuestionAnswered(q, answers[q.id]),
    );
  }

  int get manualReviewCount {
    final examValue = exam.value;
    if (examValue == null) return 0;
    return examValue.questions
        .where(
          (q) =>
              _requiresManualReview(q) && _isQuestionAnswered(q, answers[q.id]),
        )
        .length;
  }

  bool _isAutoMarkable(CenterQuestion q) {
    switch (q.type) {
      case CenterQuestionType.objectiveSingle:
      case CenterQuestionType.objectiveMultiple:
      case CenterQuestionType.trueFalse:
      case CenterQuestionType.fillBlank:
      case CenterQuestionType.dragDrop:
        return true;
      case CenterQuestionType.essay:
      case CenterQuestionType.whiteboard:
      case CenterQuestionType.shortAnswer:
        return false;
    }
  }

  bool _requiresManualReview(CenterQuestion q) {
    switch (q.type) {
      case CenterQuestionType.essay:
      case CenterQuestionType.whiteboard:
      case CenterQuestionType.shortAnswer:
        return true;
      case CenterQuestionType.objectiveSingle:
      case CenterQuestionType.objectiveMultiple:
      case CenterQuestionType.fillBlank:
      case CenterQuestionType.dragDrop:
      case CenterQuestionType.trueFalse:
        return false;
    }
  }

  bool _isAnswerCorrect(CenterQuestion q, CenterCandidateAnswer answer) {
    switch (q.type) {
      case CenterQuestionType.objectiveSingle:
      case CenterQuestionType.trueFalse:
        if (q.correctIndexes.isEmpty || answer.selectedIndexes.length != 1) {
          return false;
        }
        return answer.selectedIndexes.first == q.correctIndexes.first;
      case CenterQuestionType.objectiveMultiple:
        final selected = answer.selectedIndexes.toSet();
        final correct = q.correctIndexes.toSet();
        return selected.isNotEmpty &&
            selected.length == correct.length &&
            selected.containsAll(correct);
      case CenterQuestionType.fillBlank:
        final response = (answer.textAnswer ?? '').trim().toLowerCase();
        if (response.isEmpty) return false;
        return q.correctTextAnswers.any(
          (item) => item.trim().toLowerCase() == response,
        );
      case CenterQuestionType.dragDrop:
        if (q.dragItems.isEmpty || q.dragItems.length != q.dropTargets.length) {
          return false;
        }
        for (int i = 0; i < q.dragItems.length; i++) {
          final item = q.dragItems[i];
          final expected = q.dropTargets[i];
          if (answer.dragAssignments[item] != expected) {
            return false;
          }
        }
        return true;
      case CenterQuestionType.essay:
      case CenterQuestionType.whiteboard:
      case CenterQuestionType.shortAnswer:
        return false;
    }
  }

  void requestSubmit() {
    if (isSubmitted.value || exam.value == null) return;
    final cs = Get.theme.colorScheme;
    final unanswered = unansweredCount;
    final answered = totalQuestions - unanswered;
    final flagged = flaggedQuestionIds.length;

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: GlassCard(
          tone: GlassCardTone.primary,
          showGlow: true,
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.verified_user_outlined, color: Color(0xFF39D2FF)),
                  SizedBox(width: 10),
                  Text(
                    'Submit Examination',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                unanswered == 0
                    ? 'All questions appear answered. Submit now for final grading?'
                    : 'You still have $unanswered unanswered question(s). You can review before submitting.',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.78),
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  KsStatusChip(
                    label: 'Answered: $answered',
                    tone: KsStatusChipTone.success,
                  ),
                  KsStatusChip(
                    label: 'Unanswered: $unanswered',
                    tone: unanswered > 0
                        ? KsStatusChipTone.warning
                        : KsStatusChipTone.info,
                  ),
                  if (flagged > 0)
                    KsStatusChip(
                      label: 'Flagged: $flagged',
                      tone: KsStatusChipTone.warningSoft,
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: Get.back,
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Review Answers'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        Get.back();
                        await _finalizeSubmission(autoSubmitted: false);
                      },
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: const Text('Submit Now'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _finalizeSubmission({required bool autoSubmitted}) async {
    if (isSubmitted.value) return;
    final examValue = exam.value;
    if (examValue == null) return;
    final risk = await _assessSubmissionRisk();
    await _emitUsageHeartbeat(
      WorkstationUsageState.submitted,
      registrationOverride: risk.registration,
      riskContext: risk,
    );

    isSubmitted.value = true;
    _timer?.cancel();

    if (Get.isRegistered<CenterExamPortalController>()) {
      Get.find<CenterExamPortalController>().markExamCompleted(examValue.id);
    }

    final offlineLike =
        networkStatus == NetworkHealthStatus.offline ||
        networkStatus == NetworkHealthStatus.lowNetwork;
    submissionQueuedForSync.value = offlineLike;

    Get.offNamed(
      Routes.centerExamSubmit,
      arguments: <String, dynamic>{
        'exam': examValue,
        'score': score,
        'totalQuestions': examValue.questions.length,
        'totalPossibleAutoScore': totalPossibleAutoScore,
        'totalPossibleScore': totalPossibleScore,
        'unansweredCount': unansweredCount,
        'needsReview': needsReview,
        'manualReviewCount': manualReviewCount,
        'submittedAt': DateTime.now(),
        'autoSubmitted': autoSubmitted,
        'queuedForSync': offlineLike,
        'workstationId': risk.registration.workstationId,
        'centerName': risk.registration.centerName,
        'hallName': risk.registration.hallName,
        'seatNumber': risk.registration.seatNumber,
        'workstationStatus': risk.registration.status.name,
        'riskFlagged': risk.riskFlagged,
        'riskReasons': risk.reasons,
        'isNewWorkstation': risk.isNewWorkstation,
        'clientIpAddress': risk.ipAddress,
        'expectedHallIpRange': risk.expectedRangeLabel,
        'ipInExpectedRange': risk.ipInExpectedRange,
        'riskScore': risk.riskScore,
        'riskLevel': risk.riskLevel,
        'workstationApproved': risk.workstationApproved,
        'securityHeader': _buildSecurityHeader(risk),
      },
    );
    await WorkstationService.markSubmission(risk.registration.workstationId);
  }

  Future<void> _emitInExamHeartbeat() async {
    final risk = await _assessSubmissionRisk();
    await _emitUsageHeartbeat(
      WorkstationUsageState.inExam,
      registrationOverride: risk.registration,
      riskContext: risk,
    );
  }

  Future<void> _emitUsageHeartbeat(
    WorkstationUsageState state, {
    WorkstationRegistration? registrationOverride,
    _SubmissionRiskContext? riskContext,
  }) async {
    try {
      final registration =
          registrationOverride ?? await WorkstationService.loadOrCreate();
      if (registration.workstationId.trim().isEmpty) return;

      final wsService = Get.isRegistered<WorkstationPresenceWsService>()
          ? Get.find<WorkstationPresenceWsService>()
          : Get.put(WorkstationPresenceWsService());

      await wsService.connectWorkstation();

      final candidate = Get.isRegistered<CenterExamPortalController>()
          ? Get.find<CenterExamPortalController>().candidate.value
          : null;

      final examValue = exam.value;
      wsService.sendHeartbeat(
        WorkstationPresenceRecord(
          workstationId: registration.workstationId,
          centerName: registration.centerName.isEmpty
              ? 'KASU'
              : registration.centerName,
          hallName: registration.hallName,
          seatNumber: registration.seatNumber,
          registrationNumber: candidate?.registrationNumber ?? '',
          candidateName: candidate?.fullName ?? '',
          examTitle: examValue == null
              ? ''
              : '${examValue.courseCode} - ${examValue.courseTitle}',
          usageState: state,
          workstationStatus: registration.status,
          eventAtIso: DateTime.now().toIso8601String(),
          riskFlagged:
              riskContext?.riskFlagged ??
              registration.status != WorkstationStatus.whitelisted,
          isNewWorkstation: riskContext?.isNewWorkstation ?? false,
          clientIpAddress: riskContext?.ipAddress ?? '',
          expectedHallIpRange: riskContext?.expectedRangeLabel ?? '',
          ipInExpectedRange: riskContext?.ipInExpectedRange ?? true,
          riskReasons: riskContext?.reasons ?? const <String>[],
          workstationApproved:
              riskContext?.workstationApproved ??
              registration.status == WorkstationStatus.whitelisted,
          riskScore: riskContext?.riskScore ?? 0,
          riskLevel: riskContext?.riskLevel ?? 'low',
        ),
      );
    } catch (_) {
      // Presence telemetry should not block exam execution.
    }
  }

  Future<_SubmissionRiskContext> _assessSubmissionRisk() async {
    final candidateRegistrationNumber =
        Get.isRegistered<CenterExamPortalController>()
        ? Get.find<CenterExamPortalController>()
                  .candidate
                  .value
                  ?.registrationNumber ??
              ''
        : '';
    final registration = candidateRegistrationNumber.trim().isEmpty
        ? await WorkstationService.loadOrCreate()
        : await WorkstationService.ensureAssignmentFromAttendance(
            candidateRegistrationNumber: candidateRegistrationNumber,
          );
    final reasons = <String>[];
    final isApproved = registration.status == WorkstationStatus.whitelisted;

    if (registration.workstationId.trim().isEmpty) {
      reasons.add('Workstation ID is missing.');
    }
    if (!isApproved) {
      reasons.add('Workstation ID is not yet whitelisted by invigilator.');
    }
    if (registration.hallName.trim().isEmpty) {
      reasons.add('Hall assignment is missing.');
    }
    if (registration.seatNumber.trim().isEmpty) {
      reasons.add('Seat assignment is missing.');
    }

    final hasUsedBefore = await WorkstationService.hasSubmissionHistory(
      registration.workstationId,
    );
    final isNewWorkstation = !hasUsedBefore;
    if (isNewWorkstation) {
      reasons.add('New workstation detected (no prior submission history).');
    }

    final ipAssessment = await HallNetworkRiskService.assess(
      hallName: registration.hallName,
    );

    var ipInRange = ipAssessment.matchesExpectedRange;
    if (!ipAssessment.hasExpectedRange) {
      ipInRange = false;
      reasons.add(
        registration.hallName.trim().isEmpty
            ? 'Cannot verify hall IP range because hall is not assigned.'
            : 'No configured hall IP range policy for ${registration.hallName}.',
      );
    } else if (!ipAssessment.hasIp) {
      reasons.add('Laptop IP address could not be resolved.');
      ipInRange = false;
    } else if (!ipAssessment.matchesExpectedRange) {
      reasons.add(
        'IP ${ipAssessment.ipAddress} is outside hall range ${ipAssessment.expectedRangeLabel}.',
      );
    }

    var riskScore = 0;
    if (!isApproved) riskScore += 45;
    if (registration.hallName.trim().isEmpty) riskScore += 15;
    if (registration.seatNumber.trim().isEmpty) riskScore += 10;
    if (isNewWorkstation) riskScore += 25;

    if (ipAssessment.hasExpectedRange &&
        ipAssessment.hasIp &&
        !ipAssessment.matchesExpectedRange) {
      // Out-of-bounds network is high severity by policy.
      riskScore = riskScore < 90 ? 90 : riskScore;
    } else if (!ipAssessment.hasIp) {
      riskScore += 40;
    } else if (!ipAssessment.hasExpectedRange) {
      riskScore += 20;
    }

    if (riskScore > 100) {
      riskScore = 100;
    }

    final riskLevel = switch (riskScore) {
      >= 90 => 'critical',
      >= 70 => 'high',
      >= 40 => 'medium',
      _ => 'low',
    };

    return _SubmissionRiskContext(
      registration: registration,
      riskFlagged: reasons.isNotEmpty,
      reasons: reasons,
      isNewWorkstation: isNewWorkstation,
      ipAddress: ipAssessment.ipAddress,
      expectedRangeLabel: ipAssessment.expectedRangeLabel,
      ipInExpectedRange: ipInRange,
      riskScore: riskScore,
      riskLevel: riskLevel,
      workstationApproved: isApproved,
    );
  }

  Map<String, dynamic> _buildSecurityHeader(_SubmissionRiskContext risk) {
    final registration = risk.registration;
    final fingerprintSource =
        '${registration.workstationId}|${registration.centerName}|'
        '${registration.hallName}|${registration.seatNumber}|'
        '${registration.installedAtIso}';
    final hardwareFingerprintSha256 = sha256
        .convert(utf8.encode(fingerprintSource))
        .toString();

    final baseHeader = <String, dynamic>{
      'workstationId': registration.workstationId,
      'workstationApproved': risk.workstationApproved,
      'hardwareFingerprintSha256': hardwareFingerprintSha256,
      'isNewDevice': risk.isNewWorkstation,
      'clientIp': risk.ipAddress,
      'expectedHallApiAddressRange': risk.expectedRangeLabel,
      'ipInExpectedRange': risk.ipInExpectedRange,
      'riskScore': risk.riskScore,
      'riskLevel': risk.riskLevel,
      'riskFlags': risk.reasons,
      'capturedAtIso': DateTime.now().toIso8601String(),
      'source': 'flutter+sentinel-prep',
    };

    final canonical = jsonEncode(baseHeader);
    final auditSignature = sha256.convert(utf8.encode(canonical)).toString();

    return <String, dynamic>{...baseHeader, 'auditSignature': auditSignature};
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}

class _SubmissionRiskContext {
  _SubmissionRiskContext({
    required this.registration,
    required this.riskFlagged,
    required this.reasons,
    required this.isNewWorkstation,
    required this.ipAddress,
    required this.expectedRangeLabel,
    required this.ipInExpectedRange,
    required this.riskScore,
    required this.riskLevel,
    required this.workstationApproved,
  });

  final WorkstationRegistration registration;
  final bool riskFlagged;
  final List<String> reasons;
  final bool isNewWorkstation;
  final String ipAddress;
  final String expectedRangeLabel;
  final bool ipInExpectedRange;
  final int riskScore;
  final String riskLevel;
  final bool workstationApproved;
}
