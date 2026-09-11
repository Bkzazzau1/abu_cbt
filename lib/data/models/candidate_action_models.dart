enum CandidateExamControlState {
  normal,
  paused,
  resumed,
  forceSubmitted,
  lateEntryAllowed,
  seatReassigned,
}

class CandidateActionContext {
  CandidateActionContext({
    required this.workstationId,
    required this.hallName,
    required this.seatNumber,
    required this.candidateName,
    required this.registrationNumber,
    required this.examTitle,
    required this.currentState,
    required this.note,
  });

  final String workstationId;
  final String hallName;
  final String seatNumber;
  final String candidateName;
  final String registrationNumber;
  final String examTitle;
  final CandidateExamControlState currentState;
  final String note;

  CandidateActionContext copyWith({
    String? workstationId,
    String? hallName,
    String? seatNumber,
    String? candidateName,
    String? registrationNumber,
    String? examTitle,
    CandidateExamControlState? currentState,
    String? note,
  }) {
    return CandidateActionContext(
      workstationId: workstationId ?? this.workstationId,
      hallName: hallName ?? this.hallName,
      seatNumber: seatNumber ?? this.seatNumber,
      candidateName: candidateName ?? this.candidateName,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      examTitle: examTitle ?? this.examTitle,
      currentState: currentState ?? this.currentState,
      note: note ?? this.note,
    );
  }
}
