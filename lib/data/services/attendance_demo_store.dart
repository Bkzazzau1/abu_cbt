import 'package:get/get.dart';

import '../models/attendance_models.dart';
import 'attendance_mock_service.dart';
import 'invigilator_demo_store.dart';

class AttendanceDemoStore extends GetxService {
  final records = <AttendanceRecord>[].obs;

  bool _loaded = false;
  late final InvigilatorDemoStore _invigilatorStore;
  Worker? _seatReassignmentWorker;
  Worker? _workstationAssignmentWorker;

  @override
  void onInit() {
    super.onInit();
    _invigilatorStore = Get.isRegistered<InvigilatorDemoStore>()
        ? Get.find<InvigilatorDemoStore>()
        : Get.put(InvigilatorDemoStore(), permanent: true);

    _seatReassignmentWorker = ever(
      _invigilatorStore.seatReassignments,
      (_) => _syncSeatReassignments(),
    );
    _workstationAssignmentWorker = ever(
      _invigilatorStore.workstationAssignments,
      (_) => _syncWorkstationAssignments(),
    );
  }

  Future<void> ensureLoaded() async {
    if (!_loaded) {
      records.assignAll(await AttendanceMockService.loadAttendance());
      _loaded = true;
    }

    await _invigilatorStore.ensureLoaded();
    _syncWorkstationAssignments();
    _syncSeatReassignments();
  }

  AttendanceRecord? findByRegistration(String registrationNumber) {
    for (final record in records) {
      if (record.registrationNumber == registrationNumber) return record;
    }
    return null;
  }

  void updateRecord(AttendanceRecord updated) {
    final index = records.indexWhere(
      (record) => record.registrationNumber == updated.registrationNumber,
    );
    if (index < 0) return;
    records[index] = updated;
    records.refresh();
  }

  void setState(String registrationNumber, AttendanceState state) {
    final current = findByRegistration(registrationNumber);
    if (current == null) return;
    updateRecord(current.copyWith(state: state));
  }

  void setVerification({
    required String registrationNumber,
    required IdentityVerificationState identityState,
    required double biometricConfidence,
    required String note,
    AttendanceState? state,
  }) {
    final current = findByRegistration(registrationNumber);
    if (current == null) return;
    updateRecord(
      current.copyWith(
        identityState: identityState,
        biometricConfidence: biometricConfidence,
        verificationNote: note,
        state: state,
      ),
    );
  }

  void _syncWorkstationAssignments() {
    if (!_loaded) return;
    var changed = false;

    for (var index = 0; index < records.length; index++) {
      final current = records[index];
      final assignment = _invigilatorStore.assignmentForCandidate(
        registrationNumber: current.registrationNumber,
        examTitle: current.examTitle,
      );
      if (assignment == null) continue;

      if (current.hallName == assignment.hallName &&
          current.seatNumber == assignment.seatNumber &&
          current.workstationId == assignment.workstationId) {
        continue;
      }

      records[index] = current.copyWith(
        hallName: assignment.hallName,
        seatNumber: assignment.seatNumber,
        workstationId: assignment.workstationId,
      );
      changed = true;
    }

    if (changed) records.refresh();
  }

  void _syncSeatReassignments() {
    if (!_loaded || _invigilatorStore.seatReassignments.isEmpty) return;

    var changed = false;

    // Events are stored newest-first. Apply oldest-first so the most recent
    // transfer wins when a candidate has been moved more than once.
    for (final event in _invigilatorStore.seatReassignments.reversed) {
      final index = records.indexWhere(
        (record) => record.registrationNumber == event.registrationNumber,
      );
      if (index < 0) continue;

      final current = records[index];
      if (current.hallName == event.hallName &&
          current.seatNumber == event.newSeatNumber &&
          current.workstationId == event.newWorkstationId) {
        continue;
      }

      records[index] = current.copyWith(
        hallName: event.hallName,
        seatNumber: event.newSeatNumber,
        workstationId: event.newWorkstationId,
      );
      changed = true;
    }

    if (changed) records.refresh();
  }

  @override
  void onClose() {
    _seatReassignmentWorker?.dispose();
    _workstationAssignmentWorker?.dispose();
    super.onClose();
  }
}
