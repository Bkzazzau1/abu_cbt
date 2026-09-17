import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/attendance_models.dart';
import '../../../data/models/checkin_models.dart';
import '../../../data/models/hall_monitor_models.dart';
import '../../../data/models/invigilator_models.dart';
import '../../../data/services/attendance_demo_store.dart';
import '../../../data/services/workstation_presence_ws_service.dart';

class CandidateCheckInController extends GetxController {
  final record = Rxn<CandidateCheckInRecord>();
  final notesController = TextEditingController();

  late final AttendanceDemoStore _attendanceStore;

  @override
  void onInit() {
    super.onInit();
    _attendanceStore = Get.isRegistered<AttendanceDemoStore>()
        ? Get.find<AttendanceDemoStore>()
        : Get.put(AttendanceDemoStore(), permanent: true);
    _initialise(Get.arguments);
  }

  Future<void> _initialise(dynamic arg) async {
    await _attendanceStore.ensureLoaded();

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
      seatVerified: progressed,
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
      case AttendanceState.inExam:
      case AttendanceState.submitted:
        return CandidateCheckInStatus.authorized;
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
      'Candidate arrival recorded. Complete verification before authorization.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void confirmSeat() {
    final current = record.value;
    if (current == null) return;
    record.value = current.copyWith(seatVerified: true);
  }

  void confirmExam() {
    final current = record.value;
    if (current == null) return;
    record.value = current.copyWith(examVerified: true);
  }

  void runIdentityVerification() {
    final current = record.value;
    if (current == null) return;

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
      status: CandidateCheckInStatus.verified,
      note: notesController.text.trim().isEmpty
          ? 'Identity and biometric checks passed.'
          : notesController.text.trim(),
    );
    record.value = updated;
    _attendanceStore.setVerification(
      registrationNumber: updated.registrationNumber,
      identityState: IdentityVerificationState.matched,
      biometricConfidence: updated.biometricConfidence,
      note: updated.note,
      state: AttendanceState.verified,
    );
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
      status: CandidateCheckInStatus.verified,
      note: notesController.text.trim(),
    );
    record.value = updated;
    _attendanceStore.setVerification(
      registrationNumber: updated.registrationNumber,
      identityState: IdentityVerificationState.matched,
      biometricConfidence: updated.biometricConfidence,
      note: updated.note,
      state: AttendanceState.verified,
    );
  }

  void authorize() {
    final current = record.value;
    if (current == null) return;
    if (!current.canAuthorize) {
      Get.snackbar(
        'Verification incomplete',
        'Identity, assigned seat, and exam allocation must all be verified.',
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
      'Candidate authorized to proceed to the examination.',
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

  void _updateAttendance(
    CandidateCheckInRecord updated,
    AttendanceState attendanceState,
  ) {
    final source = _attendanceStore.findByRegistration(updated.registrationNumber);
    if (source == null) return;
    _attendanceStore.updateRecord(
      source.copyWith(
        state: attendanceState,
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
