enum CandidateCheckInStatus {
  pending,
  checkedIn,
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
  });

  final String workstationId;
  final String hallName;
  final String seatNumber;
  final String candidateName;
  final String registrationNumber;
  final String examTitle;
  final CandidateCheckInStatus status;
  final String note;

  CandidateCheckInRecord copyWith({
    String? workstationId,
    String? hallName,
    String? seatNumber,
    String? candidateName,
    String? registrationNumber,
    String? examTitle,
    CandidateCheckInStatus? status,
    String? note,
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
    );
  }
}
