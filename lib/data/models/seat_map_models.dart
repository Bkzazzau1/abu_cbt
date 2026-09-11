enum SeatOccupancyState {
  empty,
  expected,
  seated,
  authorized,
  inExam,
  submitted,
  absent,
  issue,
  malpractice,
}

class SeatMapRecord {
  SeatMapRecord({
    required this.hallName,
    required this.seatNumber,
    required this.candidateName,
    required this.registrationNumber,
    required this.examTitle,
    required this.workstationId,
    required this.state,
  });

  final String hallName;
  final String seatNumber;
  final String candidateName;
  final String registrationNumber;
  final String examTitle;
  final String workstationId;
  final SeatOccupancyState state;

  SeatMapRecord copyWith({
    String? hallName,
    String? seatNumber,
    String? candidateName,
    String? registrationNumber,
    String? examTitle,
    String? workstationId,
    SeatOccupancyState? state,
  }) {
    return SeatMapRecord(
      hallName: hallName ?? this.hallName,
      seatNumber: seatNumber ?? this.seatNumber,
      candidateName: candidateName ?? this.candidateName,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      examTitle: examTitle ?? this.examTitle,
      workstationId: workstationId ?? this.workstationId,
      state: state ?? this.state,
    );
  }
}
