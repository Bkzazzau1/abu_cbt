enum MalpracticeType {
  impersonation,
  phoneUse,
  talking,
  unauthorizedMaterial,
  switchingSeat,
  multipleLoginAttempt,
  externalAssistance,
  suspiciousBehavior,
  refusalToComply,
  other,
}

enum MalpracticeSeverity { moderate, major, severe, critical }

class MalpracticeReportModel {
  MalpracticeReportModel({
    required this.workstationId,
    required this.hallName,
    required this.seatNumber,
    required this.candidateName,
    required this.registrationNumber,
    required this.examTitle,
    required this.type,
    required this.severity,
    required this.description,
    required this.actionTaken,
    required this.reportedAtIso,
  });

  final String workstationId;
  final String hallName;
  final String seatNumber;
  final String candidateName;
  final String registrationNumber;
  final String examTitle;
  final MalpracticeType type;
  final MalpracticeSeverity severity;
  final String description;
  final String actionTaken;
  final String reportedAtIso;

  Map<String, dynamic> toJson() {
    return {
      'workstationId': workstationId,
      'hallName': hallName,
      'seatNumber': seatNumber,
      'candidateName': candidateName,
      'registrationNumber': registrationNumber,
      'examTitle': examTitle,
      'type': type.name,
      'severity': severity.name,
      'description': description,
      'actionTaken': actionTaken,
      'reportedAtIso': reportedAtIso,
    };
  }
}
