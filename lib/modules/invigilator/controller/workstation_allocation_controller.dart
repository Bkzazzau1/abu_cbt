import 'package:get/get.dart';

import '../../../data/models/attendance_models.dart';
import '../../../data/models/seat_map_models.dart';
import '../../../data/models/workstation_assignment_models.dart';
import '../../../data/services/attendance_demo_store.dart';
import '../../../data/services/invigilator_demo_store.dart';

class WorkstationAllocationController extends GetxController {
  final isLoading = false.obs;
  final isProcessing = false.obs;
  final selectedHall = 'Hall A'.obs;
  final selectedMode = WorkstationAssignmentMode.freeSeating.obs;
  final selectedDistributionMode = WorkstationDistributionMode.fixed.obs;
  final selectedCandidateRegistration = ''.obs;
  final selectedSeatNumber = ''.obs;

  late final InvigilatorDemoStore _invigilatorStore;
  late final AttendanceDemoStore _attendanceStore;

  @override
  void onInit() {
    super.onInit();
    _invigilatorStore = Get.isRegistered<InvigilatorDemoStore>()
        ? Get.find<InvigilatorDemoStore>()
        : Get.put(InvigilatorDemoStore(), permanent: true);
    _attendanceStore = Get.isRegistered<AttendanceDemoStore>()
        ? Get.find<AttendanceDemoStore>()
        : Get.put(AttendanceDemoStore(), permanent: true);
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      await _invigilatorStore.ensureLoaded();
      await _attendanceStore.ensureLoaded();
      if (!hallOptions.contains(selectedHall.value) && hallOptions.isNotEmpty) {
        selectedHall.value = hallOptions.first;
      }
      _loadCurrentPolicy();
    } finally {
      isLoading.value = false;
    }
  }

  List<String> get hallOptions {
    final halls = _invigilatorStore.seats.map((e) => e.hallName).toSet().toList()
      ..sort();
    return halls;
  }

  String get currentExamTitle {
    for (final record in _attendanceStore.records) {
      if (record.hallName == selectedHall.value && record.examTitle.isNotEmpty) {
        return record.examTitle;
      }
    }
    return selectedHall.value == 'Hall B'
        ? 'GST 201 - Use of English'
        : 'CSC 305 - Data Structures';
  }

  WorkstationAssignmentPolicy get currentPolicy => _invigilatorStore.policyFor(
        hallName: selectedHall.value,
        examTitle: currentExamTitle,
      );

  List<AttendanceRecord> get candidatesForHall {
    final items = _attendanceStore.records
        .where((record) => record.hallName == selectedHall.value)
        .toList();
    items.sort((a, b) => a.registrationNumber.compareTo(b.registrationNumber));
    return items;
  }

  List<AttendanceRecord> get assignableCandidates {
    return candidatesForHall.where((record) {
      if (record.state == AttendanceState.absent ||
          record.state == AttendanceState.submitted ||
          record.state == AttendanceState.inExam ||
          record.state == AttendanceState.issueFlagged) {
        return false;
      }
      final assignment = _invigilatorStore.assignmentForCandidate(
        registrationNumber: record.registrationNumber,
        examTitle: record.examTitle,
      );
      return assignment?.isLocked != true;
    }).toList();
  }

  List<SeatMapRecord> get availableWorkstations =>
      _invigilatorStore.availableSeatsForHall(selectedHall.value);

  List<CandidateWorkstationAssignment> get currentAssignments =>
      _invigilatorStore.assignmentsForHall(
        selectedHall.value,
        examTitle: currentExamTitle,
      );

  int get reservedCount => currentAssignments.where((a) => a.isReserved).length;
  int get lockedCount => currentAssignments.where((a) => a.isLocked).length;

  void changeHall(String hall) {
    selectedHall.value = hall;
    selectedCandidateRegistration.value = '';
    selectedSeatNumber.value = '';
    _loadCurrentPolicy();
  }

  void changeMode(WorkstationAssignmentMode mode) {
    if (mode == selectedMode.value) return;

    // Locked sessions survive a policy change; only pre-login reservations are
    // released when moving to Free Seating so candidates truly become free to
    // choose any healthy workstation.
    if (mode == WorkstationAssignmentMode.freeSeating && reservedCount > 0) {
      _clearCurrentReservations();
      Get.snackbar(
        'Reservations released',
        'Pre-login workstation reservations were cleared. Existing logged-in locks were preserved.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }

    selectedMode.value = mode;
    selectedCandidateRegistration.value = '';
    selectedSeatNumber.value = '';
    _savePolicy();
  }

  void changeDistributionMode(WorkstationDistributionMode mode) {
    selectedDistributionMode.value = mode;
    _savePolicy();
  }

  void selectCandidate(String? registrationNumber) {
    selectedCandidateRegistration.value = registrationNumber ?? '';
  }

  void selectSeat(String? seatNumber) {
    selectedSeatNumber.value = seatNumber ?? '';
  }

  Future<void> reserveSelectedCandidate() async {
    if (isProcessing.value) return;
    final registrationNumber = selectedCandidateRegistration.value;
    final seatNumber = selectedSeatNumber.value;
    if (registrationNumber.isEmpty || seatNumber.isEmpty) {
      _showError('Select both a candidate and an available workstation.');
      return;
    }

    AttendanceRecord? candidate;
    for (final record in candidatesForHall) {
      if (record.registrationNumber == registrationNumber) {
        candidate = record;
        break;
      }
    }
    if (candidate == null) {
      _showError('The selected candidate is no longer available.');
      return;
    }

    isProcessing.value = true;
    try {
      await _invigilatorStore.reserveWorkstation(
        candidate: CandidateAssignmentRequest(
          registrationNumber: candidate.registrationNumber,
          candidateName: candidate.candidateName,
          examTitle: candidate.examTitle,
          hallName: candidate.hallName,
        ),
        destinationSeatNumber: seatNumber,
        source: WorkstationAssignmentSource.manual,
      );
      selectedCandidateRegistration.value = '';
      selectedSeatNumber.value = '';
      Get.snackbar(
        'Workstation reserved',
        '${candidate.candidateName} is reserved for $seatNumber. The assignment locks after successful login.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on StateError catch (error) {
      _showError(error.message.toString());
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> distributeWorkstations() async {
    if (isProcessing.value) return;

    final eligible = candidatesForHall.where((record) {
      return record.state != AttendanceState.absent &&
          record.state != AttendanceState.submitted &&
          record.state != AttendanceState.issueFlagged;
    }).toList();

    final requests = eligible
        .map(
          (record) => CandidateAssignmentRequest(
            registrationNumber: record.registrationNumber,
            candidateName: record.candidateName,
            examTitle: record.examTitle,
            hallName: record.hallName,
          ),
        )
        .toList();

    // The store intentionally replaces existing pre-login reservations during
    // a System Distribution run. Preflight capacity first so a failed run can
    // never clear a previously valid seating plan.
    final lockedRegistrations = currentAssignments
        .where((assignment) => assignment.isLocked)
        .map((assignment) => assignment.registrationNumber.trim().toUpperCase())
        .toSet();
    final candidatesNeedingReservation = requests.where(
      (request) =>
          !lockedRegistrations.contains(request.registrationNumber.trim().toUpperCase()),
    ).length;
    final effectiveCapacity = availableWorkstations.length + reservedCount;
    if (effectiveCapacity < candidatesNeedingReservation) {
      _showError(
        'Only $effectiveCapacity workstations can be allocated for $candidatesNeedingReservation candidates. Existing reservations were left unchanged.',
      );
      return;
    }

    isProcessing.value = true;
    try {
      final created = await _invigilatorStore.distributeCandidates(
        hallName: selectedHall.value,
        examTitle: currentExamTitle,
        candidates: requests,
        distributionMode: selectedDistributionMode.value,
      );
      Get.snackbar(
        'Distribution complete',
        '${created.length} workstation reservations created using ${selectedDistributionMode.value.label}.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on StateError catch (error) {
      _showError(error.message.toString());
    } finally {
      isProcessing.value = false;
    }
  }

  void _clearCurrentReservations() {
    final reservations = currentAssignments
        .where((assignment) => assignment.isReserved)
        .toList();

    for (final assignment in reservations) {
      final assignmentIndex = _invigilatorStore.workstationAssignments
          .indexWhere((item) => item.id == assignment.id);
      if (assignmentIndex >= 0) {
        _invigilatorStore.workstationAssignments[assignmentIndex] =
            assignment.copyWith(status: WorkstationAssignmentStatus.released);
      }

      final seatIndex = _invigilatorStore.seats.indexWhere(
        (seat) =>
            seat.hallName == assignment.hallName &&
            seat.seatNumber == assignment.seatNumber,
      );
      if (seatIndex < 0) continue;
      final seat = _invigilatorStore.seats[seatIndex];
      if (seat.state == SeatOccupancyState.expected &&
          seat.registrationNumber.trim().toUpperCase() ==
              assignment.registrationNumber.trim().toUpperCase()) {
        _invigilatorStore.seats[seatIndex] = seat.copyWith(
          candidateName: '',
          registrationNumber: '',
          examTitle: '',
          state: SeatOccupancyState.empty,
        );
      }
    }

    _invigilatorStore.workstationAssignments.refresh();
    _invigilatorStore.seats.refresh();
  }

  void _loadCurrentPolicy() {
    final policy = currentPolicy;
    selectedMode.value = policy.mode;
    selectedDistributionMode.value = policy.distributionMode;
  }

  void _savePolicy() {
    _invigilatorStore.setAssignmentPolicy(
      hallName: selectedHall.value,
      examTitle: currentExamTitle,
      mode: selectedMode.value,
      distributionMode: selectedDistributionMode.value,
    );
  }

  void _showError(String message) {
    Get.snackbar(
      'Workstation allocation',
      message,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
