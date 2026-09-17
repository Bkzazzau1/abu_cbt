enum ExamControlAuditType {
  paused,
  resumed,
  lateEntryAllowed,
  forceSubmitted;

  String get label {
    switch (this) {
      case ExamControlAuditType.paused:
        return 'Exam Paused';
      case ExamControlAuditType.resumed:
        return 'Exam Resumed';
      case ExamControlAuditType.lateEntryAllowed:
        return 'Late Entry Allowed';
      case ExamControlAuditType.forceSubmitted:
        return 'Force Submitted';
    }
  }
}

class ExamControlAuditRecord {
  const ExamControlAuditRecord({
    required this.id,
    required this.registrationNumber,
    required this.candidateName,
    required this.examTitle,
    required this.hallName,
    required this.seatNumber,
    required this.workstationId,
    required this.type,
    required this.createdAt,
    required this.actedBy,
    this.note = '',
  });

  final String id;
  final String registrationNumber;
  final String candidateName;
  final String examTitle;
  final String hallName;
  final String seatNumber;
  final String workstationId;
  final ExamControlAuditType type;
  final DateTime createdAt;
  final String actedBy;
  final String note;
}
