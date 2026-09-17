import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/checkin_models.dart';
import '../../../data/models/hall_monitor_models.dart';
import '../../../data/models/invigilator_models.dart';
import '../../../data/models/evidence_models.dart';
import '../../../data/models/malpractice_models.dart';
import '../../../data/services/invigilator_session.dart';
import '../../../data/services/workstation_presence_ws_service.dart';

class MalpracticeReportController extends GetxController {
  final candidateName = ''.obs;
  final registrationNumber = ''.obs;
  final workstationId = ''.obs;
  final centerName = ''.obs;
  final hallName = ''.obs;
  final seatNumber = ''.obs;
  final examTitle = ''.obs;

  final selectedType = MalpracticeType.suspiciousBehavior.obs;
  final selectedSeverity = MalpracticeSeverity.major.obs;
  final isSubmitting = false.obs;
  final sourceEvidenceLabel = ''.obs;

  final descriptionController = TextEditingController();
  final actionTakenController = TextEditingController();
  final evidenceController = TextEditingController();

  bool get isHighPriority =>
      selectedSeverity.value == MalpracticeSeverity.severe ||
      selectedSeverity.value == MalpracticeSeverity.critical;

  bool get hasSupportingEvidence => sourceEvidenceLabel.value.isNotEmpty;

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
      centerName.value = arg.centerName;
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

    if (arg is EvidenceEvent) {
      candidateName.value = arg.candidateName;
      registrationNumber.value = arg.registrationNumber;
      workstationId.value = arg.workstationId;
      centerName.value = arg.centerName;
      hallName.value = arg.hallName;
      seatNumber.value = arg.seatNumber;
      examTitle.value = arg.examTitle;
      selectedType.value = _defaultTypeFor(arg.evidenceType);
      selectedSeverity.value = MalpracticeSeverity.major;

      final confidenceText = arg.confidence != null
          ? '${(arg.confidence! * 100).round()}% confidence'
          : 'confidence unavailable';
      sourceEvidenceLabel.value = 'Local detection • $confidenceText';
      evidenceController.text =
          '${arg.details.isEmpty ? _evidenceTypeLabel(arg.evidenceType) : arg.details}. '
          'Detected at ${arg.detectedAtIso}. This is supporting evidence only and requires invigilator review.';
    }
  }

  MalpracticeType _defaultTypeFor(String evidenceType) {
    switch (evidenceType) {
      case EvidenceType.phone:
        return MalpracticeType.phoneUse;
      case EvidenceType.identity:
        return MalpracticeType.impersonation;
      case EvidenceType.talking:
        return MalpracticeType.talking;
      case EvidenceType.usb:
        return MalpracticeType.unauthorizedMaterial;
      default:
        return MalpracticeType.suspiciousBehavior;
    }
  }

  String _evidenceTypeLabel(String evidenceType) {
    switch (evidenceType) {
      case EvidenceType.phone:
        return 'Possible phone detected';
      case EvidenceType.identity:
        return 'Possible identity mismatch detected';
      case EvidenceType.talking:
        return 'Elevated talking detected';
      case EvidenceType.usb:
        return 'Unauthorized USB event detected';
      default:
        return 'Detection event';
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
    final evidenceNote = evidenceController.text.trim();

    if (description.isEmpty) {
      Get.snackbar(
        'Observation required',
        'Record what the invigilator actually observed before submitting.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (actionTaken.isEmpty) {
      Get.snackbar(
        'Action required',
        'Record the immediate action taken by the invigilator.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isSubmitting.value = true;
    try {
      final now = DateTime.now();
      final report = MalpracticeReportModel(
        id: 'MAL-${now.millisecondsSinceEpoch}',
        workstationId: workstationId.value,
        centerName: centerName.value.isEmpty ? 'ABU' : centerName.value,
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

      final wsService = Get.isRegistered<WorkstationPresenceWsService>()
          ? Get.find<WorkstationPresenceWsService>()
          : Get.put(WorkstationPresenceWsService());
      wsService.sendMalpracticeReport(report.toJson());

      Get.snackbar(
        'Malpractice Report Recorded',
        '${report.id} submitted for review.',
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
