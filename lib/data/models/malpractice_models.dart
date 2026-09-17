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
    this.id = '',
    required this.workstationId,
    this.centerName = '',
    required this.hallName,
    required this.seatNumber,
    required this.candidateName,
    required this.registrationNumber,
    required this.examTitle,
    required this.type,
    required this.severity,
    required this.description,
    required this.actionTaken,
    this.reportedBy = '',
    required this.reportedAtIso,
    this.escalated = false,
    this.escalatedBy = '',
    this.escalatedAtIso = '',
    this.examTerminated = false,
  });

  final String id;
  final String workstationId;
  final String centerName;
  final String hallName;
  final String seatNumber;
  final String candidateName;
  final String registrationNumber;
  final String examTitle;
  final MalpracticeType type;
  final MalpracticeSeverity severity;
  final String description;
  final String actionTaken;
  final String reportedBy;
  final String reportedAtIso;
  final bool escalated;
  final String escalatedBy;
  final String escalatedAtIso;
  final bool examTerminated;

  Map<String, dynamic> toJson() {
    return {
      'workstationId': workstationId,
      'centerName': centerName,
      'hallName': hallName,
      'seatNumber': seatNumber,
      'candidateName': candidateName,
      'registrationNumber': registrationNumber,
      'examTitle': examTitle,
      'malpracticeType': type.name,
      'severity': severity.name,
      'description': description,
      'actionTaken': actionTaken,
      'reportedBy': reportedBy,
      'reportedAtIso': reportedAtIso,
    };
  }

  factory MalpracticeReportModel.fromJson(Map<String, dynamic> json) {
    return MalpracticeReportModel(
      id: (json['id'] ?? '').toString(),
      workstationId: (json['workstationId'] ?? '').toString(),
      centerName: (json['centerName'] ?? '').toString(),
      hallName: (json['hallName'] ?? '').toString(),
      seatNumber: (json['seatNumber'] ?? '').toString(),
      candidateName: (json['candidateName'] ?? '').toString(),
      registrationNumber: (json['registrationNumber'] ?? '').toString(),
      examTitle: (json['examTitle'] ?? '').toString(),
      type: MalpracticeType.values.firstWhere(
        (e) => e.name == (json['malpracticeType'] ?? '').toString(),
        orElse: () => MalpracticeType.other,
      ),
      severity: MalpracticeSeverity.values.firstWhere(
        (e) => e.name == (json['severity'] ?? '').toString(),
        orElse: () => MalpracticeSeverity.major,
      ),
      description: (json['description'] ?? '').toString(),
      actionTaken: (json['actionTaken'] ?? '').toString(),
      reportedBy: (json['reportedBy'] ?? '').toString(),
      reportedAtIso: (json['reportedAtIso'] ?? '').toString(),
      escalated: json['escalated'] == true,
      escalatedBy: (json['escalatedBy'] ?? '').toString(),
      escalatedAtIso: (json['escalatedAtIso'] ?? '').toString(),
      examTerminated: json['examTerminated'] == true,
    );
  }
}
