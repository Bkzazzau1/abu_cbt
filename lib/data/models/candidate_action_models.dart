enum CandidateExamControlState {
  normal,
  paused,
  resumed,
  forceSubmitted,
  lateEntryAllowed,
  seatReassigned,
}

enum SeatReassignmentReason {
  workstationFault,
  networkIssue,
  powerIssue,
  peripheralIssue,
  accessibility,
  supervisorInstruction,
  other,
}

extension SeatReassignmentReasonX on SeatReassignmentReason {
  String get label {
    switch (this) {
      case SeatReassignmentReason.workstationFault:
        return 'Workstation fault';
      case SeatReassignmentReason.networkIssue:
        return 'Network issue';
      case SeatReassignmentReason.powerIssue:
        return 'Power issue';
      case SeatReassignmentReason.peripheralIssue:
        return 'Keyboard / mouse / display issue';
      case SeatReassignmentReason.accessibility:
        return 'Accessibility requirement';
      case SeatReassignmentReason.supervisorInstruction:
        return 'Supervisor instruction';
      case SeatReassignmentReason.other:
        return 'Other';
    }
  }

  bool get marksOldSeatAsTechnicalIssue {
    switch (this) {
      case SeatReassignmentReason.workstationFault:
      case SeatReassignmentReason.networkIssue:
      case SeatReassignmentReason.powerIssue:
      case SeatReassignmentReason.peripheralIssue:
        return true;
      case SeatReassignmentReason.accessibility:
      case SeatReassignmentReason.supervisorInstruction:
      case SeatReassignmentReason.other:
        return false;
    }
  }
}

class SeatReassignmentRecord {
  SeatReassignmentRecord({
    required this.id,
    required this.candidateName,
    required this.registrationNumber,
    required this.hallName,
    required this.oldSeatNumber,
    required this.newSeatNumber,
    required this.oldWorkstationId,
    required this.newWorkstationId,
    required this.reason,
    required this.note,
    required this.createdAt,
  });

  final String id;
  final String candidateName;
  final String registrationNumber;
  final String hallName;
  final String oldSeatNumber;
  final String newSeatNumber;
  final String oldWorkstationId;
  final String newWorkstationId;
  final SeatReassignmentReason reason;
  final String note;
  final DateTime createdAt;
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
