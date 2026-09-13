import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/workstation_models.dart';
import 'attendance_mock_service.dart';

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

  static Future<WorkstationRegistration> ensureAssignmentFromAttendance({
    required String candidateRegistrationNumber,
    String fallbackCenterName = 'ABU',
  }) async {
    final current = await loadOrCreate();
    final needsHall = current.hallName.trim().isEmpty;
    final needsSeat = current.seatNumber.trim().isEmpty;

    if (!needsHall && !needsSeat) {
      return current;
    }

    final normalizedRegNo = candidateRegistrationNumber.trim().toUpperCase();
    if (normalizedRegNo.isEmpty) {
      return current;
    }

    final attendance = await AttendanceMockService.loadAttendance();
    for (final item in attendance) {
      if (item.registrationNumber.trim().toUpperCase() != normalizedRegNo) {
        continue;
      }

      final updated = current.copyWith(
        centerName: current.centerName.trim().isEmpty
            ? fallbackCenterName.trim()
            : current.centerName,
        hallName: needsHall ? item.hallName : current.hallName,
        seatNumber: needsSeat ? item.seatNumber : current.seatNumber,
        lastSeenAtIso: DateTime.now().toIso8601String(),
      );
      await save(updated);
      return updated;
    }

    return current;
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
