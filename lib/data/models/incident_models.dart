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
    required this.workstationId,
    required this.hallName,
    required this.seatNumber,
    required this.candidateName,
    required this.registrationNumber,
    required this.examTitle,
    required this.type,
    required this.severity,
    required this.description,
    required this.reportedAtIso,
  });

  final String workstationId;
  final String hallName;
  final String seatNumber;
  final String candidateName;
  final String registrationNumber;
  final String examTitle;
  final IncidentType type;
  final IncidentSeverity severity;
  final String description;
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
      'reportedAtIso': reportedAtIso,
    };
  }
}
