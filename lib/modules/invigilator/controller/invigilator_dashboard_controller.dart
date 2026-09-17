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

  /// Newest first. Bounded display only — the backend already bounds what
  /// it retains (see MAX_EVIDENCE_EVENTS in the heartbeat service).
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
      // Demo/presentation seed data so the evidence and malpractice-report
      // sections have realistic content without needing a live detection or
      // a filed report first. Ids are prefixed `DEMO-` so a live backend's
      // snapshot (see `_applyPresenceEnvelope`) merges real data in
      // alongside these rather than wiping them.
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

  /// Highest-risk flagged candidates, most urgent first — the "check these
  /// first" list so an invigilator isn't scanning a flat grid to find them.
  /// A check-in/workstation mismatch, an AI-flagged answer similarity, or a
  /// filed malpractice report is treated as urgent as a submission risk flag.
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
    _replaceRecord(
      record.copyWith(usageState: WorkstationUsageState.submitted),
    );
  }

  /// Marks a candidate paused for this invigilator's own tracking. This is
  /// a dashboard-local marker only (see [InvigilatorWorkstationRecord.isPaused])
  /// — it does not freeze the candidate's running exam screen.
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

  /// Malpractice reports filed against this specific workstation, so a
  /// candidate's own card can show them inline instead of only in the
  /// separate reports feed.
  List<MalpracticeReportModel> malpracticeReportsFor(String workstationId) =>
      malpracticeReports
          .where((report) => report.workstationId == workstationId)
          .toList();

  /// Pauses every candidate currently visible under [hallName] (dashboard-
  /// local marker only — see [pauseCandidate]).
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

  /// Sends a real termination command (see [terminateExam]) to every
  /// currently-connected workstation with a candidate in [hallName].
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
        // Keep demo-seeded entries (see `load()`) rather than wiping them —
        // a live backend's snapshot merges alongside the demo data instead
        // of replacing it, so a presentation keeps its illustrative content
        // even once real detections start arriving.
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

  /// Hands an evidence event to the exam officer for further review,
  /// on top of it already being visible to every invigilator.
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

  /// Ends a specific candidate's exam immediately. Only takes effect if
  /// that workstation is currently connected — there is no queued/offline
  /// delivery, so a confirmation is shown by the caller (the view) before
  /// this is invoked, since it can't be undone once the candidate's app
  /// acts on it.
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
      'Termination command sent',
      'Told $seatLabel\'s workstation to end the exam now.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  String get _actorName =>
      InvigilatorSession.currentName.isEmpty
      ? 'invigilator'
      : InvigilatorSession.currentName;

  void _upsertFromPresence(WorkstationPresenceRecord update) {
    if (update.workstationId.trim().isEmpty) return;

    final index = records.indexWhere(
      (e) => e.workstationId == update.workstationId,
    );

    if (index >= 0) {
      final current = records[index];
      records[index] = current.copyWith(
        centerName: update.centerName.isEmpty
            ? current.centerName
            : update.centerName,
        hallName: update.hallName.isEmpty ? current.hallName : update.hallName,
        seatNumber: update.seatNumber.isEmpty
            ? current.seatNumber
            : update.seatNumber,
        status: update.workstationStatus,
        usageState: update.usageState,
        candidateName: update.candidateName,
        registrationNumber: update.registrationNumber,
        examTitle: update.examTitle,
        lastSeenLabel: _lastSeenLabel(update.eventAtIso),
        riskFlagged: update.riskFlagged,
        isNewWorkstation: update.isNewWorkstation,
        clientIpAddress: update.clientIpAddress,
        expectedHallIpRange: update.expectedHallIpRange,
        ipInExpectedRange: update.ipInExpectedRange,
        riskReasons: update.riskReasons,
        workstationApproved: update.workstationApproved,
        riskScore: update.riskScore,
        riskLevel: update.riskLevel,
        checkInMismatch: update.checkInMismatch,
        checkInMismatchReason: update.checkInMismatchReason,
        similarityFlagged: update.similarityFlagged,
        similarityReason: update.similarityReason,
      );
      records.refresh();
      return;
    }

    records.add(
      InvigilatorWorkstationRecord(
        workstationId: update.workstationId,
        centerName: update.centerName.isEmpty ? 'ABU' : update.centerName,
        hallName: update.hallName.isEmpty ? 'Unknown Hall' : update.hallName,
        seatNumber: update.seatNumber.isEmpty ? '-' : update.seatNumber,
        status: update.workstationStatus,
        usageState: update.usageState,
        appInstalled: true,
        candidateName: update.candidateName,
        registrationNumber: update.registrationNumber,
        examTitle: update.examTitle,
        lastSeenLabel: _lastSeenLabel(update.eventAtIso),
        riskFlagged: update.riskFlagged,
        isNewWorkstation: update.isNewWorkstation,
        clientIpAddress: update.clientIpAddress,
        expectedHallIpRange: update.expectedHallIpRange,
        ipInExpectedRange: update.ipInExpectedRange,
        riskReasons: update.riskReasons,
        workstationApproved: update.workstationApproved,
        riskScore: update.riskScore,
        riskLevel: update.riskLevel,
        checkInMismatch: update.checkInMismatch,
        checkInMismatchReason: update.checkInMismatchReason,
        similarityFlagged: update.similarityFlagged,
        similarityReason: update.similarityReason,
      ),
    );
    records.refresh();
  }

  String _lastSeenLabel(String eventAtIso) {
    final dt = DateTime.tryParse(eventAtIso)?.toLocal();
    if (dt == null) return 'Just now';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 50) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} day ago';
  }

  @override
  void onClose() {
    _presenceSub?.cancel();
    _connectionSub?.cancel();
    _presenceService.disconnect();
    searchController.dispose();
    super.onClose();
  }
}
