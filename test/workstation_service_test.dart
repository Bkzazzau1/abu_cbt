import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:k_slas_cbt/data/models/workstation_models.dart';
import 'package:k_slas_cbt/data/services/workstation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'ensureAssignmentFromAttendance backfills blank hall and seat',
    () async {
      final now = DateTime.now().toIso8601String();
      await WorkstationService.save(
        WorkstationRegistration(
          workstationId: 'KASU-CBT-TEST-0001',
          centerName: '',
          hallName: '',
          seatNumber: '',
          status: WorkstationStatus.whitelisted,
          installedAtIso: now,
          lastSeenAtIso: now,
        ),
      );

      final updated = await WorkstationService.ensureAssignmentFromAttendance(
        candidateRegistrationNumber: 'KASU/CSC/001',
      );

      expect(updated.centerName, 'KASU');
      expect(updated.hallName, 'Hall A');
      expect(updated.seatNumber, 'A-01');
      expect(updated.status, WorkstationStatus.whitelisted);
    },
  );

  test('ensureAssignmentFromAttendance keeps existing assignment', () async {
    final now = DateTime.now().toIso8601String();
    await WorkstationService.save(
      WorkstationRegistration(
        workstationId: 'KASU-CBT-TEST-0002',
        centerName: 'KASU',
        hallName: 'Hall Z',
        seatNumber: 'Z-99',
        status: WorkstationStatus.whitelisted,
        installedAtIso: now,
        lastSeenAtIso: now,
      ),
    );

    final updated = await WorkstationService.ensureAssignmentFromAttendance(
      candidateRegistrationNumber: 'KASU/CSC/001',
    );

    expect(updated.centerName, 'KASU');
    expect(updated.hallName, 'Hall Z');
    expect(updated.seatNumber, 'Z-99');
  });
}
