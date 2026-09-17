import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/routes/app_routes.dart';

import '../../../data/models/center_exam_models.dart';
import '../../../data/models/evidence_models.dart';
import '../../../data/models/invigilator_models.dart';
import '../../../data/models/workstation_models.dart';
import '../../../data/models/workstation_presence_models.dart';
import '../../../data/services/hall_network_risk_service.dart';
import '../../../data/services/network_health_service.dart';
import '../../../data/services/object_detection_service.dart';
import '../../../data/services/seat_question_order_service.dart';
import '../../../data/services/usb_monitor_service.dart';
import '../../../data/services/workstation_presence_ws_service.dart';
import '../../../data/services/workstation_service.dart';
import '../models/essay_answer_codec.dart';
import '../models/whiteboard_models.dart';
import '../../demo/abu_demo_theme.dart';
import '../../portal/controller/center_exam_portal_controller.dart';

class CenterExamRunController extends GetxController {
  CenterExamRunController({
    UsbMonitorService? usbMonitor,
    ObjectDetectionService? objectDetector,
    Future<HallIpRiskAssessment> Function({required String hallName})?
    assessHall,
  }) : _usbMonitor = usbMonitor ?? UsbMonitorService(),
       _objectDetector = objectDetector ?? _resolveObjectDetector(),
       _assessHall = assessHall ?? HallNetworkRiskService.assess;

  /// Reuses the detector already running for this login session (started by
  /// [CenterExamPortalController] the moment the candidate signed in) so the
  /// exam screen re-attaches to it instead of opening the camera a second
  /// time. Falls back to a standalone instance when there's no portal
  /// session (e.g. practice mode).
  static ObjectDetectionService _resolveObjectDetector() =>
      Get.isRegistered<CenterExamPortalController>()
      ? Get.find<CenterExamPortalController>().objectDetector
      : ObjectDetectionService();

  final UsbMonitorService _usbMonitor;
  final ObjectDetectionService _objectDetector;
  final objectDetectionStatus = 'Inactive'.obs;
  final objectDetectionFlags = <String>[].obs;
  Future<void> _objectAuditWrite = Future<void>.value();
  String _objectAuditKey = '';
  List<String> get _monitorFlags => [...usbFlags, ...objectDetectionFlags];
  final Future<HallIpRiskAssessment> Function({required String hallName})
  _assessHall;
  final usbFlags = <String>[].obs;
  Timer? _presenceTimer;
  bool _presenceBusy = false;
  bool _endingExam = false;
  Future<void> _usbAuditWrite = Future<void>.value();
  String _usbAuditKey = '';
  WorkstationRegistration? _registration;
  StreamSubscription<WorkstationPresenceEnvelope>? _commandSub;
  final exam = Rxn<CenterExam>();
  final isLoadingExam = false.obs;
  final examLoadError = ''.obs;

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
      unawaited(_prepareExam(payload));
    }
  }

  Future<void> _prepareExam(CenterExam payload) async {
    isLoadingExam.value = true;
    try {
      final candidate = Get.isRegistered<CenterExamPortalController>()
          ? Get.find<CenterExamPortalController>().candidate.value
          : null;
      final registration = candidate == null
          ? await WorkstationService.loadOrCreate()
          : await WorkstationService.ensureAssignmentFromAttendance(
              candidateRegistrationNumber: candidate.registrationNumber,
            );
      if (isClosed) return;
      _registration = registration;
      if (payload.questions.isEmpty) {
        examLoadError.value = 'This exam has no questions.';
        return;
      }
      exam.value = SeatQuestionOrderService.forSeat(
        payload,
        registration.seatNumber,
      );
      secondsLeft.value = payload.durationMinutes * 60;
      _syncCurrentAnswer();
      _markSaved();
      _usbAuditKey =
          'usb.audit.${registration.workstationId}.${payload.id}.'
          '${DateTime.now().microsecondsSinceEpoch}';
      await _usbMonitor.start(_recordUsbFlag);
      _objectAuditKey = _usbAuditKey.replaceFirst(
        'usb.audit.',
        'objects.audit.',
      );
      // Monitoring normally already started at login (see
      // CenterExamPortalController), so this call just re-attaches
      // exam-scoped flag/audit/popup handling onto the running process —
      // the reference photo/duration below only matter as a fallback if it
      // wasn't already running (e.g. no portal session, as in practice mode).
      final referencePhotoPath = candidate == null
          ? null
          : Get.isRegistered<CenterExamPortalController>()
          ? Get.find<CenterExamPortalController>().referencePhotoPath
          : null;
      await _objectDetector.start(
        _recordObjectFlag,
        onStatus: (status) {
          if (!isClosed) objectDetectionStatus.value = status;
        },
        onEvidence: _handleEvidenceDetected,
        referencePhotoPath: referencePhotoPath,
        durationSeconds: payload.durationMinutes * 60,
      );
      if (isClosed) {
        _usbMonitor.stop();
        await _stopObjectDetection();
        return;
      }
      await _listenForInvigilatorCommands();
      if (isClosed) return;
      _startTimer();
      unawaited(_emitInExamHeartbeat());
      _presenceTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        unawaited(_emitInExamHeartbeat());
      });
    } catch (_) {
      if (!isClosed) {
        examLoadError.value =
            'Unable to load the seat assignment. Go back and try again.';
      }
    } finally {
      if (!isClosed) isLoadingExam.value = false;
    }
  }

  void _recordUsbFlag(String flag) {
    // Bound live telemetry. The final entry explicitly indicates truncation.
    if (usbFlags.length < 100) {
      usbFlags.add(flag);
    } else {
      usbFlags[99] =
          'USB event limit reached; further connections require officer review.';
    }
    if (_usbAuditKey.isNotEmpty) {
      final snapshot = List<String>.of(usbFlags);
      _usbAuditWrite = _usbAuditWrite
          .then((_) async {
            final prefs = await SharedPreferences.getInstance();
            final saved = await prefs.setStringList(_usbAuditKey, snapshot);
            if (!saved) throw StateError('USB audit write failed');
          })
          .catchError((Object _) {
            const failure = 'USB audit could not be saved locally.';
            if (!usbFlags.contains(failure)) usbFlags.add(failure);
          });
    }
    if (!_endingExam && !isClosed && exam.value != null) {
      unawaited(_emitInExamHeartbeat());
    }
    // A connected/removable device is a plain fact, not a model score, so
    // it's reported as evidence without a confidence value — only the
    // genuine "device connected" case counts as evidence; monitor
    // diagnostics (unavailable, buffer overflow, unreadable event) aren't.
    if (flag.startsWith('USB device connected')) {
      unawaited(
        _reportEvidence(
          evidenceType: EvidenceType.usb,
          details: flag,
          capturedAt: DateTime.now(),
        ),
      );
    }
  }

  void _recordObjectFlag(String flag) {
    if (objectDetectionFlags.length < 100) {
      objectDetectionFlags.add(flag);
    } else {
      objectDetectionFlags[99] =
          'Object detection event limit reached; officer review required.';
    }
    if (_objectAuditKey.isNotEmpty) {
      final snapshot = List<String>.of(objectDetectionFlags);
      _objectAuditWrite = _objectAuditWrite
          .then((_) async {
            final prefs = await SharedPreferences.getInstance();
            if (!await prefs.setStringList(_objectAuditKey, snapshot)) {
              throw StateError('Object detection audit write failed');
            }
          })
          .catchError((Object _) {
            const failure =
                'Object detection audit could not be saved locally.';
            if (!objectDetectionFlags.contains(failure)) {
              objectDetectionFlags.add(failure);
            }
          });
    }
    if (!_endingExam && !isClosed && exam.value != null) {
      unawaited(_emitInExamHeartbeat());
    }
  }

  bool _phoneAlertShowing = false;

  /// Called whenever the local detector flags anything — phone, identity
  /// mismatch, or elevated talking. Every kind is reported as structured
  /// evidence for the invigilator dashboard; only a phone also interrupts
  /// the candidate with an on-screen warning, since that's the one flag a
  /// candidate can actually act on immediately (put it away). Identity/
  /// talking flags need an invigilator's in-room judgment, not a popup the
  /// candidate could game by knowing exactly when they were flagged.
  void _handleEvidenceDetected({
    required String evidenceType,
    double? confidence,
    required String details,
    required DateTime capturedAt,
  }) {
    unawaited(
      _reportEvidence(
        evidenceType: evidenceType,
        confidence: confidence,
        details: details,
        capturedAt: capturedAt,
      ),
    );
    if (evidenceType == EvidenceType.phone) {
      _showPhoneDetectedAlert();
    }
  }

  /// Interrupts the candidate immediately when a phone is detected, on top
  /// of the flag already recorded for the invigilator — a deterrent shown
  /// in the moment, not just a note reviewed after the fact. Guarded so a
  /// second detection during the 30s detector cooldown can't stack dialogs.
  void _showPhoneDetectedAlert() {
    if (isClosed || _endingExam || _phoneAlertShowing) return;
    _phoneAlertShowing = true;
    Get.dialog(
      Theme(
        data: abuDemoTheme(),
        child: AlertDialog(
          icon: const Icon(
            Icons.phonelink_erase_outlined,
            color: Colors.red,
            size: 32,
          ),
          title: const Text('Phone detected'),
          content: const SizedBox(
            width: 420,
            child: Text(
              'The camera detected a possible phone at your seat. Put it away '
              'immediately — this has been flagged to the invigilator for review.',
              style: TextStyle(height: 1.7),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                _phoneAlertShowing = false;
                Get.back();
              },
              child: const Text('I understand'),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _reportEvidence({
    required String evidenceType,
    double? confidence,
    required String details,
    required DateTime capturedAt,
  }) async {
    final registration = _registration;
    if (registration == null) return;
    final candidate = Get.isRegistered<CenterExamPortalController>()
        ? Get.find<CenterExamPortalController>().candidate.value
        : null;
    final examValue = exam.value;

    final wsService = Get.isRegistered<WorkstationPresenceWsService>()
        ? Get.find<WorkstationPresenceWsService>()
        : Get.put(WorkstationPresenceWsService());
    await wsService.connectWorkstation();
    wsService.sendEvidenceEvent(
      workstationId: registration.workstationId,
      centerName: registration.centerName,
      hallName: registration.hallName,
      seatNumber: registration.seatNumber,
      registrationNumber: candidate?.registrationNumber ?? '',
      candidateName: candidate?.fullName ?? '',
      examTitle: examValue == null
          ? ''
          : '${examValue.courseCode} - ${examValue.courseTitle}',
      evidenceType: evidenceType,
      confidence: confidence,
      details: details,
      detectedAtIso: capturedAt.toIso8601String(),
    );
  }

  /// Subscribes to inbound messages on this candidate's own workstation
  /// socket so an invigilator's "Terminate Exam" action (pushed as a
  /// `command` message targeted at this one connection — see
  /// backend/workstation_heartbeat_service) can end the exam immediately
  /// rather than only being visible after the fact.
  Future<void> _listenForInvigilatorCommands() async {
    final wsService = Get.isRegistered<WorkstationPresenceWsService>()
        ? Get.find<WorkstationPresenceWsService>()
        : Get.put(WorkstationPresenceWsService());
    await wsService.connectWorkstation();
    if (isClosed) return;
    _commandSub = wsService.incoming.listen(_handleIncomingCommand);
  }

  void _handleIncomingCommand(WorkstationPresenceEnvelope envelope) {
    if (envelope.kind != 'command') return;
    if (envelope.commandAction != 'terminate_exam') return;
    _handleTerminatedByInvigilator(envelope.commandReason ?? '');
  }

  /// Ends the exam immediately on the invigilator's command, distinct from
  /// the candidate's own timer/submit flow. Reuses the existing flag/audit
  /// pipeline (`_recordObjectFlag`) so the reason flows into the same
  /// heartbeat/risk-reasons trail already sent to the invigilator, rather
  /// than needing a parallel path.
  void _handleTerminatedByInvigilator(String reason) {
    if (isClosed || isSubmitted.value || _endingExam) return;
    _timer?.cancel();
    _recordObjectFlag(
      'Exam terminated by invigilator'
      '${reason.trim().isEmpty ? '' : ': ${reason.trim()}'}.',
    );
    Get.dialog(
      Theme(
        data: abuDemoTheme(),
        child: AlertDialog(
          icon: const Icon(Icons.gpp_bad_outlined, color: Colors.red, size: 32),
          title: const Text('Exam terminated by invigilator'),
          content: SizedBox(
            width: 420,
            child: Text(
              reason.trim().isEmpty
                  ? 'Your invigilator has ended this exam. Your responses so '
                        'far have been submitted for review.'
                  : 'Your invigilator has ended this exam: ${reason.trim()}\n\n'
                        'Your responses so far have been submitted for review.',
              style: const TextStyle(height: 1.7),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () async {
                Get.back();
                await _finalizeSubmission(autoSubmitted: true);
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Ends this screen's involvement with detection. When a portal session
  /// owns the detector (started at login), monitoring must keep running for
  /// the rest of the candidate's time at the workstation, so this only
  /// detaches this screen's callbacks; otherwise (e.g. practice mode, with
  /// its own standalone instance) it stops the process outright.
  Future<void> _stopObjectDetection() async {
    objectDetectionStatus.value = 'Stopped';
    if (Get.isRegistered<CenterExamPortalController>()) {
      _objectDetector.detach();
    } else {
      await _objectDetector.stop();
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
    _usbMonitor.stop();
    unawaited(_stopObjectDetection());
    _timeUpDialogShown = true;
    Get.dialog(
      Theme(
        data: abuDemoTheme(),
        child: AlertDialog(
          icon: const Icon(Icons.timer_off_outlined, color: abuGreen, size: 32),
          title: const Text('Your practice time has ended'),
          content: const SizedBox(
            width: 420,
            child: Text(
              'Your responses are ready to submit. Continue to finish this session and view your practice summary.',
              style: TextStyle(height: 1.7),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () async {
                Get.back();
                await _finalizeSubmission(autoSubmitted: true);
              },
              child: const Text('View my summary'),
            ),
          ],
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
    Get.dialog(
      Theme(
        data: abuDemoTheme(),
        child: AlertDialog(
          title: const Text('Finish this practice session?'),
          content: SizedBox(
            width: 420,
            child: Text(
              'You have answered ${totalQuestions - unansweredCount} of $totalQuestions questions. '
              'After submission, your responses cannot be changed. You can start a new practice attempt at any time.',
              style: const TextStyle(height: 1.7),
            ),
          ),
          actions: [
            TextButton(onPressed: Get.back, child: const Text('Keep working')),
            FilledButton(
              onPressed: () async {
                Get.back();
                await _finalizeSubmission(autoSubmitted: false);
              },
              child: const Text('Submit practice'),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _finalizeSubmission({required bool autoSubmitted}) async {
    if (isSubmitted.value || _endingExam) return;
    final examValue = exam.value;
    if (examValue == null) return;
    if (_phoneAlertShowing) {
      _phoneAlertShowing = false;
      Get.back();
    }
    _endingExam = true;
    _presenceTimer?.cancel();
    _usbMonitor.stop();
    await _stopObjectDetection();
    await _usbAuditWrite;
    await _objectAuditWrite;
    final risk = await _assessSubmissionRisk();
    await _emitUsageHeartbeat(
      WorkstationUsageState.submitted,
      registrationOverride: risk.registration,
      riskContext: risk,
    );
    await _submitAnswersForIntegrityCheck(examValue, risk);

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
        // A count only, not the flag text itself — the specifics (what was
        // detected, when) belong on the invigilator dashboard for review,
        // not on the candidate's own receipt.
        'monitorFlagCount': _monitorFlags.length,
      },
    );
    await WorkstationService.markSubmission(risk.registration.workstationId);
  }

  /// Sends each free-text answer to the backend at submission time so the
  /// Python AI service can compare it against the rest of the hall's
  /// answers for that question and flag likely collusion. Objective
  /// (multiple-choice/drag-drop) answers carry no text and are skipped.
  Future<void> _submitAnswersForIntegrityCheck(
    CenterExam examValue,
    _SubmissionRiskContext risk,
  ) async {
    final textAnswers = answers.values.where(
      (a) => (a.textAnswer ?? '').trim().isNotEmpty,
    );
    if (textAnswers.isEmpty) return;

    final wsService = Get.isRegistered<WorkstationPresenceWsService>()
        ? Get.find<WorkstationPresenceWsService>()
        : Get.put(WorkstationPresenceWsService());
    await wsService.connectWorkstation();

    final candidate = Get.isRegistered<CenterExamPortalController>()
        ? Get.find<CenterExamPortalController>().candidate.value
        : null;
    final questionTypes = <String, CenterQuestionType>{
      for (final q in examValue.questions) q.id: q.type,
    };

    for (final answer in textAnswers) {
      // Essay answers are stored as Quill Delta JSON (rich formatting) —
      // the similarity check must compare actual words, not markup, or
      // two candidates with identical text but different formatting (or
      // vice versa) would be scored on JSON structure instead of content.
      final isEssay =
          questionTypes[answer.questionId] == CenterQuestionType.essay;
      final text = isEssay
          ? essayAnswerToPlainText(answer.textAnswer!)
          : answer.textAnswer!.trim();
      if (text.isEmpty) continue;

      wsService.sendAnswerSubmission(
        registrationNumber: candidate?.registrationNumber ?? '',
        candidateName: candidate?.fullName ?? '',
        hallName: risk.registration.hallName,
        seatNumber: risk.registration.seatNumber,
        examId: examValue.id,
        questionId: answer.questionId,
        textAnswer: text,
      );
    }
  }

  Future<void> _emitInExamHeartbeat() async {
    if (_presenceBusy || _endingExam || isClosed) return;
    _presenceBusy = true;
    try {
      final risk = await _assessSubmissionRisk();
      await _emitUsageHeartbeat(
        WorkstationUsageState.inExam,
        registrationOverride: risk.registration,
        riskContext: risk,
      );
    } catch (_) {
      // The next periodic heartbeat retries without interrupting the exam.
    } finally {
      _presenceBusy = false;
    }
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
      if (state == WorkstationUsageState.inExam && (_endingExam || isClosed)) {
        return;
      }

      final candidate = Get.isRegistered<CenterExamPortalController>()
          ? Get.find<CenterExamPortalController>().candidate.value
          : null;

      final examValue = exam.value;
      wsService.sendHeartbeat(
        WorkstationPresenceRecord(
          workstationId: registration.workstationId,
          centerName: registration.centerName.isEmpty
              ? 'ABU'
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
              _monitorFlags.isNotEmpty ||
              (riskContext?.riskFlagged ??
                  registration.status != WorkstationStatus.whitelisted),
          isNewWorkstation: riskContext?.isNewWorkstation ?? false,
          clientIpAddress: riskContext?.ipAddress ?? '',
          expectedHallIpRange: riskContext?.expectedRangeLabel ?? '',
          ipInExpectedRange: riskContext?.ipInExpectedRange ?? true,
          riskReasons: {...?riskContext?.reasons, ..._monitorFlags}.toList(),
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

    final ipAssessment = await _assessHall(hallName: registration.hallName);

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

    reasons.addAll(_monitorFlags);
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
    _endingExam = true;
    _presenceTimer?.cancel();
    _commandSub?.cancel();
    _usbMonitor.stop();
    unawaited(_stopObjectDetection());
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
