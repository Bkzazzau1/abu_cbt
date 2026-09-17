import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/invigilator_models.dart';
import '../../../data/models/malpractice_models.dart';
import '../../../data/models/evidence_models.dart';
import '../../../data/models/workstation_presence_models.dart';
import '../../../data/models/workstation_models.dart';
import '../../../data/services/evidence_mock_service.dart';
import '../../../data/services/invigilator_mock_service.dart';
import '../../../data/services/invigilator_session.dart';
import '../../../data/services/malpractice_mock_service.dart';
import '../../../data/services/workstation_presence_ws_service.dart';

class InvigilatorDashboardController extends GetxController {
  final isLoading = false.obs;
  final records = <InvigilatorWorkstationRecord>[].obs;
  final liveFeedConnected = false.obs;

  final evidenceEvents = <EvidenceEvent>[].obs;
  final malpracticeReports = <MalpracticeReportModel>[].obs;

  final searchController = TextEditingController();
  final selectedHall = 'All Halls'.obs;
  final selectedStatus = 'All Statuses'.obs;

  late final WorkstationPresenceWsService _presenceService;
  StreamSubscription<WorkstationPresenceEnvelope>? _presenceSub;
  StreamSubscription<bool>? _connectionSub;

  @override
  void onInit() {
    super.onInit();
    _presenceService = Get.isRegistered<WorkstationPresenceWsService>()
        ? Get.find<WorkstationPresenceWsService>()
        : Get.put(WorkstationPresenceWsService());
    _bindRealtimeFeed();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      final items = await InvigilatorMockService.loadWorkstations();
      records.assignAll(items);

      final demoEvidence = await EvidenceMockService.loadEvidenceEvents();
      for (final event in demoEvidence) {
        _upsertEvidenceEvent(event);
      }

      final demoReports = await MalpracticeMockService.loadReports();
      for (final report in demoReports) {
        _upsertMalpracticeReport(report);
      }
    } finally {
      isLoading.value = false;
    }
  }

  List<String> get hallOptions {
    final halls = records.map((e) => e.hallName).toSet().toList()..sort();
    return ['All Halls', ...halls];
  }

  List<String> get statusOptions => const [
    'All Statuses',
    'Pending',
    'Whitelisted',
    'Disabled',
    'Revoked',
  ];

  List<InvigilatorWorkstationRecord> get filteredRecords {
    final q = searchController.text.trim().toLowerCase();

    return records.where((r) {
      final hallOk =
          selectedHall.value == 'All Halls' || r.hallName == selectedHall.value;

      final statusOk = switch (selectedStatus.value) {
        'Pending' => r.status == WorkstationStatus.pending,
        'Whitelisted' => r.status == WorkstationStatus.whitelisted,
        'Disabled' => r.status == WorkstationStatus.disabled,
        'Revoked' => r.status == WorkstationStatus.revoked,
        _ => true,
      };

      final queryOk =
          q.isEmpty ||
          r.workstationId.toLowerCase().contains(q) ||
          r.seatNumber.toLowerCase().contains(q) ||
          r.hallName.toLowerCase().contains(q) ||
          r.candidateName.toLowerCase().contains(q) ||
          r.registrationNumber.toLowerCase().contains(q);

      return hallOk && statusOk && queryOk;
    }).toList()..sort(_byRiskDescending);
  }

  List<InvigilatorWorkstationRecord> get priorityQueue {
    final flagged = records.where(_isUrgent).toList()..sort(_byRiskDescending);
    return flagged.take(5).toList();
  }

  bool _hasMalpracticeReport(String workstationId) =>
      malpracticeReports.any((r) => r.workstationId == workstationId);

  bool _isUrgent(InvigilatorWorkstationRecord r) =>
      r.riskFlagged ||
      r.checkInMismatch ||
      r.similarityFlagged ||
      _hasMalpracticeReport(r.workstationId);

  bool needsAttention(InvigilatorWorkstationRecord record) => _isUrgent(record);

  int get attentionCount => records.where(_isUrgent).length;

  int _byRiskDescending(
    InvigilatorWorkstationRecord a,
    InvigilatorWorkstationRecord b,
  ) {
    final aUrgent = _isUrgent(a);
    final bUrgent = _isUrgent(b);
    if (aUrgent != bUrgent) {
      return aUrgent ? -1 : 1;
    }
    final aHard = a.checkInMismatch ||
        a.similarityFlagged ||
        _hasMalpracticeReport(a.workstationId);
    final bHard = b.checkInMismatch ||
        b.similarityFlagged ||
        _hasMalpracticeReport(b.workstationId);
    if (aHard != bHard) {
      return aHard ? -1 : 1;
    }
    return b.riskScore.compareTo(a.riskScore);
  }

  int get totalCount => records.length;
  int get whitelistedCount =>
      records.where((e) => e.status == WorkstationStatus.whitelisted).length;
  int get pendingCount =>
      records.where((e) => e.status == WorkstationStatus.pending).length;
  int get activeExamCount =>
      records.where((e) => e.usageState == WorkstationUsageState.inExam).length;
  int get riskFlaggedCount => records.where((e) => e.riskFlagged).length;
  int get criticalRiskCount =>
      records.where((e) => e.riskLevel.toLowerCase() == 'critical').length;
  int get checkInMismatchCount =>
      records.where((e) => e.checkInMismatch).length;
  int get similarityFlaggedCount =>
      records.where((e) => e.similarityFlagged).length;

  void updateSearch(String _) {
    records.refresh();
  }

  void updateHall(String value) {
    selectedHall.value = value;
  }

  void updateStatus(String value) {
    selectedStatus.value = value;
  }

  void approve(InvigilatorWorkstationRecord record) {
    _replaceRecord(record.copyWith(status: WorkstationStatus.whitelisted));
    Get.snackbar(
      'Approved',
      '${record.seatNumber} is now whitelisted.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void disable(InvigilatorWorkstationRecord record) {
    _replaceRecord(record.copyWith(status: WorkstationStatus.disabled));
    Get.snackbar(
      'Disabled',
      '${record.seatNumber} has been disabled.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void revoke(InvigilatorWorkstationRecord record) {
    _replaceRecord(record.copyWith(status: WorkstationStatus.revoked));
    Get.snackbar(
      'Revoked',
      '${record.seatNumber} has been revoked.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void markActive(InvigilatorWorkstationRecord record) {
    _replaceRecord(record.copyWith(usageState: WorkstationUsageState.active));
  }

  void markLoggedIn(InvigilatorWorkstationRecord record) {
    _replaceRecord(
      record.copyWith(usageState: WorkstationUsageState.candidateLoggedIn),
    );
  }

  void markInExam(InvigilatorWorkstationRecord record) {
    _replaceRecord(record.copyWith(usageState: WorkstationUsageState.inExam));
  }

  void markSubmitted(InvigilatorWorkstationRecord record) {
    _replaceRecord(record.copyWith(usageState: WorkstationUsageState.submitted));
  }

  void pauseCandidate(InvigilatorWorkstationRecord record) {
    _replaceRecord(record.copyWith(isPaused: true));
    Get.snackbar(
      'Candidate Paused',
      '${record.candidateName.isEmpty ? record.seatNumber : record.candidateName} '
      'marked paused on this dashboard.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void resumeCandidate(InvigilatorWorkstationRecord record) {
    _replaceRecord(record.copyWith(isPaused: false));
    Get.snackbar(
      'Candidate Resumed',
      '${record.candidateName.isEmpty ? record.seatNumber : record.candidateName} '
      'marked active again.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  List<MalpracticeReportModel> malpracticeReportsFor(String workstationId) =>
      malpracticeReports
          .where((report) => report.workstationId == workstationId)
          .toList();

  void pauseHall(String hallName) {
    final targets = records.where((r) => r.hallName == hallName).toList();
    for (final record in targets) {
      _replaceRecord(record.copyWith(isPaused: true));
    }
    Get.snackbar(
      'Hall Paused',
      '${targets.length} candidate(s) in $hallName marked paused.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void resumeHall(String hallName) {
    final targets = records.where((r) => r.hallName == hallName).toList();
    for (final record in targets) {
      _replaceRecord(record.copyWith(isPaused: false));
    }
    Get.snackbar(
      'Hall Resumed',
      '${targets.length} candidate(s) in $hallName marked active again.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void terminateHall(String hallName, {required String reason}) {
    final targets = records
        .where((r) => r.hallName == hallName && r.candidateName.isNotEmpty)
        .toList();
    for (final record in targets) {
      terminateExam(
        workstationId: record.workstationId,
        seatLabel: 'seat ${record.seatNumber}',
        reason: reason,
      );
    }
  }

  void _replaceRecord(InvigilatorWorkstationRecord updated) {
    final index = records.indexWhere(
      (e) => e.workstationId == updated.workstationId,
    );
    if (index < 0) return;
    records[index] = updated;
    records.refresh();
  }

  Future<void> _bindRealtimeFeed() async {
    _presenceSub = _presenceService.incoming.listen(_applyPresenceEnvelope);
    _connectionSub = _presenceService.isConnected.listen(
      (value) => liveFeedConnected.value = value,
    );
    await _presenceService.connectInvigilator(centerName: 'ABU');
  }

  void _applyPresenceEnvelope(WorkstationPresenceEnvelope envelope) {
    switch (envelope.kind) {
      case 'snapshot':
        for (final item in envelope.records) {
          _upsertFromPresence(item);
        }
        break;
      case 'presenceUpdate':
        final item = envelope.record;
        if (item != null) {
          _upsertFromPresence(item);
        }
        break;
      case 'evidenceSnapshot':
        final demoEvidence = evidenceEvents
            .where((e) => e.id.startsWith('DEMO-'))
            .toList();
        evidenceEvents.assignAll(
          [...demoEvidence, ...envelope.evidenceEvents]
            ..sort((a, b) => b.detectedAtIso.compareTo(a.detectedAtIso)),
        );
        break;
      case 'evidenceUpdate':
        final event = envelope.evidenceEvent;
        if (event != null) _upsertEvidenceEvent(event);
        break;
      case 'malpracticeSnapshot':
        final demoReports = malpracticeReports
            .where((r) => r.id.startsWith('DEMO-'))
            .toList();
        malpracticeReports.assignAll(
          [...demoReports, ...envelope.malpracticeReports]
            ..sort((a, b) => b.reportedAtIso.compareTo(a.reportedAtIso)),
        );
        break;
      case 'malpracticeUpdate':
        final report = envelope.malpracticeReport;
        if (report != null) _upsertMalpracticeReport(report);
        break;
      default:
        break;
    }
  }

  void _upsertEvidenceEvent(EvidenceEvent event) {
    final index = evidenceEvents.indexWhere((e) => e.id == event.id);
    if (index >= 0) {
      evidenceEvents[index] = event;
    } else {
      evidenceEvents.insert(0, event);
    }
    evidenceEvents.refresh();
  }

  void _upsertMalpracticeReport(MalpracticeReportModel report) {
    final index = malpracticeReports.indexWhere((r) => r.id == report.id);
    if (index >= 0) {
      malpracticeReports[index] = report;
    } else {
      malpracticeReports.insert(0, report);
    }
    malpracticeReports.refresh();
  }

  void escalateEvidenceEvent(EvidenceEvent event) {
    _presenceService.sendEscalateEvidenceEvent(
      eventId: event.id,
      escalatedBy: _actorName,
    );
    Get.snackbar(
      'Escalated to exam officer',
      '${event.candidateName.isEmpty ? event.seatNumber : event.candidateName} '
      'has been flagged for exam officer review.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void escalateMalpracticeReport(MalpracticeReportModel report) {
    _presenceService.sendEscalateMalpracticeReport(
      reportId: report.id,
      escalatedBy: _actorName,
    );
    Get.snackbar(
      'Escalated to exam officer',
      'Malpractice report for '
      '${report.candidateName.isEmpty ? report.seatNumber : report.candidateName} '
      'has been sent for exam officer review.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void terminateExam({
    required String workstationId,
    required String seatLabel,
    required String reason,
  }) {
    _presenceService.sendTerminateExam(
      workstationId: workstationId,
      reason: reason,
      issuedBy: _actorName,
    );
    Get.snackbar(
      'Termination Sent',
      'Exam termination command sent to $seatLabel.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _upsertFromPresence(WorkstationPresenceModel item) {
    final index = records.indexWhere(
      (record) => record.workstationId == item.workstationId,
    );

    if (index >= 0) {
      final current = records[index];
      records[index] = current.copyWith(
        hallName: item.hallName,
        seatNumber: item.seatNumber,
        status: item.status,
        usageState: item.usageState,
        appInstalled: item.appInstalled,
        candidateName: item.candidateName,
        registrationNumber: item.registrationNumber,
        examTitle: item.examTitle,
        lastSeenLabel: item.lastSeenLabel,
        riskFlagged: item.riskFlagged,
        isNewWorkstation: item.isNewWorkstation,
        clientIpAddress: item.clientIpAddress,
        expectedHallIpRange: item.expectedHallIpRange,
        ipInExpectedRange: item.ipInExpectedRange,
        riskReasons: item.riskReasons,
        workstationApproved: item.workstationApproved,
        riskScore: item.riskScore,
        riskLevel: item.riskLevel,
        checkInMismatch: item.checkInMismatch,
        checkInMismatchReason: item.checkInMismatchReason,
        similarityFlagged: item.similarityFlagged,
        similarityReason: item.similarityReason,
      );
      records.refresh();
      return;
    }

    records.add(
      InvigilatorWorkstationRecord(
        workstationId: item.workstationId,
        centerName: item.centerName,
        hallName: item.hallName,
        seatNumber: item.seatNumber,
        status: item.status,
        usageState: item.usageState,
        appInstalled: item.appInstalled,
        candidateName: item.candidateName,
        registrationNumber: item.registrationNumber,
        examTitle: item.examTitle,
        lastSeenLabel: item.lastSeenLabel,
        riskFlagged: item.riskFlagged,
        isNewWorkstation: item.isNewWorkstation,
        clientIpAddress: item.clientIpAddress,
        expectedHallIpRange: item.expectedHallIpRange,
        ipInExpectedRange: item.ipInExpectedRange,
        riskReasons: item.riskReasons,
        workstationApproved: item.workstationApproved,
        riskScore: item.riskScore,
        riskLevel: item.riskLevel,
        checkInMismatch: item.checkInMismatch,
        checkInMismatchReason: item.checkInMismatchReason,
        similarityFlagged: item.similarityFlagged,
        similarityReason: item.similarityReason,
      ),
    );
    records.refresh();
  }

  String get _actorName {
    final session = Get.isRegistered<InvigilatorSession>()
        ? Get.find<InvigilatorSession>()
        : Get.put(InvigilatorSession(), permanent: true);
    return session.displayName.trim().isEmpty
        ? 'Invigilator'
        : session.displayName.trim();
  }

  @override
  void onClose() {
    searchController.dispose();
    _presenceSub?.cancel();
    _connectionSub?.cancel();
    _presenceService.disconnect();
    super.onClose();
  }
}
