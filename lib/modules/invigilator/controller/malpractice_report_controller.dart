import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/checkin_models.dart';
import '../../../data/models/hall_monitor_models.dart';
import '../../../data/models/invigilator_models.dart';
import '../../../data/models/malpractice_models.dart';

class MalpracticeReportController extends GetxController {
  final candidateName = ''.obs;
  final registrationNumber = ''.obs;
  final workstationId = ''.obs;
  final hallName = ''.obs;
  final seatNumber = ''.obs;
  final examTitle = ''.obs;

  final selectedType = MalpracticeType.suspiciousBehavior.obs;
  final selectedSeverity = MalpracticeSeverity.major.obs;
  final isSubmitting = false.obs;

  final descriptionController = TextEditingController();
  final actionTakenController = TextEditingController();

  @override
  void onInit() {
    super.onInit();

    final arg = Get.arguments;

    if (arg is InvigilatorWorkstationRecord) {
      candidateName.value = arg.candidateName;
      registrationNumber.value = arg.registrationNumber;
      workstationId.value = arg.workstationId;
      hallName.value = arg.hallName;
      seatNumber.value = arg.seatNumber;
      examTitle.value = arg.examTitle;
      return;
    }

    if (arg is CandidateCheckInRecord) {
      candidateName.value = arg.candidateName;
      registrationNumber.value = arg.registrationNumber;
      workstationId.value = arg.workstationId;
      hallName.value = arg.hallName;
      seatNumber.value = arg.seatNumber;
      examTitle.value = arg.examTitle;
      return;
    }

    if (arg is HallMonitorRecord) {
      candidateName.value = arg.candidateName;
      registrationNumber.value = arg.registrationNumber;
      workstationId.value = arg.workstationId;
      hallName.value = arg.hallName;
      seatNumber.value = arg.seatNumber;
      examTitle.value = arg.examTitle;
      return;
    }
  }

  void setType(MalpracticeType type) {
    selectedType.value = type;
  }

  void setSeverity(MalpracticeSeverity severity) {
    selectedSeverity.value = severity;
  }

  Future<void> submit() async {
    if (isSubmitting.value) return;

    final description = descriptionController.text.trim();
    final actionTaken = actionTakenController.text.trim();

    if (description.isEmpty) {
      Get.snackbar(
        'Missing description',
        'Please describe the malpractice incident.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (actionTaken.isEmpty) {
      Get.snackbar(
        'Missing action',
        'Please state the action taken by the invigilator.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isSubmitting.value = true;
    try {
      final report = MalpracticeReportModel(
        workstationId: workstationId.value,
        hallName: hallName.value,
        seatNumber: seatNumber.value,
        candidateName: candidateName.value,
        registrationNumber: registrationNumber.value,
        examTitle: examTitle.value,
        type: selectedType.value,
        severity: selectedSeverity.value,
        description: description,
        actionTaken: actionTaken,
        reportedAtIso: DateTime.now().toIso8601String(),
      );

      await Future.delayed(const Duration(milliseconds: 700));

      Get.snackbar(
        'Malpractice Report Submitted',
        'Malpractice report logged successfully (${report.type.name}).',
        snackPosition: SnackPosition.BOTTOM,
      );

      Get.back(result: report);
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    descriptionController.dispose();
    actionTakenController.dispose();
    super.onClose();
  }
}
