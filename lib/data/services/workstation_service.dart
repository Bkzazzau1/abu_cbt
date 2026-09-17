import 'dart:math';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/attendance_models.dart';
import '../models/workstation_models.dart';
import 'attendance_demo_store.dart';

class WorkstationService {
  static const _key = 'center_exam.workstation_registration';
  static const _submissionHistoryKey =
      'center_exam.workstation_submission_history';

  static Future<WorkstationRegistration> loadOrCreate() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_key);

    if (saved != null && saved.length == 7) {
      return WorkstationRegistration(
        workstationId: saved[0],
        centerName: saved[1],
        hallName: saved[2],
        seatNumber: saved[3],
        status: WorkstationStatus.values.firstWhere(
          (e) => e.name == saved[4],
          orElse: () => WorkstationStatus.pending,
        ),
        installedAtIso: saved[5],
        lastSeenAtIso: saved[6],
      );
    }

    final now = DateTime.now().toIso8601String();
    final reg = WorkstationRegistration(
      workstationId: _generateWorkstationId(),
      centerName: '',
      hallName: '',
      seatNumber: '',
      status: WorkstationStatus.pending,
      installedAtIso: now,
      lastSeenAtIso: now,
    );

    await save(reg);
    return reg;
  }

  static Future<void> save(WorkstationRegistration reg) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, [
      reg.workstationId,
      reg.centerName,
      reg.hallName,
      reg.seatNumber,
      reg.status.name,
      reg.installedAtIso,
      reg.lastSeenAtIso,
    ]);
  }

  static Future<WorkstationRegistration> touchLastSeen() async {
    final current = await loadOrCreate();
    final updated = current.copyWith(
      lastSeenAtIso: DateTime.now().toIso8601String(),
    );
    await save(updated);
    return updated;
  }

  static Future<WorkstationRegistration> submitForApproval({
    required String centerName,
    required String hallName,
    required String seatNumber,
  }) async {
    final current = await loadOrCreate();
    final updated = current.copyWith(
      centerName: centerName.trim(),
      hallName: hallName.trim(),
      seatNumber: seatNumber.trim(),
      status: WorkstationStatus.pending,
      lastSeenAtIso: DateTime.now().toIso8601String(),
    );
    await save(updated);
    return updated;
  }

  /// Updates only the physical workstation registration. Candidate login must
  /// never change hall/seat identity; the assignment engine binds a candidate
  /// to this already-registered workstation for an examination session.
  static Future<WorkstationRegistration> updateAssignment({
    required String centerName,
    required String hallName,
    required String seatNumber,
  }) async {
    final current = await loadOrCreate();
    final updated = current.copyWith(
      centerName: centerName.trim(),
      hallName: hallName.trim(),
      seatNumber: seatNumber.trim(),
      lastSeenAtIso: DateTime.now().toIso8601String(),
    );
    await save(updated);
    return updated;
  }

  /// Legacy compatibility bridge used by the exam-run controller.
  ///
  /// This method intentionally does NOT derive or change the physical seat
  /// from Attendance. By the time CenterExamRun starts, candidate login has
  /// already bound the candidate to the registered workstation and identity
  /// verification has passed. We therefore return the existing physical
  /// registration and record the admission transition to In Exam.
  static Future<WorkstationRegistration> ensureAssignmentFromAttendance({
    required String candidateRegistrationNumber,
  }) async {
    final registration = await touchLastSeen();

    try {
      final store = Get.isRegistered<AttendanceDemoStore>()
          ? Get.find<AttendanceDemoStore>()
          : Get.put(AttendanceDemoStore(), permanent: true);
      await store.ensureLoaded();
      final attendance = store.findByRegistration(candidateRegistrationNumber);
      if (attendance != null &&
          attendance.state != AttendanceState.submitted &&
          attendance.state != AttendanceState.absent &&
          attendance.state != AttendanceState.issueFlagged) {
        store.updateRecord(
          attendance.copyWith(
            hallName: registration.hallName.isEmpty
                ? attendance.hallName
                : registration.hallName,
            seatNumber: registration.seatNumber.isEmpty
                ? attendance.seatNumber
                : registration.seatNumber,
            workstationId: registration.workstationId,
            state: AttendanceState.inExam,
          ),
        );
      }
    } catch (_) {
      // Demo attendance synchronization must never stop the actual exam from
      // opening after identity clearance. Production uses hall-server events.
    }

    return registration;
  }

  // FRONTEND MOCK:
  // Later backend will control this permanently.
  static Future<WorkstationRegistration> mockWhitelistCurrentDevice() async {
    final current = await loadOrCreate();
    final updated = current.copyWith(
      status: WorkstationStatus.whitelisted,
      lastSeenAtIso: DateTime.now().toIso8601String(),
    );
    await save(updated);
    return updated;
  }

  static Future<WorkstationRegistration> mockDisableCurrentDevice() async {
    final current = await loadOrCreate();
    final updated = current.copyWith(
      status: WorkstationStatus.disabled,
      lastSeenAtIso: DateTime.now().toIso8601String(),
    );
    await save(updated);
    return updated;
  }

  static Future<WorkstationRegistration> mockRevokeCurrentDevice() async {
    final current = await loadOrCreate();
    final updated = current.copyWith(
      status: WorkstationStatus.revoked,
      lastSeenAtIso: DateTime.now().toIso8601String(),
    );
    await save(updated);
    return updated;
  }

  static Future<bool> hasSubmissionHistory(String workstationId) async {
    final id = workstationId.trim();
    if (id.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    final saved =
        prefs.getStringList(_submissionHistoryKey) ?? const <String>[];
    return saved.any((item) => item == id);
  }

  static Future<void> markSubmission(String workstationId) async {
    final id = workstationId.trim();
    if (id.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final saved =
        (prefs.getStringList(_submissionHistoryKey) ?? const <String>[])
            .toSet();
    saved.add(id);
    await prefs.setStringList(_submissionHistoryKey, saved.toList()..sort());
  }

  static String _generateWorkstationId() {
    final r = Random.secure();

    String block(int len) {
      const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
      return List.generate(len, (_) => chars[r.nextInt(chars.length)]).join();
    }

    return 'ABU-CBT-${block(4)}-${block(4)}-${block(4)}';
  }
}
