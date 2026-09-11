import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/checkin_models.dart';
import '../../../data/models/hall_monitor_models.dart';
import '../../../data/models/invigilator_models.dart';

class CandidateCheckInController extends GetxController {
  final record = Rxn<CandidateCheckInRecord>();
  final notesController = TextEditingController();

  @override
  void onInit() {
    super.onInit();

    final arg = Get.arguments;
    if (arg is InvigilatorWorkstationRecord) {
      record.value = CandidateCheckInRecord(
        workstationId: arg.workstationId,
        hallName: arg.hallName,
        seatNumber: arg.seatNumber,
        candidateName: arg.candidateName,
        registrationNumber: arg.registrationNumber,
        examTitle: arg.examTitle,
        status: CandidateCheckInStatus.pending,
        note: '',
      );
      notesController.text = '';
    }

    if (arg is HallMonitorRecord) {
      record.value = CandidateCheckInRecord(
        workstationId: arg.workstationId,
        hallName: arg.hallName,
        seatNumber: arg.seatNumber,
        candidateName: arg.candidateName,
        registrationNumber: arg.registrationNumber,
        examTitle: arg.examTitle,
        status: CandidateCheckInStatus.pending,
        note: '',
      );
      notesController.text = '';
    }
  }

  void markCheckedIn() {
    final current = record.value;
    if (current == null) return;
    record.value = current.copyWith(
      status: CandidateCheckInStatus.checkedIn,
      note: notesController.text.trim(),
    );
    Get.snackbar(
      'Checked In',
      'Candidate marked as checked in.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void authorize() {
    final current = record.value;
    if (current == null) return;
    record.value = current.copyWith(
      status: CandidateCheckInStatus.authorized,
      note: notesController.text.trim(),
    );
    Get.snackbar(
      'Authorized',
      'Candidate authorized to proceed.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void markAbsent() {
    final current = record.value;
    if (current == null) return;
    record.value = current.copyWith(
      status: CandidateCheckInStatus.absent,
      note: notesController.text.trim(),
    );
    Get.snackbar(
      'Absent',
      'Candidate marked as absent.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void flagIssue() {
    final current = record.value;
    if (current == null) return;
    record.value = current.copyWith(
      status: CandidateCheckInStatus.issueFlagged,
      note: notesController.text.trim(),
    );
    Get.snackbar(
      'Issue Flagged',
      'Candidate check-in issue has been flagged.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  void onClose() {
    notesController.dispose();
    super.onClose();
  }
}
