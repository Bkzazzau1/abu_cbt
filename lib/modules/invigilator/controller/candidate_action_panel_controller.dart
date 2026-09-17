import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/candidate_action_models.dart';
import '../../../data/models/checkin_models.dart';
import '../../../data/models/hall_monitor_models.dart';
import '../../../data/models/invigilator_models.dart';
import '../../../data/models/seat_map_models.dart';
import '../../../data/services/invigilator_demo_store.dart';

class CandidateActionPanelController extends GetxController {
  final contextRecord = Rxn<CandidateActionContext>();
  final noteController = TextEditingController();
  final isProcessing = false.obs;

  final selectedDestinationSeat = ''.obs;
  final selectedReassignmentReason = Rxn<SeatReassignmentReason>();
  final lastSeatReassignment = Rxn<SeatReassignmentRecord>();

  late final InvigilatorDemoStore _demoStore;

  @override
  void onInit() {
    super.onInit();
    _demoStore = Get.isRegistered<InvigilatorDemoStore>()
        ? Get.find<InvigilatorDemoStore>()
        : Get.put(InvigilatorDemoStore(), permanent: true);

    _buildContext(Get.arguments);
    _prepareSeatReassignment();
  }

  void _buildContext(dynamic arg) {
    if (arg is InvigilatorWorkstationRecord) {
      contextRecord.value = CandidateActionContext(
        workstationId: arg.workstationId,
        hallName: arg.hallName,
        seatNumber: arg.seatNumber,
        candidateName: arg.candidateName,
        registrationNumber: arg.registrationNumber,
        examTitle: arg.examTitle,
        currentState: CandidateExamControlState.normal,
        note: '',
      );
      return;
    }

    if (arg is CandidateCheckInRecord) {
      contextRecord.value = CandidateActionContext(
        workstationId: arg.workstationId,
        hallName: arg.hallName,
        seatNumber: arg.seatNumber,
        candidateName: arg.candidateName,
        registrationNumber: arg.registrationNumber,
        examTitle: arg.examTitle,
        currentState: CandidateExamControlState.normal,
        note: arg.note,
      );
      noteController.text = arg.note;
      return;
    }

    if (arg is HallMonitorRecord) {
      contextRecord.value = CandidateActionContext(
        workstationId: arg.workstationId,
        hallName: arg.hallName,
        seatNumber: arg.seatNumber,
        candidateName: arg.candidateName,
        registrationNumber: arg.registrationNumber,
        examTitle: arg.examTitle,
        currentState: CandidateExamControlState.normal,
        note: '',
      );
      return;
    }

    if (arg is CandidateActionContext) {
      contextRecord.value = arg;
      noteController.text = arg.note;
    }
  }

  Future<void> _prepareSeatReassignment() async {
    await _demoStore.ensureLoaded();
    final current = contextRecord.value;
    if (current == null || current.registrationNumber.isEmpty) return;
    lastSeatReassignment.value =
        _demoStore.latestReassignmentFor(current.registrationNumber);
  }

  List<SeatMapRecord> get availableDestinationSeats {
    final current = contextRecord.value;
    if (current == null) return const [];
    return _demoStore.availableSeatsForHall(current.hallName);
  }

  SeatMapRecord? get selectedDestinationRecord {
    final current = contextRecord.value;
    final selected = selectedDestinationSeat.value;
    if (current == null || selected.isEmpty) return null;
    return _demoStore.findSeat(current.hallName, selected);
  }

  CandidateExamControlState? get currentState => contextRecord.value?.currentState;
  bool get isExamPaused => currentState == CandidateExamControlState.paused;
  bool get isForceSubmitted =>
      currentState == CandidateExamControlState.forceSubmitted;

  bool get canPauseExam =>
      !isProcessing.value && !isExamPaused && !isForceSubmitted;
  bool get canResumeExam =>
      !isProcessing.value && isExamPaused && !isForceSubmitted;
  bool get canAllowLateEntry => !isProcessing.value && !isForceSubmitted;
  bool get canForceSubmit => !isProcessing.value && !isForceSubmitted;

  bool get canReassignSeat =>
      !isProcessing.value &&
      !isForceSubmitted &&
      selectedDestinationSeat.value.isNotEmpty &&
      selectedReassignmentReason.value != null;

  void selectDestinationSeat(String? value) {
    selectedDestinationSeat.value = value ?? '';
  }

  void selectReassignmentReason(SeatReassignmentReason? value) {
    selectedReassignmentReason.value = value;
  }

  Future<void> pauseExam() async {
    if (!canPauseExam) {
      _showControlError(
        isForceSubmitted
            ? 'This exam has already been submitted.'
            : 'The candidate exam is already paused.',
      );
      return;
    }
    await _runAction(
      nextState: CandidateExamControlState.paused,
      message: 'Candidate exam paused.',
    );
  }

  Future<void> resumeExam() async {
    if (!canResumeExam) {
      _showControlError(
        isForceSubmitted
            ? 'A submitted exam cannot be resumed.'
            : 'Pause the candidate exam before using Resume.',
      );
      return;
    }
    await _runAction(
      nextState: CandidateExamControlState.resumed,
      message: 'Candidate exam resumed.',
    );
  }

  Future<void> forceSubmit() async {
    if (!canForceSubmit) {
      _showControlError('This exam has already been submitted.');
      return;
    }
    await _runAction(
      nextState: CandidateExamControlState.forceSubmitted,
      message: 'Candidate exam force-submitted.',
    );
  }

  Future<void> allowLateEntry() async {
    if (!canAllowLateEntry) {
      _showControlError('Late entry cannot be enabled after submission.');
      return;
    }
    await _runAction(
      nextState: CandidateExamControlState.lateEntryAllowed,
      message: 'Late entry allowed for candidate.',
    );
  }

  Future<bool> reassignSeat() async {
    final current = contextRecord.value;
    final newSeat = selectedDestinationSeat.value.trim();
    final reason = selectedReassignmentReason.value;

    if (current == null) return false;
    if (isForceSubmitted) {
      _showError('A submitted candidate cannot be moved to another seat.');
      return false;
    }
    if (newSeat.isEmpty) {
      _showError('Select an available destination seat.');
      return false;
    }
    if (reason == null) {
      _showError('Select the reason for this seat reassignment.');
      return false;
    }
    if (reason == SeatReassignmentReason.other &&
        noteController.text.trim().isEmpty) {
      _showError('Add an invigilator note when the reason is Other.');
      return false;
    }

    isProcessing.value = true;
    try {
      final event = await _demoStore.reassignSeat(
        candidate: current,
        destinationSeatNumber: newSeat,
        reason: reason,
        note: noteController.text.trim(),
      );

      contextRecord.value = current.copyWith(
        workstationId: event.newWorkstationId,
        seatNumber: event.newSeatNumber,
        currentState: CandidateExamControlState.seatReassigned,
        note: noteController.text.trim(),
      );
      lastSeatReassignment.value = event;
      selectedDestinationSeat.value = '';
      selectedReassignmentReason.value = null;

      Get.snackbar(
        'Seat Reassigned',
        '${event.candidateName} moved from ${event.oldSeatNumber} to '
        '${event.newSeatNumber}. Exam context preserved.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } on StateError catch (error) {
      _showError(error.message.toString());
      return false;
    } catch (_) {
      _showError('The seat could not be reassigned. Please try again.');
      return false;
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> _runAction({
    required CandidateExamControlState nextState,
    required String message,
  }) async {
    final current = contextRecord.value;
    if (current == null) return;

    isProcessing.value = true;
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      contextRecord.value = current.copyWith(
        currentState: nextState,
        note: noteController.text.trim(),
      );

      Get.snackbar(
        'Action Completed',
        message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isProcessing.value = false;
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'Seat Reassignment',
      message,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _showControlError(String message) {
    Get.snackbar(
      'Candidate Controls',
      message,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  void onClose() {
    noteController.dispose();
    super.onClose();
  }
}
