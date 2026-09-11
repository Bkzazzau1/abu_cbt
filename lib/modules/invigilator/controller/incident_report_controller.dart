import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/checkin_models.dart';
import '../../../data/models/hall_monitor_models.dart';
import '../../../data/models/incident_models.dart';
import '../../../data/models/invigilator_models.dart';

class IncidentReportController extends GetxController {
  final candidateName = ''.obs;
  final registrationNumber = ''.obs;
  final workstationId = ''.obs;
  final hallName = ''.obs;
  final seatNumber = ''.obs;
  final examTitle = ''.obs;

  final selectedType = IncidentType.technicalIssue.obs;
  final selectedSeverity = IncidentSeverity.medium.obs;
  final isSubmitting = false.obs;

  final descriptionController = TextEditingController();

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

  void setType(IncidentType type) {
    selectedType.value = type;
  }

  void setSeverity(IncidentSeverity severity) {
    selectedSeverity.value = severity;
  }

  Future<void> submit() async {
    if (isSubmitting.value) return;

    final description = descriptionController.text.trim();
    if (description.isEmpty) {
      Get.snackbar(
        'Missing description',
        'Please provide incident details before submitting.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isSubmitting.value = true;
    try {
      final report = IncidentReportModel(
        workstationId: workstationId.value,
        hallName: hallName.value,
        seatNumber: seatNumber.value,
        candidateName: candidateName.value,
        registrationNumber: registrationNumber.value,
        examTitle: examTitle.value,
        type: selectedType.value,
        severity: selectedSeverity.value,
        description: description,
        reportedAtIso: DateTime.now().toIso8601String(),
      );

      await Future.delayed(const Duration(milliseconds: 600));

      Get.snackbar(
        'Incident Reported',
        'Incident logged successfully '
            '(${report.type.name}, ${report.severity.name}).',
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
    super.onClose();
  }
}
