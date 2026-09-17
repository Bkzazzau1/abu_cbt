import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/hall_monitor_models.dart';
import '../../../data/services/hall_monitor_mock_service.dart';

class HallMonitoringController extends GetxController {
  final isLoading = false.obs;
  final records = <HallMonitorRecord>[].obs;

  final selectedHall = 'All Halls'.obs;
  final selectedState = 'All Statuses'.obs;
  final selectedRecord = Rxn<HallMonitorRecord>();
  final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      final items = await HallMonitorMockService.loadHallRecords();
      records.assignAll(items);
      selectedRecord.value = items.isEmpty ? null : items.first;
    } finally {
      isLoading.value = false;
    }
  }

  List<String> get hallOptions {
    final halls = records.map((e) => e.hallName).toSet().toList()..sort();
    return ['All Halls', ...halls];
  }

  List<String> get stateOptions => const [
    'All Statuses',
    'In Exam',
    'Ready',
    'Checked In',
    'Authorized',
    'Submitted',
    'Issue',
    'Malpractice',
    'Offline',
    'Absent',
  ];

  List<HallMonitorRecord> get filteredRecords {
    final q = searchController.text.trim().toLowerCase();
    final items = records.where((r) {
      final hallOk =
          selectedHall.value == 'All Halls' || r.hallName == selectedHall.value;
      final stateOk = _matchesState(r.state, selectedState.value);
      final queryOk =
          q.isEmpty ||
          r.seatNumber.toLowerCase().contains(q) ||
          r.workstationId.toLowerCase().contains(q) ||
          r.candidateName.toLowerCase().contains(q) ||
          r.registrationNumber.toLowerCase().contains(q) ||
          r.examTitle.toLowerCase().contains(q);

      return hallOk && stateOk && queryOk;
    }).toList();

    items.sort((a, b) {
      final priority = _priority(b).compareTo(_priority(a));
      if (priority != 0) return priority;
      final hall = a.hallName.compareTo(b.hallName);
      if (hall != 0) return hall;
      return a.seatNumber.compareTo(b.seatNumber);
    });
    return items;
  }

  List<HallMonitorRecord> get summaryRecords => records.where((r) {
    return selectedHall.value == 'All Halls' || r.hallName == selectedHall.value;
  }).toList();

  int get readyCount =>
      summaryRecords.where((e) => e.state == HallCandidateLiveState.ready).length;
  int get inExamCount => summaryRecords
      .where((e) => e.state == HallCandidateLiveState.inExam)
      .length;
  int get submittedCount => summaryRecords
      .where((e) => e.state == HallCandidateLiveState.submitted)
      .length;
  int get issueCount => summaryRecords
      .where(
        (e) => e.state == HallCandidateLiveState.issueFlagged || e.hasIncident,
      )
      .length;
  int get malpracticeCount => summaryRecords
      .where(
        (e) =>
            e.state == HallCandidateLiveState.malpracticeFlagged ||
            e.hasMalpractice,
      )
      .length;
  int get offlineCount => summaryRecords
      .where((e) => e.state == HallCandidateLiveState.offline)
      .length;

  void updateHall(String value) {
    selectedHall.value = value;
    _keepSelectionVisible();
  }

  void updateState(String value) {
    selectedState.value = value;
    _keepSelectionVisible();
  }

  void updateSearch(String _) {
    records.refresh();
    _keepSelectionVisible();
  }

  void selectRecord(HallMonitorRecord record) {
    selectedRecord.value = record;
  }

  void markIssue(HallMonitorRecord record) {
    _replace(
      record.copyWith(
        state: HallCandidateLiveState.issueFlagged,
        hasIncident: true,
      ),
    );
  }

  void markMalpractice(HallMonitorRecord record) {
    _replace(
      record.copyWith(
        state: HallCandidateLiveState.malpracticeFlagged,
        hasMalpractice: true,
      ),
    );
  }

  void markOffline(HallMonitorRecord record) {
    _replace(record.copyWith(state: HallCandidateLiveState.offline));
  }

  void markSubmitted(HallMonitorRecord record) {
    _replace(record.copyWith(state: HallCandidateLiveState.submitted));
  }

  bool _matchesState(HallCandidateLiveState state, String filter) {
    return switch (filter) {
      'In Exam' => state == HallCandidateLiveState.inExam,
      'Ready' => state == HallCandidateLiveState.ready,
      'Checked In' => state == HallCandidateLiveState.checkedIn,
      'Authorized' => state == HallCandidateLiveState.authorized,
      'Submitted' => state == HallCandidateLiveState.submitted,
      'Issue' => state == HallCandidateLiveState.issueFlagged,
      'Malpractice' => state == HallCandidateLiveState.malpracticeFlagged,
      'Offline' => state == HallCandidateLiveState.offline,
      'Absent' => state == HallCandidateLiveState.absent,
      _ => true,
    };
  }

  int _priority(HallMonitorRecord record) {
    if (record.state == HallCandidateLiveState.malpracticeFlagged) return 5;
    if (record.state == HallCandidateLiveState.issueFlagged) return 4;
    if (record.state == HallCandidateLiveState.offline) return 3;
    if (record.state == HallCandidateLiveState.inExam) return 2;
    return 1;
  }

  void _replace(HallMonitorRecord updated) {
    final index = records.indexWhere(
      (e) => e.workstationId == updated.workstationId,
    );
    if (index < 0) return;
    records[index] = updated;
    records.refresh();
    if (selectedRecord.value?.workstationId == updated.workstationId) {
      selectedRecord.value = updated;
    }
  }

  void _keepSelectionVisible() {
    final visible = filteredRecords;
    final current = selectedRecord.value;
    if (current == null ||
        !visible.any((item) => item.workstationId == current.workstationId)) {
      selectedRecord.value = visible.isEmpty ? null : visible.first;
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
