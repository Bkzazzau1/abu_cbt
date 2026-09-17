import '../models/attendance_models.dart';

class AttendanceMockService {
  static Future<List<AttendanceRecord>> loadAttendance() async {
    await Future.delayed(const Duration(milliseconds: 350));

    return [
      ..._buildHall(
        hallName: 'Hall A',
        seatPrefix: 'A',
        examTitle: 'CSC 305 - Data Structures',
        registrationPrefix: 'ABU/CSC',
        workstationPrefix: 'ABU-CBT-A',
        offset: 0,
      ),
      ..._buildHall(
        hallName: 'Hall B',
        seatPrefix: 'B',
        examTitle: 'GST 201 - Use of English',
        registrationPrefix: 'ABU/GST',
        workstationPrefix: 'ABU-CBT-B',
        offset: 48,
      ),
    ];
  }

  static List<AttendanceRecord> _buildHall({
    required String hallName,
    required String seatPrefix,
    required String examTitle,
    required String registrationPrefix,
    required String workstationPrefix,
    required int offset,
  }) {
    return List.generate(48, (index) {
      final seat = index + 1;
      final state = _stateForSeat(seat);
      final identity = _identityForSeat(seat, state);
      final name = _candidateNames[(offset + index) % _candidateNames.length];
      final arrival = _arrivalForState(state, seat);
      final confidence = _confidenceFor(identity, seat);
      final hasWorkstationBinding = _hasWorkstationBinding(state);

      return AttendanceRecord(
        candidateName: name,
        registrationNumber:
            '$registrationPrefix/${(offset + seat).toString().padLeft(3, '0')}',
        hallName: hallName,
        seatNumber: hasWorkstationBinding
            ? '$seatPrefix-${seat.toString().padLeft(2, '0')}'
            : '',
        examTitle: examTitle,
        state: state,
        workstationId: hasWorkstationBinding
            ? '$workstationPrefix${seat.toString().padLeft(2, '0')}-WS'
            : '',
        identityState: identity,
        biometricConfidence: confidence,
        arrivalTimeLabel: arrival,
        verificationNote: _noteFor(identity, seat),
      );
    });
  }

  static AttendanceState _stateForSeat(int seat) {
    if (seat == 19 || seat == 34) return AttendanceState.issueFlagged;
    if (seat == 11 || seat == 42) return AttendanceState.absent;
    if (seat == 4 ||
        seat == 15 ||
        seat == 22 ||
        seat == 31 ||
        seat == 39 ||
        seat == 46) {
      return AttendanceState.expected;
    }
    if (seat == 2 || seat == 28) return AttendanceState.checkedIn;
    if (seat == 5 || seat == 26) return AttendanceState.verified;
    if (seat == 8 || seat == 30) return AttendanceState.authorized;
    if (seat == 13 || seat == 24 || seat == 37 || seat == 45) {
      return AttendanceState.submitted;
    }
    return AttendanceState.inExam;
  }

  /// Check-in and authorization are identity/admission states, not evidence
  /// that a candidate owns a physical seat. Only a candidate who has actually
  /// entered the exam (or already submitted it) starts with a workstation
  /// binding in the demo data.
  static bool _hasWorkstationBinding(AttendanceState state) {
    return state == AttendanceState.inExam ||
        state == AttendanceState.submitted;
  }

  static IdentityVerificationState _identityForSeat(
    int seat,
    AttendanceState state,
  ) {
    if (seat == 19) return IdentityVerificationState.mismatch;
    if (seat == 34) return IdentityVerificationState.manualReview;
    if (state == AttendanceState.expected ||
        state == AttendanceState.checkedIn ||
        state == AttendanceState.absent) {
      return IdentityVerificationState.pending;
    }
    return IdentityVerificationState.matched;
  }

  static double _confidenceFor(IdentityVerificationState state, int seat) {
    switch (state) {
      case IdentityVerificationState.matched:
        return 94 + (seat % 5).toDouble();
      case IdentityVerificationState.manualVerified:
        return 0;
      case IdentityVerificationState.mismatch:
        return 54;
      case IdentityVerificationState.manualReview:
        return 72;
      case IdentityVerificationState.pending:
        return 0;
    }
  }

  static String _arrivalForState(AttendanceState state, int seat) {
    if (state == AttendanceState.expected || state == AttendanceState.absent) {
      return '-';
    }
    final minute = (seat * 2) % 28;
    return '09:${minute.toString().padLeft(2, '0')}';
  }

  static String _noteFor(IdentityVerificationState state, int seat) {
    switch (state) {
      case IdentityVerificationState.mismatch:
        return 'Biometric match below threshold. Candidate requires identity review.';
      case IdentityVerificationState.manualReview:
        return 'Biometric confidence is borderline. Manual document/photo review required.';
      case IdentityVerificationState.manualVerified:
        return 'Identity was verified manually by an invigilator.';
      case IdentityVerificationState.matched:
        return 'Identity and biometric checks passed.';
      case IdentityVerificationState.pending:
        return seat == 2 || seat == 28
            ? 'Candidate checked in; identity verification pending.'
            : '';
    }
  }

  static const _candidateNames = <String>[
    'Zainab Musa',
    'Ibrahim Bashir Yahaya',
    'Maryam Bello',
    'Sadiq Lawal',
    'Fatima Musa',
    'Umar Aliyu',
    'Aisha Bello',
    'Abubakar Sani',
    'Khadija Abdullahi',
    'Muhammad Kabir',
    'Hauwa Ibrahim',
    'Usman Garba',
    'Safiya Ahmad',
    'Yusuf Suleiman',
    'Nafisa Ismail',
    'Aminu Mohammed',
    'Rukayya Adamu',
    'Bashir Haruna',
    'Halima Sani',
    'Musa Abdullahi',
    'Jamila Ibrahim',
    'Abdullahi Umar',
    "Asma'u Bello",
    'Mustapha Garba',
    'Rahma Yusuf',
    'Nasir Ahmad',
    'Zahra Mohammed',
    'Aliyu Sani',
    'Habiba Musa',
    'Ibrahim Suleiman',
    'Amina Abdullahi',
    'Salisu Haruna',
    'Nura Kabir',
    'Fadila Umar',
    'Murtala Ahmad',
    'Sadiya Garba',
    'Khalid Ibrahim',
    'Bilal Musa',
    'Hafsat Bello',
    'Ismail Yusuf',
    'Farida Sani',
    'Mahmud Abdullahi',
    'Aisha Kabir',
    'Anas Mohammed',
    'Maryam Sani',
    'Hamza Bello',
    'Zulaihat Umar',
    'Abdulrahman Musa',
  ];
}
