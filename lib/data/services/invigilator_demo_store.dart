import 'package:get/get.dart';

import '../models/candidate_action_models.dart';
import '../models/seat_map_models.dart';
import '../models/technical_report_models.dart';
import 'seat_map_mock_service.dart';

class InvigilatorDemoStore extends GetxService {
  final seats = <SeatMapRecord>[].obs;
  final seatReassignments = <SeatReassignmentRecord>[].obs;
  final technicalReports = <TechnicalReportRecord>[].obs;

  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    seats.assignAll(await SeatMapMockService.loadSeatMap());
    _seedTechnicalReports();
    _loaded = true;
  }

  List<SeatMapRecord> availableSeatsForHall(String hallName) {
    final items = seats
        .where(
          (seat) =>
              seat.hallName == hallName &&
              seat.state == SeatOccupancyState.empty,
        )
        .toList();
    items.sort((a, b) => a.seatNumber.compareTo(b.seatNumber));
    return items;
  }

  SeatMapRecord? findSeat(String hallName, String seatNumber) {
    for (final seat in seats) {
      if (seat.hallName == hallName && seat.seatNumber == seatNumber) {
        return seat;
      }
    }
    return null;
  }

  SeatReassignmentRecord? latestReassignmentFor(String registrationNumber) {
    for (final event in seatReassignments) {
      if (event.registrationNumber == registrationNumber) return event;
    }
    return null;
  }

  Future<SeatReassignmentRecord> reassignSeat({
    required CandidateActionContext candidate,
    required String destinationSeatNumber,
    required SeatReassignmentReason reason,
    required String note,
  }) async {
    await ensureLoaded();

    final source = findSeat(candidate.hallName, candidate.seatNumber);
    final destination = findSeat(candidate.hallName, destinationSeatNumber);

    if (destination == null) {
      throw StateError('The selected destination seat no longer exists.');
    }
    if (destination.state != SeatOccupancyState.empty) {
      throw StateError('The selected destination seat is no longer available.');
    }
    if (destination.seatNumber == candidate.seatNumber) {
      throw StateError('Choose a different destination seat.');
    }

    await Future.delayed(const Duration(milliseconds: 450));

    if (source != null) {
      _replaceSeat(
        source.copyWith(
          candidateName: '',
          registrationNumber: '',
          examTitle: '',
          state: reason.marksOldSeatAsTechnicalIssue
              ? SeatOccupancyState.issue
              : SeatOccupancyState.empty,
        ),
      );
    }

    _replaceSeat(
      destination.copyWith(
        candidateName: candidate.candidateName,
        registrationNumber: candidate.registrationNumber,
        examTitle: candidate.examTitle,
        state: SeatOccupancyState.inExam,
      ),
    );

    final event = SeatReassignmentRecord(
      id: 'MOVE-${DateTime.now().microsecondsSinceEpoch}',
      candidateName: candidate.candidateName,
      registrationNumber: candidate.registrationNumber,
      hallName: candidate.hallName,
      oldSeatNumber: candidate.seatNumber,
      newSeatNumber: destination.seatNumber,
      oldWorkstationId: source?.workstationId ?? candidate.workstationId,
      newWorkstationId: destination.workstationId,
      reason: reason,
      note: note,
      createdAt: DateTime.now(),
    );

    seatReassignments.insert(0, event);

    if (reason.marksOldSeatAsTechnicalIssue) {
      technicalReports.insert(
        0,
        TechnicalReportRecord(
          id: 'TECH-${DateTime.now().microsecondsSinceEpoch}',
          hallName: candidate.hallName,
          seatNumber: candidate.seatNumber,
          workstationId: source?.workstationId ?? candidate.workstationId,
          candidateName: candidate.candidateName,
          registrationNumber: candidate.registrationNumber,
          category: _technicalCategoryFor(reason),
          severity: reason == SeatReassignmentReason.powerIssue
              ? TechnicalIssueSeverity.high
              : TechnicalIssueSeverity.medium,
          description:
              '${reason.label} affected the candidate workstation during the examination.',
          actionTaken:
              'Candidate reassigned from ${candidate.seatNumber} to ${destination.seatNumber}; original workstation isolated for technical review.',
          status: TechnicalIssueStatus.open,
          createdAt: DateTime.now(),
          sourceSeatReassignmentId: event.id,
        ),
      );
    }

    return event;
  }

  void updateTechnicalReportStatus(
    String reportId,
    TechnicalIssueStatus status,
  ) {
    final index = technicalReports.indexWhere((report) => report.id == reportId);
    if (index < 0) return;
    final current = technicalReports[index];
    technicalReports[index] = current.copyWith(
      status: status,
      resolvedAt: status == TechnicalIssueStatus.resolved
          ? DateTime.now()
          : current.resolvedAt,
    );
    technicalReports.refresh();
  }

  List<WorkstationHealthRecord> buildWorkstationHealth() {
    return seats.map((seat) {
      final reports = technicalReports
          .where(
            (report) =>
                report.workstationId == seat.workstationId &&
                report.status != TechnicalIssueStatus.resolved,
          )
          .toList();

      WorkstationHealthState state = WorkstationHealthState.healthy;
      String network = 'Good';
      String app = 'Healthy';
      String lastSeen = '4 sec ago';
      String issue = '—';

      if (reports.isNotEmpty || seat.state == SeatOccupancyState.issue) {
        final report = reports.isEmpty ? null : reports.first;
        final severity = report?.severity;
        state = severity == TechnicalIssueSeverity.critical
            ? WorkstationHealthState.critical
            : WorkstationHealthState.degraded;
        issue = report?.category.label ?? 'Technical issue';
        if (report?.category == TechnicalIssueCategory.network) {
          network = 'Degraded • 420 ms';
        }
        if (report?.category == TechnicalIssueCategory.application) {
          app = 'Attention required';
        }
        if (report?.category == TechnicalIssueCategory.power) {
          state = WorkstationHealthState.offline;
          network = 'Offline';
          app = 'Unavailable';
          lastSeen = '2 min ago';
        }
      }

      return WorkstationHealthRecord(
        hallName: seat.hallName,
        seatNumber: seat.seatNumber,
        workstationId: seat.workstationId,
        state: state,
        networkLabel: network,
        appLabel: app,
        lastSeenLabel: lastSeen,
        issueLabel: issue,
      );
    }).toList();
  }

  void _replaceSeat(SeatMapRecord updated) {
    final index = seats.indexWhere(
      (seat) =>
          seat.hallName == updated.hallName &&
          seat.seatNumber == updated.seatNumber,
    );
    if (index < 0) return;
    seats[index] = updated;
    seats.refresh();
  }

  TechnicalIssueCategory _technicalCategoryFor(SeatReassignmentReason reason) {
    switch (reason) {
      case SeatReassignmentReason.workstationFault:
        return TechnicalIssueCategory.workstation;
      case SeatReassignmentReason.networkIssue:
        return TechnicalIssueCategory.network;
      case SeatReassignmentReason.powerIssue:
        return TechnicalIssueCategory.power;
      case SeatReassignmentReason.peripheralIssue:
        return TechnicalIssueCategory.peripheral;
      case SeatReassignmentReason.accessibility:
      case SeatReassignmentReason.supervisorInstruction:
      case SeatReassignmentReason.other:
        return TechnicalIssueCategory.other;
    }
  }

  void _seedTechnicalReports() {
    if (technicalReports.isNotEmpty) return;
    final now = DateTime.now();

    technicalReports.assignAll([
      TechnicalReportRecord(
        id: 'TECH-DEMO-001',
        hallName: 'Hall A',
        seatNumber: 'A-07',
        workstationId: 'ABU-CBT-A07-WS',
        candidateName: 'Aisha Bello',
        registrationNumber: 'ABU/CSC/007',
        category: TechnicalIssueCategory.network,
        severity: TechnicalIssueSeverity.medium,
        description:
            'Intermittent network latency detected while answer synchronization was running.',
        actionTaken:
            'Connection monitored; local exam remained active and answer buffer retained.',
        status: TechnicalIssueStatus.inProgress,
        createdAt: now.subtract(const Duration(minutes: 18)),
      ),
      TechnicalReportRecord(
        id: 'TECH-DEMO-002',
        hallName: 'Hall A',
        seatNumber: 'A-34',
        workstationId: 'ABU-CBT-A34-WS',
        candidateName: 'Fadila Umar',
        registrationNumber: 'ABU/CSC/034',
        category: TechnicalIssueCategory.application,
        severity: TechnicalIssueSeverity.high,
        description:
            'CBT client became unresponsive during navigation between questions.',
        actionTaken:
            'Session preserved locally; workstation isolated pending technical review.',
        status: TechnicalIssueStatus.open,
        createdAt: now.subtract(const Duration(minutes: 9)),
      ),
      TechnicalReportRecord(
        id: 'TECH-DEMO-003',
        hallName: 'Hall B',
        seatNumber: 'B-12',
        workstationId: 'ABU-CBT-B12-WS',
        candidateName: 'Hauwa Ibrahim',
        registrationNumber: 'ABU/GST/060',
        category: TechnicalIssueCategory.peripheral,
        severity: TechnicalIssueSeverity.low,
        description: 'Mouse click intermittently failed during pre-exam check.',
        actionTaken: 'Mouse replaced before examination start.',
        status: TechnicalIssueStatus.resolved,
        createdAt: now.subtract(const Duration(hours: 1, minutes: 12)),
        resolvedAt: now.subtract(const Duration(minutes: 58)),
      ),
      TechnicalReportRecord(
        id: 'TECH-DEMO-004',
        hallName: 'Hall B',
        seatNumber: 'B-21',
        workstationId: 'ABU-CBT-B21-WS',
        candidateName: 'Habiba Musa',
        registrationNumber: 'ABU/GST/069',
        category: TechnicalIssueCategory.power,
        severity: TechnicalIssueSeverity.critical,
        description: 'Workstation lost power unexpectedly during the session.',
        actionTaken:
            'Candidate exam paused and candidate prepared for reassignment to a healthy workstation.',
        status: TechnicalIssueStatus.open,
        createdAt: now.subtract(const Duration(minutes: 4)),
      ),
    ]);
  }
}
