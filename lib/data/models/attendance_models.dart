enum AttendanceState {
  expected,
  present,
  absent,
  seated,
  authorized,
  inExam,
  submitted,
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
  });

  final String candidateName;
  final String registrationNumber;
  final String hallName;
  final String seatNumber;
  final String examTitle;
  final AttendanceState state;
  final String workstationId;

  AttendanceRecord copyWith({
    String? candidateName,
    String? registrationNumber,
    String? hallName,
    String? seatNumber,
    String? examTitle,
    AttendanceState? state,
    String? workstationId,
  }) {
    return AttendanceRecord(
      candidateName: candidateName ?? this.candidateName,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      hallName: hallName ?? this.hallName,
      seatNumber: seatNumber ?? this.seatNumber,
      examTitle: examTitle ?? this.examTitle,
      state: state ?? this.state,
      workstationId: workstationId ?? this.workstationId,
    );
  }
}
