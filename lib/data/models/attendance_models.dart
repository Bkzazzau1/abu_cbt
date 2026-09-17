enum AttendanceState {
  expected,
  checkedIn,
  verified,
  authorized,
  inExam,
  submitted,
  absent,
  issueFlagged,
}

enum IdentityVerificationState {
  pending,
  matched,
  manualVerified,
  mismatch,
  manualReview,
}

class AttendanceRecord {
  AttendanceRecord({
    required this.candidateName,
    required this.registrationNumber,
    required this.hallName,
    required this.seatNumber,
    required this.examTitle,
    required this.state,
    required this.workstationId,
    this.identityState = IdentityVerificationState.pending,
    this.biometricConfidence = 0,
    this.arrivalTimeLabel = '-',
    this.verificationNote = '',
  });

  final String candidateName;
  final String registrationNumber;
  final String hallName;
  final String seatNumber;
  final String examTitle;
  final AttendanceState state;
  final String workstationId;
  final IdentityVerificationState identityState;
  final double biometricConfidence;
  final String arrivalTimeLabel;
  final String verificationNote;

  bool get identityVerified =>
      identityState == IdentityVerificationState.matched ||
      identityState == IdentityVerificationState.manualVerified;

  bool get needsAttention =>
      state == AttendanceState.issueFlagged ||
      identityState == IdentityVerificationState.mismatch ||
      identityState == IdentityVerificationState.manualReview;

  AttendanceRecord copyWith({
    String? candidateName,
    String? registrationNumber,
    String? hallName,
    String? seatNumber,
    String? examTitle,
    AttendanceState? state,
    String? workstationId,
    IdentityVerificationState? identityState,
    double? biometricConfidence,
    String? arrivalTimeLabel,
    String? verificationNote,
  }) {
    return AttendanceRecord(
      candidateName: candidateName ?? this.candidateName,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      hallName: hallName ?? this.hallName,
      seatNumber: seatNumber ?? this.seatNumber,
      examTitle: examTitle ?? this.examTitle,
      state: state ?? this.state,
      workstationId: workstationId ?? this.workstationId,
      identityState: identityState ?? this.identityState,
      biometricConfidence: biometricConfidence ?? this.biometricConfidence,
      arrivalTimeLabel: arrivalTimeLabel ?? this.arrivalTimeLabel,
      verificationNote: verificationNote ?? this.verificationNote,
    );
  }
}
