import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/invigilator_models.dart';
import '../../../data/models/workstation_presence_models.dart';
import '../../../data/models/workstation_models.dart';
import '../../../data/services/invigilator_mock_service.dart';
import '../../../data/services/workstation_presence_ws_service.dart';

class InvigilatorDashboardController extends GetxController {
  final isLoading = false.obs;
  final records = <InvigilatorWorkstationRecord>[].obs;
  final liveFeedConnected = false.obs;

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
    }).toList();
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
      default:
        break;
    }
  }

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
