enum HallCandidateLiveState {
  ready,
  checkedIn,
  authorized,
  inExam,
  submitted,
  offline,
  issueFlagged,
  malpracticeFlagged,
  absent,
}

class HallMonitorRecord {
  HallMonitorRecord({
    required this.workstationId,
    required this.hallName,
    required this.seatNumber,
    required this.candidateName,
    required this.registrationNumber,
    required this.examTitle,
    required this.state,
    required this.lastSeenLabel,
    required this.hasIncident,
    required this.hasMalpractice,
  });

  final String workstationId;
  final String hallName;
  final String seatNumber;
  final String candidateName;
  final String registrationNumber;
  final String examTitle;
  final HallCandidateLiveState state;
  final String lastSeenLabel;
  final bool hasIncident;
  final bool hasMalpractice;

  HallMonitorRecord copyWith({
    String? workstationId,
    String? hallName,
    String? seatNumber,
    String? candidateName,
    String? registrationNumber,
    String? examTitle,
    HallCandidateLiveState? state,
    String? lastSeenLabel,
    bool? hasIncident,
    bool? hasMalpractice,
  }) {
    return HallMonitorRecord(
      workstationId: workstationId ?? this.workstationId,
      hallName: hallName ?? this.hallName,
      seatNumber: seatNumber ?? this.seatNumber,
      candidateName: candidateName ?? this.candidateName,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      examTitle: examTitle ?? this.examTitle,
      state: state ?? this.state,
      lastSeenLabel: lastSeenLabel ?? this.lastSeenLabel,
      hasIncident: hasIncident ?? this.hasIncident,
      hasMalpractice: hasMalpractice ?? this.hasMalpractice,
    );
  }
}
