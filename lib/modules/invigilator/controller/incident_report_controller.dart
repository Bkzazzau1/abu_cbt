import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/checkin_models.dart';
import '../../../data/models/hall_monitor_models.dart';
import '../../../data/models/incident_models.dart';
import '../../../data/models/invigilator_models.dart';
import '../../../data/services/invigilator_session.dart';

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
  final actionTakenController = TextEditingController();
  final evidenceController = TextEditingController();

  bool get hasCandidateContext =>
      candidateName.value.isNotEmpty || registrationNumber.value.isNotEmpty;

  bool get isHighPriority =>
      selectedSeverity.value == IncidentSeverity.high ||
      selectedSeverity.value == IncidentSeverity.critical;

  @override
  void onInit() {
    super.onInit();
    _readContext(Get.arguments);
  }

  void _readContext(dynamic arg) {
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
      if (arg.needsAttention) {
        selectedType.value = IncidentType.identityMismatch;
        selectedSeverity.value = IncidentSeverity.high;
        descriptionController.text = arg.note;
      }
      return;
    }

    if (arg is HallMonitorRecord) {
      candidateName.value = arg.candidateName;
      registrationNumber.value = arg.registrationNumber;
      workstationId.value = arg.workstationId;
      hallName.value = arg.hallName;
      seatNumber.value = arg.seatNumber;
      examTitle.value = arg.examTitle;
      if (arg.state == HallCandidateLiveState.offline) {
        selectedType.value = IncidentType.technicalIssue;
      }
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
    final actionTaken = actionTakenController.text.trim();
    final evidenceNote = evidenceController.text.trim();

    if (description.isEmpty) {
      Get.snackbar(
        'What happened?',
        'Add a short factual description of the incident.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (actionTaken.isEmpty) {
      Get.snackbar(
        'Action required',
        'Record what the invigilator or support team did in response.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isSubmitting.value = true;
    try {
      final now = DateTime.now();
      final report = IncidentReportModel(
        id: 'INC-${now.millisecondsSinceEpoch}',
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
        evidenceNote: evidenceNote,
        reportedBy: InvigilatorSession.currentName.isEmpty
            ? 'Invigilator'
            : InvigilatorSession.currentName,
        reportedAtIso: now.toIso8601String(),
      );

      await Future.delayed(const Duration(milliseconds: 350));

      Get.snackbar(
        'Incident Recorded',
        '${report.id} saved successfully.',
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
    evidenceController.dispose();
    super.onClose();
  }
}
