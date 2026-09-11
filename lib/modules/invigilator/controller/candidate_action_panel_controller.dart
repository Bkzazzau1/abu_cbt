import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/candidate_action_models.dart';
import '../../../data/models/checkin_models.dart';
import '../../../data/models/hall_monitor_models.dart';
import '../../../data/models/invigilator_models.dart';

class CandidateActionPanelController extends GetxController {
  final contextRecord = Rxn<CandidateActionContext>();

  final noteController = TextEditingController();
  final reassignedSeatController = TextEditingController();

  final isProcessing = false.obs;

  @override
  void onInit() {
    super.onInit();

    final arg = Get.arguments;

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
        note: '',
      );
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
  }

  Future<void> pauseExam() async {
    await _runAction(
      nextState: CandidateExamControlState.paused,
      message: 'Candidate exam paused.',
    );
  }

  Future<void> resumeExam() async {
    await _runAction(
      nextState: CandidateExamControlState.resumed,
      message: 'Candidate exam resumed.',
    );
  }

  Future<void> forceSubmit() async {
    await _runAction(
      nextState: CandidateExamControlState.forceSubmitted,
      message: 'Candidate exam force-submitted.',
    );
  }

  Future<void> allowLateEntry() async {
    await _runAction(
      nextState: CandidateExamControlState.lateEntryAllowed,
      message: 'Late entry allowed for candidate.',
    );
  }

  Future<void> reassignSeat() async {
    final current = contextRecord.value;
    if (current == null) return;

    final newSeat = reassignedSeatController.text.trim();
    if (newSeat.isEmpty) {
      Get.snackbar(
        'Missing seat number',
        'Enter the new seat number before reassigning.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isProcessing.value = true;
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      contextRecord.value = current.copyWith(
        seatNumber: newSeat,
        currentState: CandidateExamControlState.seatReassigned,
        note: noteController.text.trim(),
      );

      Get.snackbar(
        'Seat Reassigned',
        'Candidate moved to seat $newSeat.',
        snackPosition: SnackPosition.BOTTOM,
      );
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

  @override
  void onClose() {
    noteController.dispose();
    reassignedSeatController.dispose();
    super.onClose();
  }
}
