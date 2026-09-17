import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/attendance_models.dart';
import '../../../data/models/checkin_models.dart';
import '../../../data/models/hall_monitor_models.dart';
import '../../../data/models/invigilator_models.dart';
import '../../../data/services/attendance_demo_store.dart';
import '../../../data/services/invigilator_demo_store.dart';
import '../../../data/services/workstation_presence_ws_service.dart';

class CandidateCheckInController extends GetxController {
  final record = Rxn<CandidateCheckInRecord>();
  final notesController = TextEditingController();

  late final AttendanceDemoStore _attendanceStore;
  late final InvigilatorDemoStore _invigilatorStore;

  @override
  void onInit() {
    super.onInit();
    _attendanceStore = Get.isRegistered<AttendanceDemoStore>()
        ? Get.find<AttendanceDemoStore>()
        : Get.put(AttendanceDemoStore(), permanent: true);
    _invigilatorStore = Get.isRegistered<InvigilatorDemoStore>()
        ? Get.find<InvigilatorDemoStore>()
        : Get.put(InvigilatorDemoStore(), permanent: true);
    _initialise(Get.arguments);
  }

  Future<void> _initialise(dynamic arg) async {
    await _attendanceStore.ensureLoaded();
    await _invigilatorStore.ensureLoaded();

    if (arg is AttendanceRecord) {
      record.value = _fromAttendance(arg);
      notesController.text = arg.verificationNote;
      return;
    }

    if (arg is InvigilatorWorkstationRecord) {
      final stored = _attendanceStore.findByRegistration(arg.registrationNumber);
      if (stored != null) {
        record.value = _fromAttendance(stored);
        notesController.text = stored.verificationNote;
        return;
      }
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
      return;
    }

    if (arg is HallMonitorRecord) {
      final stored = _attendanceStore.findByRegistration(arg.registrationNumber);
      if (stored != null) {
        record.value = _fromAttendance(stored);
        notesController.text = stored.verificationNote;
        return;
      }
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
    }
  }

  CandidateCheckInRecord _fromAttendance(AttendanceRecord source) {
    final progressed = source.state == AttendanceState.verified ||
        source.state == AttendanceState.authorized ||
        source.state == AttendanceState.inExam ||
        source.state == AttendanceState.submitted;

    return CandidateCheckInRecord(
      workstationId: source.workstationId,
      hallName: source.hallName,
      seatNumber: source.seatNumber,
      candidateName: source.candidateName,
      registrationNumber: source.registrationNumber,
      examTitle: source.examTitle,
      status: _statusForAttendance(source.state),
      note: source.verificationNote,
      identityState: source.identityState,
      biometricConfidence: source.biometricConfidence,
      seatVerified:
          source.seatNumber.isNotEmpty && source.workstationId.isNotEmpty,
      examVerified: progressed,
    );
  }

  CandidateCheckInStatus _statusForAttendance(AttendanceState state) {
    switch (state) {
      case AttendanceState.expected:
        return CandidateCheckInStatus.pending;
      case AttendanceState.checkedIn:
        return CandidateCheckInStatus.checkedIn;
      case AttendanceState.verified:
        return CandidateCheckInStatus.verified;
      case AttendanceState.authorized:
        return CandidateCheckInStatus.authorized;
      case AttendanceState.inExam:
      case AttendanceState.submitted:
        return CandidateCheckInStatus.inExam;
      case AttendanceState.absent:
        return CandidateCheckInStatus.absent;
      case AttendanceState.issueFlagged:
        return CandidateCheckInStatus.issueFlagged;
    }
  }

  void markCheckedIn() {
    final current = record.value;
    if (current == null) return;
    final updated = current.copyWith(
      status: CandidateCheckInStatus.checkedIn,
      note: notesController.text.trim(),
    );
    record.value = updated;
    _updateAttendance(updated, AttendanceState.checkedIn);
    _broadcastCheckIn(updated);
    Get.snackbar(
      'Checked In',
      'Candidate arrival recorded. Complete identity and exam verification before authorization.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Kept for compatibility with older UI/actions. Workstation allocation is
  /// no longer a prerequisite for candidate verification or authorization.
  void confirmSeat() {
    final current = record.value;
    if (current == null || current.status == CandidateCheckInStatus.pending) {
      _checkInRequired('workstation review');
      return;
    }

    final assignment = _invigilatorStore.assignmentForCandidate(
      registrationNumber: current.registrationNumber,
      examTitle: current.examTitle,
    );
    if (assignment == null) {
      Get.snackbar(
        'No workstation assigned',
        'This is valid in Free Seating. Manual/System allocation can be managed from Workstation Allocation.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final updated = current.copyWith(
      hallName: assignment.hallName,
      seatNumber: assignment.seatNumber,
      workstationId: assignment.workstationId,
      seatVerified: true,
    );
    record.value = updated;
  }

  void confirmExam() {
    final current = record.value;
    if (current == null || current.status == CandidateCheckInStatus.pending) {
      _checkInRequired('assigned exam');
      return;
    }
    _applyVerificationProgress(current.copyWith(examVerified: true));
  }

  void runIdentityVerification() {
    final current = record.value;
    if (current == null) return;
    if (current.status == CandidateCheckInStatus.pending) {
      _checkInRequired('identity verification');
      return;
    }

    if (current.identityState == IdentityVerificationState.mismatch) {
      flagIssue(
        message: 'Biometric mismatch remains below the acceptance threshold.',
      );
      return;
    }

    if (current.identityState == IdentityVerificationState.manualReview) {
      Get.snackbar(
        'Manual review required',
        'This candidate needs an invigilator identity review before approval.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final updated = current.copyWith(
      identityState: IdentityVerificationState.matched,
      biometricConfidence: current.biometricConfidence > 0
          ? current.biometricConfidence
          : 96,
      note: notesController.text.trim().isEmpty
          ? 'Identity and biometric checks passed.'
          : notesController.text.trim(),
    );
    _applyVerificationProgress(updated);
    Get.snackbar(
      'Identity Verified',
      'Biometric identity check passed.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void approveManualReview() {
    final current = record.value;
    if (current == null) return;
    if (current.identityState != IdentityVerificationState.manualReview) return;
    if (notesController.text.trim().isEmpty) {
      Get.snackbar(
        'Review note required',
        'Add a note describing the manual identity review before approval.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final updated = current.copyWith(
      identityState: IdentityVerificationState.matched,
      note: notesController.text.trim(),
    );
    _applyVerificationProgress(updated);
    Get.snackbar(
      'Manual Review Approved',
      'Identity review recorded. Complete any remaining verification checks.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _applyVerificationProgress(CandidateCheckInRecord candidate) {
    final fullyVerified = candidate.identityVerified && candidate.examVerified;
    final nextStatus = fullyVerified
        ? CandidateCheckInStatus.verified
        : CandidateCheckInStatus.checkedIn;
    final updated = candidate.copyWith(status: nextStatus);
    record.value = updated;

    _attendanceStore.setVerification(
      registrationNumber: updated.registrationNumber,
      identityState: updated.identityState,
      biometricConfidence: updated.biometricConfidence,
      note: updated.note,
      state: fullyVerified ? AttendanceState.verified : AttendanceState.checkedIn,
    );
  }

  void authorize() {
    final current = record.value;
    if (current == null) return;
    if (current.status != CandidateCheckInStatus.verified ||
        !current.canAuthorize) {
      Get.snackbar(
        'Verification incomplete',
        'Complete identity and exam verification before authorization. Workstation allocation is handled separately.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final updated = current.copyWith(
      status: CandidateCheckInStatus.authorized,
      note: notesController.text.trim(),
    );
    record.value = updated;
    _updateAttendance(updated, AttendanceState.authorized);
    Get.snackbar(
      'Authorized',
      'Candidate is authorized. Workstation access will follow the active allocation policy.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void markInExam() {
    final current = record.value;
    if (current == null) return;

    final assignment = _invigilatorStore.assignmentForCandidate(
      registrationNumber: current.registrationNumber,
      examTitle: current.examTitle,
    );
    if (assignment?.isLocked != true) {
      Get.snackbar(
        'Workstation login required',
        'The candidate must successfully log in to a workstation before the In Exam state is recorded.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final updated = current.copyWith(
      workstationId: assignment!.workstationId,
      hallName: assignment.hallName,
      seatNumber: assignment.seatNumber,
      seatVerified: true,
      status: CandidateCheckInStatus.inExam,
      note: notesController.text.trim(),
    );
    record.value = updated;
    _updateAttendance(updated, AttendanceState.inExam);
    Get.snackbar(
      'Candidate In Exam',
      'Workstation login confirmed at ${assignment.seatNumber}.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void markAbsent() {
    final current = record.value;
    if (current == null) return;
    final updated = current.copyWith(
      status: CandidateCheckInStatus.absent,
      note: notesController.text.trim(),
    );
    record.value = updated;
    _updateAttendance(updated, AttendanceState.absent);
    Get.snackbar(
      'Marked Absent',
      'Candidate has been marked absent for this session.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void flagIssue({String? message}) {
    final current = record.value;
    if (current == null) return;
    final note = message ?? notesController.text.trim();
    final updated = current.copyWith(
      status: CandidateCheckInStatus.issueFlagged,
      note: note,
    );
    record.value = updated;
    _attendanceStore.setVerification(
      registrationNumber: updated.registrationNumber,
      identityState: updated.identityState,
      biometricConfidence: updated.biometricConfidence,
      note: note,
      state: AttendanceState.issueFlagged,
    );
    Get.snackbar(
      'Check-In Attention',
      message ?? 'Candidate check-in issue has been flagged.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _checkInRequired(String step) {
    Get.snackbar(
      'Check-In Required',
      'Record the candidate arrival before completing $step.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _updateAttendance(
    CandidateCheckInRecord updated,
    AttendanceState attendanceState,
  ) {
    final source = _attendanceStore.findByRegistration(updated.registrationNumber);
    if (source == null) return;
    _attendanceStore.updateRecord(
      source.copyWith(
        state: attendanceState,
        hallName: updated.hallName,
        seatNumber: updated.seatNumber,
        workstationId: updated.workstationId,
        identityState: updated.identityState,
        biometricConfidence: updated.biometricConfidence,
        verificationNote: updated.note,
        arrivalTimeLabel: source.arrivalTimeLabel == '-' &&
                attendanceState == AttendanceState.checkedIn
            ? 'Just now'
            : source.arrivalTimeLabel,
      ),
    );
  }

  void _broadcastCheckIn(CandidateCheckInRecord record) {
    if (record.registrationNumber.trim().isEmpty) return;
    final service = Get.isRegistered<WorkstationPresenceWsService>()
        ? Get.find<WorkstationPresenceWsService>()
        : Get.put(WorkstationPresenceWsService());
    service.sendCheckIn(
      registrationNumber: record.registrationNumber,
      candidateName: record.candidateName,
      hallName: record.hallName,
      seatNumber: record.seatNumber,
    );
  }

  @override
  void onClose() {
    notesController.dispose();
    super.onClose();
  }
}
