import 'invigilator_models.dart';
import 'malpractice_models.dart';
import 'evidence_models.dart';
import 'workstation_models.dart';

class WorkstationPresenceRecord {
  WorkstationPresenceRecord({
    required this.workstationId,
    required this.centerName,
    required this.hallName,
    required this.seatNumber,
    required this.registrationNumber,
    required this.candidateName,
    required this.examTitle,
    required this.usageState,
    required this.workstationStatus,
    required this.eventAtIso,
    this.riskFlagged = false,
    this.isNewWorkstation = false,
    this.clientIpAddress = '',
    this.expectedHallIpRange = '',
    this.ipInExpectedRange = true,
    this.riskReasons = const <String>[],
    this.workstationApproved = false,
    this.riskScore = 0,
    this.riskLevel = 'low',
    this.checkInMismatch = false,
    this.checkInMismatchReason = '',
    this.similarityFlagged = false,
    this.similarityReason = '',
  });

  final String workstationId;
  final String centerName;
  final String hallName;
  final String seatNumber;
  final String registrationNumber;
  final String candidateName;
  final String examTitle;
  final WorkstationUsageState usageState;
  final WorkstationStatus workstationStatus;
  final String eventAtIso;
  final bool riskFlagged;
  final bool isNewWorkstation;
  final String clientIpAddress;
  final String expectedHallIpRange;
  final bool ipInExpectedRange;
  final List<String> riskReasons;
  final bool workstationApproved;
  final int riskScore;
  final String riskLevel;
  final bool checkInMismatch;
  final String checkInMismatchReason;
  final bool similarityFlagged;
  final String similarityReason;

  Map<String, dynamic> toJson() {
    return {
      'workstationId': workstationId,
      'centerName': centerName,
      'hallName': hallName,
      'seatNumber': seatNumber,
      'registrationNumber': registrationNumber,
      'candidateName': candidateName,
      'examTitle': examTitle,
      'usageState': usageState.name,
      'workstationStatus': workstationStatus.name,
      'eventAtIso': eventAtIso,
      'riskFlagged': riskFlagged,
      'isNewWorkstation': isNewWorkstation,
      'clientIpAddress': clientIpAddress,
      'expectedHallIpRange': expectedHallIpRange,
      'ipInExpectedRange': ipInExpectedRange,
      'riskReasons': riskReasons,
      'workstationApproved': workstationApproved,
      'riskScore': riskScore,
      'riskLevel': riskLevel,
      'checkInMismatch': checkInMismatch,
      'checkInMismatchReason': checkInMismatchReason,
      'similarityFlagged': similarityFlagged,
      'similarityReason': similarityReason,
    };
  }

  factory WorkstationPresenceRecord.fromJson(Map<String, dynamic> json) {
    final status = WorkstationStatus.values.firstWhere(
      (e) => e.name == (json['workstationStatus'] ?? '').toString(),
      orElse: () => WorkstationStatus.pending,
    );
    final approved = json.containsKey('workstationApproved')
        ? json['workstationApproved'] == true
        : status == WorkstationStatus.whitelisted;

    return WorkstationPresenceRecord(
      workstationId: (json['workstationId'] ?? '').toString(),
      centerName: (json['centerName'] ?? '').toString(),
      hallName: (json['hallName'] ?? '').toString(),
      seatNumber: (json['seatNumber'] ?? '').toString(),
      registrationNumber: (json['registrationNumber'] ?? '').toString(),
      candidateName: (json['candidateName'] ?? '').toString(),
      examTitle: (json['examTitle'] ?? '').toString(),
      usageState: WorkstationUsageState.values.firstWhere(
        (e) => e.name == (json['usageState'] ?? '').toString(),
        orElse: () => WorkstationUsageState.inactive,
      ),
      workstationStatus: status,
      eventAtIso: (json['eventAtIso'] ?? '').toString(),
      riskFlagged: json['riskFlagged'] == true,
      isNewWorkstation: json['isNewWorkstation'] == true,
      clientIpAddress: (json['clientIpAddress'] ?? '').toString(),
      expectedHallIpRange: (json['expectedHallIpRange'] ?? '').toString(),
      ipInExpectedRange: json['ipInExpectedRange'] != false,
      riskReasons: (json['riskReasons'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList(),
      workstationApproved: approved,
      riskScore: json['riskScore'] is int
          ? json['riskScore'] as int
          : int.tryParse((json['riskScore'] ?? '0').toString()) ?? 0,
      riskLevel: (json['riskLevel'] ?? 'low').toString(),
      checkInMismatch: json['checkInMismatch'] == true,
      checkInMismatchReason: (json['checkInMismatchReason'] ?? '').toString(),
      similarityFlagged: json['similarityFlagged'] == true,
      similarityReason: (json['similarityReason'] ?? '').toString(),
    );
  }
}

class WorkstationPresenceEnvelope {
  WorkstationPresenceEnvelope({
    required this.kind,
    this.records = const <WorkstationPresenceRecord>[],
    this.record,
    this.errorMessage,
    this.evidenceEvents = const <EvidenceEvent>[],
    this.evidenceEvent,
    this.malpracticeReports = const <MalpracticeReportModel>[],
    this.malpracticeReport,
    this.commandAction,
    this.commandReason,
    this.commandIssuedBy,
  });

  final String kind;
  final List<WorkstationPresenceRecord> records;
  final WorkstationPresenceRecord? record;
  final String? errorMessage;
  final List<EvidenceEvent> evidenceEvents;
  final EvidenceEvent? evidenceEvent;
  final List<MalpracticeReportModel> malpracticeReports;
  final MalpracticeReportModel? malpracticeReport;
  final String? commandAction;
  final String? commandReason;
  final String? commandIssuedBy;

  factory WorkstationPresenceEnvelope.fromJson(Map<String, dynamic> json) {
    final kind = (json['kind'] ?? '').toString();
    if (kind == 'snapshot') {
      final list = (json['records'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .map(WorkstationPresenceRecord.fromJson)
          .toList();
      return WorkstationPresenceEnvelope(kind: kind, records: list);
    }

    if (kind == 'presenceUpdate') {
      final raw = json['record'];
      if (raw is Map) {
        return WorkstationPresenceEnvelope(
          kind: kind,
          record: WorkstationPresenceRecord.fromJson(
            Map<String, dynamic>.from(raw),
          ),
        );
      }
    }

    if (kind == 'evidenceSnapshot') {
      final list = (json['events'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .map(EvidenceEvent.fromJson)
          .toList();
      return WorkstationPresenceEnvelope(kind: kind, evidenceEvents: list);
    }

    if (kind == 'evidenceUpdate') {
      final raw = json['event'];
      if (raw is Map) {
        return WorkstationPresenceEnvelope(
          kind: kind,
          evidenceEvent: EvidenceEvent.fromJson(
            Map<String, dynamic>.from(raw),
          ),
        );
      }
    }

    if (kind == 'malpracticeSnapshot') {
      final list = (json['reports'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .map(MalpracticeReportModel.fromJson)
          .toList();
      return WorkstationPresenceEnvelope(kind: kind, malpracticeReports: list);
    }

    if (kind == 'malpracticeUpdate') {
      final raw = json['report'];
      if (raw is Map) {
        return WorkstationPresenceEnvelope(
          kind: kind,
          malpracticeReport: MalpracticeReportModel.fromJson(
            Map<String, dynamic>.from(raw),
          ),
        );
      }
    }

    if (kind == 'command') {
      return WorkstationPresenceEnvelope(
        kind: kind,
        commandAction: (json['action'] ?? '').toString(),
        commandReason: (json['reason'] ?? '').toString(),
        commandIssuedBy: (json['issuedBy'] ?? '').toString(),
      );
    }

    if (kind == 'error') {
      return WorkstationPresenceEnvelope(
        kind: kind,
        errorMessage: (json['message'] ?? '').toString(),
      );
    }

    return WorkstationPresenceEnvelope(kind: kind);
  }
}
