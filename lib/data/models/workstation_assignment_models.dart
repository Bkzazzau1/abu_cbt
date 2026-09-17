enum WorkstationAssignmentMode {
  freeSeating,
  manual,
  systemDistribution,
}

enum WorkstationDistributionMode {
  fixed,
  mixed,
}

enum WorkstationAssignmentStatus {
  reserved,
  locked,
  released,
}

enum WorkstationAssignmentSource {
  freeLogin,
  manual,
  systemFixed,
  systemMixed,
  invigilatorReassignment,
}

enum WorkstationLoginDecisionType {
  allowed,
  workstationNotConfigured,
  workstationUnavailable,
  workstationOccupied,
  candidateLockedElsewhere,
  candidateAssignedElsewhere,
  manualAssignmentRequired,
  systemDistributionRequired,
}

class WorkstationAssignmentPolicy {
  const WorkstationAssignmentPolicy({
    required this.hallName,
    required this.examTitle,
    required this.mode,
    required this.distributionMode,
    this.lockAfterLogin = true,
  });

  final String hallName;
  final String examTitle;
  final WorkstationAssignmentMode mode;
  final WorkstationDistributionMode distributionMode;
  final bool lockAfterLogin;

  WorkstationAssignmentPolicy copyWith({
    String? hallName,
    String? examTitle,
    WorkstationAssignmentMode? mode,
    WorkstationDistributionMode? distributionMode,
    bool? lockAfterLogin,
  }) {
    return WorkstationAssignmentPolicy(
      hallName: hallName ?? this.hallName,
      examTitle: examTitle ?? this.examTitle,
      mode: mode ?? this.mode,
      distributionMode: distributionMode ?? this.distributionMode,
      lockAfterLogin: lockAfterLogin ?? this.lockAfterLogin,
    );
  }
}

class CandidateAssignmentRequest {
  const CandidateAssignmentRequest({
    required this.registrationNumber,
    required this.candidateName,
    required this.examTitle,
    required this.hallName,
  });

  final String registrationNumber;
  final String candidateName;
  final String examTitle;
  final String hallName;
}

class CandidateWorkstationAssignment {
  const CandidateWorkstationAssignment({
    required this.id,
    required this.registrationNumber,
    required this.candidateName,
    required this.examTitle,
    required this.hallName,
    required this.seatNumber,
    required this.workstationId,
    required this.status,
    required this.source,
    required this.assignedAt,
    required this.assignedBy,
    this.lockedAt,
  });

  final String id;
  final String registrationNumber;
  final String candidateName;
  final String examTitle;
  final String hallName;
  final String seatNumber;
  final String workstationId;
  final WorkstationAssignmentStatus status;
  final WorkstationAssignmentSource source;
  final DateTime assignedAt;
  final String assignedBy;
  final DateTime? lockedAt;

  bool get isReserved => status == WorkstationAssignmentStatus.reserved;
  bool get isLocked => status == WorkstationAssignmentStatus.locked;

  CandidateWorkstationAssignment copyWith({
    String? id,
    String? registrationNumber,
    String? candidateName,
    String? examTitle,
    String? hallName,
    String? seatNumber,
    String? workstationId,
    WorkstationAssignmentStatus? status,
    WorkstationAssignmentSource? source,
    DateTime? assignedAt,
    String? assignedBy,
    DateTime? lockedAt,
  }) {
    return CandidateWorkstationAssignment(
      id: id ?? this.id,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      candidateName: candidateName ?? this.candidateName,
      examTitle: examTitle ?? this.examTitle,
      hallName: hallName ?? this.hallName,
      seatNumber: seatNumber ?? this.seatNumber,
      workstationId: workstationId ?? this.workstationId,
      status: status ?? this.status,
      source: source ?? this.source,
      assignedAt: assignedAt ?? this.assignedAt,
      assignedBy: assignedBy ?? this.assignedBy,
      lockedAt: lockedAt ?? this.lockedAt,
    );
  }
}

class WorkstationLoginDecision {
  const WorkstationLoginDecision({
    required this.type,
    required this.message,
    this.assignment,
  });

  final WorkstationLoginDecisionType type;
  final String message;
  final CandidateWorkstationAssignment? assignment;

  bool get allowed => type == WorkstationLoginDecisionType.allowed;
}

extension WorkstationAssignmentModeLabel on WorkstationAssignmentMode {
  String get label {
    switch (this) {
      case WorkstationAssignmentMode.freeSeating:
        return 'Free Seating';
      case WorkstationAssignmentMode.manual:
        return 'Manual Assignment';
      case WorkstationAssignmentMode.systemDistribution:
        return 'System Distribution';
    }
  }

  String get description {
    switch (this) {
      case WorkstationAssignmentMode.freeSeating:
        return 'Candidates may use any available workstation. The first successful login locks that candidate to the workstation.';
      case WorkstationAssignmentMode.manual:
        return 'The invigilator reserves a specific workstation for each candidate before login.';
      case WorkstationAssignmentMode.systemDistribution:
        return 'The system reserves available healthy workstations for candidates before login.';
    }
  }
}

extension WorkstationDistributionModeLabel on WorkstationDistributionMode {
  String get label => this == WorkstationDistributionMode.fixed
      ? 'Fixed / Sequential'
      : 'Mixed / Randomized';
}
