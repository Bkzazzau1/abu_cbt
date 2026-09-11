import 'workstation_models.dart';

enum WorkstationUsageState {
  inactive,
  active,
  candidateLoggedIn,
  inExam,
  submitted,
}

class InvigilatorWorkstationRecord {
  InvigilatorWorkstationRecord({
    required this.workstationId,
    required this.centerName,
    required this.hallName,
    required this.seatNumber,
    required this.status,
    required this.usageState,
    required this.appInstalled,
    required this.candidateName,
    required this.registrationNumber,
    required this.examTitle,
    required this.lastSeenLabel,
    this.riskFlagged = false,
    this.isNewWorkstation = false,
    this.clientIpAddress = '',
    this.expectedHallIpRange = '',
    this.ipInExpectedRange = true,
    this.riskReasons = const <String>[],
    this.workstationApproved = false,
    this.riskScore = 0,
    this.riskLevel = 'low',
  });

  final String workstationId;
  final String centerName;
  final String hallName;
  final String seatNumber;
  final WorkstationStatus status;
  final WorkstationUsageState usageState;
  final bool appInstalled;
  final String candidateName;
  final String registrationNumber;
  final String examTitle;
  final String lastSeenLabel;
  final bool riskFlagged;
  final bool isNewWorkstation;
  final String clientIpAddress;
  final String expectedHallIpRange;
  final bool ipInExpectedRange;
  final List<String> riskReasons;
  final bool workstationApproved;
  final int riskScore;
  final String riskLevel;

  InvigilatorWorkstationRecord copyWith({
    String? workstationId,
    String? centerName,
    String? hallName,
    String? seatNumber,
    WorkstationStatus? status,
    WorkstationUsageState? usageState,
    bool? appInstalled,
    String? candidateName,
    String? registrationNumber,
    String? examTitle,
    String? lastSeenLabel,
    bool? riskFlagged,
    bool? isNewWorkstation,
    String? clientIpAddress,
    String? expectedHallIpRange,
    bool? ipInExpectedRange,
    List<String>? riskReasons,
    bool? workstationApproved,
    int? riskScore,
    String? riskLevel,
  }) {
    return InvigilatorWorkstationRecord(
      workstationId: workstationId ?? this.workstationId,
      centerName: centerName ?? this.centerName,
      hallName: hallName ?? this.hallName,
      seatNumber: seatNumber ?? this.seatNumber,
      status: status ?? this.status,
      usageState: usageState ?? this.usageState,
      appInstalled: appInstalled ?? this.appInstalled,
      candidateName: candidateName ?? this.candidateName,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      examTitle: examTitle ?? this.examTitle,
      lastSeenLabel: lastSeenLabel ?? this.lastSeenLabel,
      riskFlagged: riskFlagged ?? this.riskFlagged,
      isNewWorkstation: isNewWorkstation ?? this.isNewWorkstation,
      clientIpAddress: clientIpAddress ?? this.clientIpAddress,
      expectedHallIpRange: expectedHallIpRange ?? this.expectedHallIpRange,
      ipInExpectedRange: ipInExpectedRange ?? this.ipInExpectedRange,
      riskReasons: riskReasons ?? this.riskReasons,
      workstationApproved: workstationApproved ?? this.workstationApproved,
      riskScore: riskScore ?? this.riskScore,
      riskLevel: riskLevel ?? this.riskLevel,
    );
  }
}
