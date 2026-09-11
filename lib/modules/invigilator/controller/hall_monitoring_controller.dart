import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/hall_monitor_models.dart';
import '../../../data/services/hall_monitor_mock_service.dart';

class HallMonitoringController extends GetxController {
  final isLoading = false.obs;
  final records = <HallMonitorRecord>[].obs;

  final selectedHall = 'All Halls'.obs;
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
    } finally {
      isLoading.value = false;
    }
  }

  List<String> get hallOptions {
    final halls = records.map((e) => e.hallName).toSet().toList()..sort();
    return ['All Halls', ...halls];
  }

  List<HallMonitorRecord> get filteredRecords {
    final q = searchController.text.trim().toLowerCase();

    return records.where((r) {
      final hallOk =
          selectedHall.value == 'All Halls' || r.hallName == selectedHall.value;

      final queryOk =
          q.isEmpty ||
          r.seatNumber.toLowerCase().contains(q) ||
          r.workstationId.toLowerCase().contains(q) ||
          r.candidateName.toLowerCase().contains(q) ||
          r.registrationNumber.toLowerCase().contains(q) ||
          r.examTitle.toLowerCase().contains(q);

      return hallOk && queryOk;
    }).toList();
  }

  int get readyCount =>
      records.where((e) => e.state == HallCandidateLiveState.ready).length;
  int get inExamCount =>
      records.where((e) => e.state == HallCandidateLiveState.inExam).length;
  int get submittedCount =>
      records.where((e) => e.state == HallCandidateLiveState.submitted).length;
  int get issueCount => records
      .where(
        (e) => e.state == HallCandidateLiveState.issueFlagged || e.hasIncident,
      )
      .length;
  int get malpracticeCount => records
      .where(
        (e) =>
            e.state == HallCandidateLiveState.malpracticeFlagged ||
            e.hasMalpractice,
      )
      .length;

  void updateHall(String value) {
    selectedHall.value = value;
  }

  void updateSearch(String _) {
    records.refresh();
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

  void _replace(HallMonitorRecord updated) {
    final index = records.indexWhere(
      (e) => e.workstationId == updated.workstationId,
    );
    if (index < 0) return;
    records[index] = updated;
    records.refresh();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
