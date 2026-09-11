import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/attendance_models.dart';
import '../../../data/services/attendance_mock_service.dart';

class AttendanceRegisterController extends GetxController {
  final isLoading = false.obs;
  final records = <AttendanceRecord>[].obs;

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
      final items = await AttendanceMockService.loadAttendance();
      records.assignAll(items);
    } finally {
      isLoading.value = false;
    }
  }

  List<String> get hallOptions {
    final halls = records.map((e) => e.hallName).toSet().toList()..sort();
    return ['All Halls', ...halls];
  }

  List<AttendanceRecord> get filteredRecords {
    final q = searchController.text.trim().toLowerCase();

    return records.where((r) {
      final hallOk =
          selectedHall.value == 'All Halls' || r.hallName == selectedHall.value;

      final queryOk =
          q.isEmpty ||
          r.candidateName.toLowerCase().contains(q) ||
          r.registrationNumber.toLowerCase().contains(q) ||
          r.seatNumber.toLowerCase().contains(q) ||
          r.examTitle.toLowerCase().contains(q);

      return hallOk && queryOk;
    }).toList();
  }

  int get expectedCount =>
      records.where((e) => e.state == AttendanceState.expected).length;
  int get presentCount =>
      records.where((e) => e.state == AttendanceState.present).length;
  int get seatedCount =>
      records.where((e) => e.state == AttendanceState.seated).length;
  int get absentCount =>
      records.where((e) => e.state == AttendanceState.absent).length;

  void updateHall(String value) {
    selectedHall.value = value;
  }

  void updateSearch(String _) {
    records.refresh();
  }

  void markPresent(AttendanceRecord record) =>
      _replace(record.copyWith(state: AttendanceState.present));

  void markAbsent(AttendanceRecord record) =>
      _replace(record.copyWith(state: AttendanceState.absent));

  void markSeated(AttendanceRecord record) =>
      _replace(record.copyWith(state: AttendanceState.seated));

  void markAuthorized(AttendanceRecord record) =>
      _replace(record.copyWith(state: AttendanceState.authorized));

  void _replace(AttendanceRecord updated) {
    final index = records.indexWhere(
      (e) => e.registrationNumber == updated.registrationNumber,
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
