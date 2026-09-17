enum ManualIdentityVerificationStatus {
  pending,
  approved,
  rejected,
  resolvedByFingerprint;

  String get label {
    switch (this) {
      case ManualIdentityVerificationStatus.pending:
        return 'Pending Review';
      case ManualIdentityVerificationStatus.approved:
        return 'Approved';
      case ManualIdentityVerificationStatus.rejected:
        return 'Rejected';
      case ManualIdentityVerificationStatus.resolvedByFingerprint:
        return 'Resolved by Fingerprint';
    }
  }
}

enum ManualIdentityFailureReason {
  fingerprintNotMatched,
  readerUnavailable,
  poorScan,
  other;

  String get label {
    switch (this) {
      case ManualIdentityFailureReason.fingerprintNotMatched:
        return 'Fingerprint did not match';
      case ManualIdentityFailureReason.readerUnavailable:
        return 'Fingerprint reader unavailable';
      case ManualIdentityFailureReason.poorScan:
        return 'Fingerprint could not be read clearly';
      case ManualIdentityFailureReason.other:
        return 'Other biometric issue';
    }
  }
}

class ManualIdentityVerificationRequest {
  const ManualIdentityVerificationRequest({
    required this.id,
    required this.registrationNumber,
    required this.candidateName,
    required this.department,
    required this.level,
    required this.photoAsset,
    required this.examTitle,
    required this.hallName,
    required this.seatNumber,
    required this.workstationId,
    required this.failureReason,
    required this.fingerprintAttempts,
    required this.requestedAt,
    required this.status,
    this.reviewedAt,
    this.reviewedBy = '',
    this.reviewNote = '',
  });

  final String id;
  final String registrationNumber;
  final String candidateName;
  final String department;
  final String level;
  final String photoAsset;
  final String examTitle;
  final String hallName;
  final String seatNumber;
  final String workstationId;
  final ManualIdentityFailureReason failureReason;
  final int fingerprintAttempts;
  final DateTime requestedAt;
  final ManualIdentityVerificationStatus status;
  final DateTime? reviewedAt;
  final String reviewedBy;
  final String reviewNote;

  bool get isPending => status == ManualIdentityVerificationStatus.pending;
  bool get isApproved => status == ManualIdentityVerificationStatus.approved;
  bool get isRejected => status == ManualIdentityVerificationStatus.rejected;
  bool get isResolvedByFingerprint =>
      status == ManualIdentityVerificationStatus.resolvedByFingerprint;

  ManualIdentityVerificationRequest copyWith({
    String? id,
    String? registrationNumber,
    String? candidateName,
    String? department,
    String? level,
    String? photoAsset,
    String? examTitle,
    String? hallName,
    String? seatNumber,
    String? workstationId,
    ManualIdentityFailureReason? failureReason,
    int? fingerprintAttempts,
    DateTime? requestedAt,
    ManualIdentityVerificationStatus? status,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? reviewNote,
  }) {
    return ManualIdentityVerificationRequest(
      id: id ?? this.id,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      candidateName: candidateName ?? this.candidateName,
      department: department ?? this.department,
      level: level ?? this.level,
      photoAsset: photoAsset ?? this.photoAsset,
      examTitle: examTitle ?? this.examTitle,
      hallName: hallName ?? this.hallName,
      seatNumber: seatNumber ?? this.seatNumber,
      workstationId: workstationId ?? this.workstationId,
      failureReason: failureReason ?? this.failureReason,
      fingerprintAttempts: fingerprintAttempts ?? this.fingerprintAttempts,
      requestedAt: requestedAt ?? this.requestedAt,
      status: status ?? this.status,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewNote: reviewNote ?? this.reviewNote,
    );
  }
}
