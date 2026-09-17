enum IncidentType {
  wrongSeat,
  technicalIssue,
  lateArrival,
  misconduct,
  powerFailure,
  networkProblem,
  identityMismatch,
  deviceIssue,
  other,
}

enum IncidentSeverity { low, medium, high, critical }

class IncidentReportModel {
  IncidentReportModel({
    this.id = '',
    required this.workstationId,
    required this.hallName,
    required this.seatNumber,
    required this.candidateName,
    required this.registrationNumber,
    required this.examTitle,
    required this.type,
    required this.severity,
    required this.description,
    this.actionTaken = '',
    this.evidenceNote = '',
    this.reportedBy = '',
    required this.reportedAtIso,
  });

  final String id;
  final String workstationId;
  final String hallName;
  final String seatNumber;
  final String candidateName;
  final String registrationNumber;
  final String examTitle;
  final IncidentType type;
  final IncidentSeverity severity;
  final String description;
  final String actionTaken;
  final String evidenceNote;
  final String reportedBy;
  final String reportedAtIso;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
      'evidenceNote': evidenceNote,
      'reportedBy': reportedBy,
      'reportedAtIso': reportedAtIso,
    };
  }
}
