import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/attendance_models.dart';
import '../../../data/models/candidate_action_models.dart';
import '../../../data/models/exam_control_audit_models.dart';
import '../../../data/models/incident_models.dart';
import '../../../data/models/malpractice_models.dart';
import '../../../data/models/manual_identity_verification_models.dart';
import '../../../data/models/technical_report_models.dart';
import '../../../data/services/attendance_demo_store.dart';
import '../../../data/services/exam_reporting_store.dart';
import '../../../data/services/invigilator_demo_store.dart';
import '../../../data/services/manual_identity_verification_store.dart';

class GeneralExamReportController extends GetxController {
  final isLoading = false.obs;
  final selectedExam = ''.obs;
  final selectedHall = 'All Halls'.obs;
  final searchController = TextEditingController();

  late final AttendanceDemoStore _attendanceStore;
  late final InvigilatorDemoStore _invigilatorStore;
  late final ManualIdentityVerificationStore _identityStore;
  late final ExamReportingStore _reportingStore;

  @override
  void onInit() {
    super.onInit();
    _attendanceStore = Get.isRegistered<AttendanceDemoStore>()
        ? Get.find<AttendanceDemoStore>()
        : Get.put(AttendanceDemoStore(), permanent: true);
    _invigilatorStore = Get.isRegistered<InvigilatorDemoStore>()
        ? Get.find<InvigilatorDemoStore>()
        : Get.put(InvigilatorDemoStore(), permanent: true);
    _identityStore = Get.isRegistered<ManualIdentityVerificationStore>()
        ? Get.find<ManualIdentityVerificationStore>()
        : Get.put(ManualIdentityVerificationStore(), permanent: true);
    _reportingStore = Get.isRegistered<ExamReportingStore>()
        ? Get.find<ExamReportingStore>()
        : Get.put(ExamReportingStore(), permanent: true);
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      await _attendanceStore.ensureLoaded();
      await _invigilatorStore.ensureLoaded();
      _reportingStore.ensureSeeded();
      _identityStore.ensureSeeded();
      final exams = examOptions;
      if (selectedExam.value.isEmpty && exams.isNotEmpty) {
        selectedExam.value = exams.first;
      }
      if (!hallOptions.contains(selectedHall.value)) {
        selectedHall.value = 'All Halls';
      }
    } finally {
      isLoading.value = false;
    }
  }

  List<String> get examOptions {
    final exams = <String>{};
    exams.addAll(
      _attendanceStore.records
          .map((record) => record.examTitle)
          .where((title) => title.trim().isNotEmpty),
    );
    exams.addAll(
      _reportingStore.incidentReports
          .map((report) => report.examTitle)
          .where((title) => title.trim().isNotEmpty),
    );
    exams.addAll(
      _reportingStore.malpracticeReports
          .map((report) => report.examTitle)
          .where((title) => title.trim().isNotEmpty),
    );
    exams.addAll(
      _reportingStore.examControlEvents
          .map((event) => event.examTitle)
          .where((title) => title.trim().isNotEmpty),
    );
    exams.addAll(
      _identityStore.requests
          .map((request) => request.examTitle)
          .where((title) => title.trim().isNotEmpty),
    );
    final result = exams.toList()..sort();
    return result;
  }

  List<String> get hallsForExam {
    final halls = _attendanceStore.records
        .where((record) => record.examTitle == selectedExam.value)
        .map((record) => record.hallName)
        .where((hall) => hall.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return halls;
  }

  List<String> get hallOptions => ['All Halls', ...hallsForExam];

  void changeExam(String exam) {
    selectedExam.value = exam;
    selectedHall.value = 'All Halls';
  }

  void changeHall(String hall) {
    selectedHall.value = hall;
  }

  void updateSearch(String _) {
    _attendanceStore.records.refresh();
  }

  bool _hallIncluded(String hallName) =>
      selectedHall.value == 'All Halls' || hallName == selectedHall.value;

  List<AttendanceRecord> get candidates {
    final query = searchController.text.trim().toLowerCase();
    final items = _attendanceStore.records.where((record) {
      if (record.examTitle != selectedExam.value) return false;
      if (!_hallIncluded(record.hallName)) return false;
      if (query.isEmpty) return true;
      return record.candidateName.toLowerCase().contains(query) ||
          record.registrationNumber.toLowerCase().contains(query) ||
          record.seatNumber.toLowerCase().contains(query) ||
          record.workstationId.toLowerCase().contains(query);
    }).toList();
    items.sort((a, b) => a.registrationNumber.compareTo(b.registrationNumber));
    return items;
  }

  List<AttendanceRecord> get allSelectedExamCandidates =>
      _attendanceStore.records.where((record) {
        return record.examTitle == selectedExam.value &&
            _hallIncluded(record.hallName);
      }).toList();

  int get registeredCount => allSelectedExamCandidates.length;

  int get checkedInCount => allSelectedExamCandidates.where((record) {
        return record.state != AttendanceState.expected &&
            record.state != AttendanceState.absent;
      }).length;

  int get fingerprintVerifiedCount => allSelectedExamCandidates.where((record) {
        return record.identityState == IdentityVerificationState.matched &&
            !record.manualIdentityVerified;
      }).length;

  int get manualVerifiedCount => allSelectedExamCandidates
      .where((record) => record.manualIdentityVerified)
      .length;

  int get absentCount => allSelectedExamCandidates
      .where((record) => record.state == AttendanceState.absent)
      .length;

  int get inExamCount => allSelectedExamCandidates
      .where((record) => record.state == AttendanceState.inExam)
      .length;

  int get submittedCount => allSelectedExamCandidates
      .where((record) => record.state == AttendanceState.submitted)
      .length;

  List<IncidentReportModel> get incidents =>
      _reportingStore.incidentReports.where((report) {
        return report.examTitle == selectedExam.value &&
            _hallIncluded(report.hallName);
      }).toList();

  List<MalpracticeReportModel> get malpracticeReports =>
      _reportingStore.malpracticeReports.where((report) {
        return report.examTitle == selectedExam.value &&
            _hallIncluded(report.hallName);
      }).toList();

  List<ExamControlAuditRecord> get examControlEvents =>
      _reportingStore.examControlEvents.where((event) {
        return event.examTitle == selectedExam.value &&
            _hallIncluded(event.hallName);
      }).toList();

  List<ManualIdentityVerificationRequest> get identityReviews =>
      _identityStore.requests.where((request) {
        return request.examTitle == selectedExam.value &&
            _hallIncluded(request.hallName);
      }).toList();

  List<SeatReassignmentRecord> get workstationTransfers =>
      _invigilatorStore.seatReassignments.where((event) {
        if (!_hallIncluded(event.hallName)) return false;
        final candidate = _attendanceStore.findByRegistration(
          event.registrationNumber,
        );
        return candidate?.examTitle == selectedExam.value;
      }).toList();

  List<TechnicalReportRecord> get technicalReports =>
      _invigilatorStore.technicalReports.where((report) {
        if (!_hallIncluded(report.hallName)) return false;
        if (report.registrationNumber.trim().isNotEmpty) {
          final candidate = _attendanceStore.findByRegistration(
            report.registrationNumber,
          );
          if (candidate != null) return candidate.examTitle == selectedExam.value;
        }
        return hallsForExam.contains(report.hallName);
      }).toList();

  int incidentCountFor(String registrationNumber) => incidents
      .where((report) => report.registrationNumber == registrationNumber)
      .length;

  int malpracticeCountFor(String registrationNumber) => malpracticeReports
      .where((report) => report.registrationNumber == registrationNumber)
      .length;

  int technicalCountFor(String registrationNumber) => technicalReports
      .where((report) => report.registrationNumber == registrationNumber)
      .length;

  int transferCountFor(String registrationNumber) => workstationTransfers
      .where((event) => event.registrationNumber == registrationNumber)
      .length;

  int controlCountFor(String registrationNumber) => examControlEvents
      .where((event) => event.registrationNumber == registrationNumber)
      .length;

  List<ExamControlAuditRecord> controlEventsFor(String registrationNumber) =>
      examControlEvents
          .where((event) => event.registrationNumber == registrationNumber)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<ManualIdentityVerificationRequest> identityReviewsFor(
    String registrationNumber,
  ) =>
      identityReviews
          .where((request) => request.registrationNumber == registrationNumber)
          .toList();

  /// Kept under the original getter name for UI compatibility. The Candidate
  /// Audit table uses this as the total number of related audit records, not a
  /// risk score.
  int attentionCountFor(String registrationNumber) {
    return incidentCountFor(registrationNumber) +
        malpracticeCountFor(registrationNumber) +
        technicalCountFor(registrationNumber) +
        transferCountFor(registrationNumber) +
        controlCountFor(registrationNumber) +
        identityReviewsFor(registrationNumber).length;
  }

  int get forceSubmittedCount => examControlEvents
      .where((event) => event.type == ExamControlAuditType.forceSubmitted)
      .length;

  int get lateEntryCount => examControlEvents
      .where((event) => event.type == ExamControlAuditType.lateEntryAllowed)
      .length;

  int get totalOperationalEvents => incidents.length +
      malpracticeReports.length +
      technicalReports.length +
      workstationTransfers.length +
      identityReviews.length +
      examControlEvents.length;

  List<AttendanceRecord> candidatesForHall(String hall) =>
      _attendanceStore.records.where((record) {
        return record.examTitle == selectedExam.value && record.hallName == hall;
      }).toList();

  int hallSubmittedCount(String hall) => candidatesForHall(hall)
      .where((record) => record.state == AttendanceState.submitted)
      .length;

  int hallInExamCount(String hall) => candidatesForHall(hall)
      .where((record) => record.state == AttendanceState.inExam)
      .length;

  int hallAbsentCount(String hall) => candidatesForHall(hall)
      .where((record) => record.state == AttendanceState.absent)
      .length;

  int hallManualVerifiedCount(String hall) => candidatesForHall(hall)
      .where((record) => record.manualIdentityVerified)
      .length;

  int hallIssueCount(String hall) {
    return incidents.where((report) => report.hallName == hall).length +
        malpracticeReports.where((report) => report.hallName == hall).length +
        technicalReports.where((report) => report.hallName == hall).length;
  }

  String stageLabel(AttendanceState state) {
    switch (state) {
      case AttendanceState.expected:
        return 'Expected';
      case AttendanceState.checkedIn:
        return 'Checked In';
      case AttendanceState.verified:
        return 'Verified';
      case AttendanceState.authorized:
        return 'Authorized';
      case AttendanceState.inExam:
        return 'In Exam';
      case AttendanceState.submitted:
        return 'Submitted';
      case AttendanceState.absent:
        return 'Absent';
      case AttendanceState.issueFlagged:
        return 'Attention';
    }
  }

  String identityLabel(AttendanceRecord record) {
    if (record.manualIdentityVerified) return 'Manual Verified';
    switch (record.identityState) {
      case IdentityVerificationState.pending:
        return 'Pending';
      case IdentityVerificationState.matched:
        return 'Fingerprint';
      case IdentityVerificationState.mismatch:
        return 'Mismatch';
      case IdentityVerificationState.manualReview:
        return 'Manual Review';
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
