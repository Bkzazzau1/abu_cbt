import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/attendance_models.dart';
import '../../../data/services/attendance_demo_store.dart';

class AttendanceRegisterController extends GetxController {
  final isLoading = false.obs;
  final selectedHall = 'All Halls'.obs;
  final selectedState = 'All States'.obs;
  final selectedRegistration = ''.obs;
  final searchController = TextEditingController();

  late final AttendanceDemoStore _store;

  RxList<AttendanceRecord> get records => _store.records;

  @override
  void onInit() {
    super.onInit();
    _store = Get.isRegistered<AttendanceDemoStore>()
        ? Get.find<AttendanceDemoStore>()
        : Get.put(AttendanceDemoStore(), permanent: true);
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      await _store.ensureLoaded();
    } finally {
      isLoading.value = false;
    }
  }

  List<String> get hallOptions {
    final halls = records.map((e) => e.hallName).toSet().toList()..sort();
    return ['All Halls', ...halls];
  }

  List<String> get stateOptions => const [
    'All States',
    'Expected',
    'Checked In',
    'Verified',
    'Authorized',
    'In Exam',
    'Submitted',
    'Absent',
    'Attention',
  ];

  List<AttendanceRecord> get filteredRecords {
    final q = searchController.text.trim().toLowerCase();

    final items = records.where((r) {
      final hallOk =
          selectedHall.value == 'All Halls' || r.hallName == selectedHall.value;
      final stateOk = switch (selectedState.value) {
        'Expected' => r.state == AttendanceState.expected,
        'Checked In' => r.state == AttendanceState.checkedIn,
        'Verified' => r.state == AttendanceState.verified,
        'Authorized' => r.state == AttendanceState.authorized,
        'In Exam' => r.state == AttendanceState.inExam,
        'Submitted' => r.state == AttendanceState.submitted,
        'Absent' => r.state == AttendanceState.absent,
        'Attention' => r.needsAttention,
        _ => true,
      };
      final queryOk =
          q.isEmpty ||
          r.candidateName.toLowerCase().contains(q) ||
          r.registrationNumber.toLowerCase().contains(q) ||
          r.seatNumber.toLowerCase().contains(q) ||
          r.workstationId.toLowerCase().contains(q) ||
          r.examTitle.toLowerCase().contains(q);

      return hallOk && stateOk && queryOk;
    }).toList();

    items.sort((a, b) {
      if (a.needsAttention != b.needsAttention) {
        return a.needsAttention ? -1 : 1;
      }
      return a.seatNumber.compareTo(b.seatNumber);
    });
    return items;
  }

  AttendanceRecord? get selectedRecord {
    final reg = selectedRegistration.value;
    if (reg.isEmpty) return null;
    return _store.findByRegistration(reg);
  }

  int get expectedCount =>
      records.where((e) => e.state == AttendanceState.expected).length;
  int get checkedInCount =>
      records.where((e) => e.state == AttendanceState.checkedIn).length;
  int get verifiedCount =>
      records.where((e) => e.state == AttendanceState.verified).length;
  int get authorizedCount =>
      records.where((e) => e.state == AttendanceState.authorized).length;
  int get inExamCount =>
      records.where((e) => e.state == AttendanceState.inExam).length;
  int get attentionCount => records.where((e) => e.needsAttention).length;

  void updateHall(String value) {
    selectedHall.value = value;
  }

  void updateState(String value) {
    selectedState.value = value;
  }

  void updateSearch(String _) {
    records.refresh();
  }

  void selectRecord(AttendanceRecord record) {
    selectedRegistration.value = record.registrationNumber;
  }

  void clearSelection() {
    selectedRegistration.value = '';
  }

  void markCheckedIn(AttendanceRecord record) {
    _store.updateRecord(
      record.copyWith(
        state: AttendanceState.checkedIn,
        arrivalTimeLabel: record.arrivalTimeLabel == '-'
            ? 'Just now'
            : record.arrivalTimeLabel,
      ),
    );
  }

  void markVerified(AttendanceRecord record) {
    _store.setVerification(
      registrationNumber: record.registrationNumber,
      identityState: IdentityVerificationState.matched,
      biometricConfidence: record.biometricConfidence > 0
          ? record.biometricConfidence
          : 96,
      note: 'Identity and biometric checks passed.',
      state: AttendanceState.verified,
    );
  }

  void markAuthorized(AttendanceRecord record) {
    if (record.identityState != IdentityVerificationState.matched) {
      Get.snackbar(
        'Verification required',
        'Verify the candidate identity before authorization.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    _store.setState(record.registrationNumber, AttendanceState.authorized);
  }

  void markAbsent(AttendanceRecord record) {
    _store.setState(record.registrationNumber, AttendanceState.absent);
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
