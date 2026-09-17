import 'package:get/get.dart';

import '../models/attendance_models.dart';
import 'attendance_mock_service.dart';

class AttendanceDemoStore extends GetxService {
  final records = <AttendanceRecord>[].obs;

  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    records.assignAll(await AttendanceMockService.loadAttendance());
    _loaded = true;
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
}
