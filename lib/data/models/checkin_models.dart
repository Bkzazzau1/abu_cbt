import 'attendance_models.dart';

enum CandidateCheckInStatus {
  pending,
  checkedIn,
  verified,
  authorized,
  absent,
  issueFlagged,
}

class CandidateCheckInRecord {
  CandidateCheckInRecord({
    required this.workstationId,
    required this.hallName,
    required this.seatNumber,
    required this.candidateName,
    required this.registrationNumber,
    required this.examTitle,
    required this.status,
    required this.note,
    this.identityState = IdentityVerificationState.pending,
    this.biometricConfidence = 0,
    this.seatVerified = false,
    this.examVerified = false,
  });

  final String workstationId;
  final String hallName;
  final String seatNumber;
  final String candidateName;
  final String registrationNumber;
  final String examTitle;
  final CandidateCheckInStatus status;
  final String note;
  final IdentityVerificationState identityState;
  final double biometricConfidence;
  final bool seatVerified;
  final bool examVerified;

  bool get identityVerified => identityState == IdentityVerificationState.matched;
  bool get canAuthorize => identityVerified && seatVerified && examVerified;
  bool get needsAttention =>
      status == CandidateCheckInStatus.issueFlagged ||
      identityState == IdentityVerificationState.mismatch ||
      identityState == IdentityVerificationState.manualReview;

  CandidateCheckInRecord copyWith({
    String? workstationId,
    String? hallName,
    String? seatNumber,
    String? candidateName,
    String? registrationNumber,
    String? examTitle,
    CandidateCheckInStatus? status,
    String? note,
    IdentityVerificationState? identityState,
    double? biometricConfidence,
    bool? seatVerified,
    bool? examVerified,
  }) {
    return CandidateCheckInRecord(
      workstationId: workstationId ?? this.workstationId,
      hallName: hallName ?? this.hallName,
      seatNumber: seatNumber ?? this.seatNumber,
      candidateName: candidateName ?? this.candidateName,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      examTitle: examTitle ?? this.examTitle,
      status: status ?? this.status,
      note: note ?? this.note,
      identityState: identityState ?? this.identityState,
      biometricConfidence: biometricConfidence ?? this.biometricConfidence,
      seatVerified: seatVerified ?? this.seatVerified,
      examVerified: examVerified ?? this.examVerified,
    );
  }
}
