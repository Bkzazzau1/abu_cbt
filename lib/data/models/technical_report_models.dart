enum TechnicalIssueCategory {
  workstation,
  network,
  power,
  peripheral,
  application,
  biometric,
  display,
  other,
}

extension TechnicalIssueCategoryX on TechnicalIssueCategory {
  String get label {
    switch (this) {
      case TechnicalIssueCategory.workstation:
        return 'Workstation fault';
      case TechnicalIssueCategory.network:
        return 'Network issue';
      case TechnicalIssueCategory.power:
        return 'Power issue';
      case TechnicalIssueCategory.peripheral:
        return 'Keyboard / mouse / peripheral';
      case TechnicalIssueCategory.application:
        return 'CBT application';
      case TechnicalIssueCategory.biometric:
        return 'Biometric device';
      case TechnicalIssueCategory.display:
        return 'Display issue';
      case TechnicalIssueCategory.other:
        return 'Other';
    }
  }
}

enum TechnicalIssueSeverity { low, medium, high, critical }

extension TechnicalIssueSeverityX on TechnicalIssueSeverity {
  String get label {
    switch (this) {
      case TechnicalIssueSeverity.low:
        return 'Low';
      case TechnicalIssueSeverity.medium:
        return 'Medium';
      case TechnicalIssueSeverity.high:
        return 'High';
      case TechnicalIssueSeverity.critical:
        return 'Critical';
    }
  }
}

enum TechnicalIssueStatus { open, inProgress, resolved }

extension TechnicalIssueStatusX on TechnicalIssueStatus {
  String get label {
    switch (this) {
      case TechnicalIssueStatus.open:
        return 'Open';
      case TechnicalIssueStatus.inProgress:
        return 'In Progress';
      case TechnicalIssueStatus.resolved:
        return 'Resolved';
    }
  }
}

class TechnicalReportRecord {
  TechnicalReportRecord({
    required this.id,
    required this.hallName,
    required this.seatNumber,
    required this.workstationId,
    required this.candidateName,
    required this.registrationNumber,
    required this.category,
    required this.severity,
    required this.description,
    required this.actionTaken,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
    this.sourceSeatReassignmentId,
  });

  final String id;
  final String hallName;
  final String seatNumber;
  final String workstationId;
  final String candidateName;
  final String registrationNumber;
  final TechnicalIssueCategory category;
  final TechnicalIssueSeverity severity;
  final String description;
  final String actionTaken;
  final TechnicalIssueStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? sourceSeatReassignmentId;

  TechnicalReportRecord copyWith({
    String? hallName,
    String? seatNumber,
    String? workstationId,
    String? candidateName,
    String? registrationNumber,
    TechnicalIssueCategory? category,
    TechnicalIssueSeverity? severity,
    String? description,
    String? actionTaken,
    TechnicalIssueStatus? status,
    DateTime? createdAt,
    DateTime? resolvedAt,
    String? sourceSeatReassignmentId,
  }) {
    return TechnicalReportRecord(
      id: id,
      hallName: hallName ?? this.hallName,
      seatNumber: seatNumber ?? this.seatNumber,
      workstationId: workstationId ?? this.workstationId,
      candidateName: candidateName ?? this.candidateName,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      category: category ?? this.category,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      actionTaken: actionTaken ?? this.actionTaken,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      sourceSeatReassignmentId:
          sourceSeatReassignmentId ?? this.sourceSeatReassignmentId,
    );
  }
}

enum WorkstationHealthState { healthy, degraded, offline, critical }

class WorkstationHealthRecord {
  WorkstationHealthRecord({
    required this.hallName,
    required this.seatNumber,
    required this.workstationId,
    required this.state,
    required this.networkLabel,
    required this.appLabel,
    required this.lastSeenLabel,
    required this.issueLabel,
  });

  final String hallName;
  final String seatNumber;
  final String workstationId;
  final WorkstationHealthState state;
  final String networkLabel;
  final String appLabel;
  final String lastSeenLabel;
  final String issueLabel;
}
