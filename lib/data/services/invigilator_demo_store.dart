import 'dart:math';

import 'package:get/get.dart';

import '../models/candidate_action_models.dart';
import '../models/seat_map_models.dart';
import '../models/technical_report_models.dart';
import '../models/workstation_assignment_models.dart';
import 'seat_map_mock_service.dart';

class InvigilatorDemoStore extends GetxService {
  final seats = <SeatMapRecord>[].obs;
  final seatReassignments = <SeatReassignmentRecord>[].obs;
  final technicalReports = <TechnicalReportRecord>[].obs;

  /// Frontend demo state for the workstation allocation engine. In the
  /// production architecture these policies and locks belong on the hall
  /// server so every candidate workstation sees one authoritative state.
  final assignmentPolicies = <String, WorkstationAssignmentPolicy>{}.obs;
  final workstationAssignments = <CandidateWorkstationAssignment>[].obs;

  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    seats.assignAll(await SeatMapMockService.loadSeatMap());
    _seedAssignmentPolicies();
    _seedAssignmentsFromCurrentSeats();
    _seedTechnicalReports();
    _loaded = true;
  }

  String _policyKey(String hallName, String examTitle) =>
      '${hallName.trim().toLowerCase()}|${examTitle.trim().toLowerCase()}';

  WorkstationAssignmentPolicy policyFor({
    required String hallName,
    required String examTitle,
  }) {
    return assignmentPolicies[_policyKey(hallName, examTitle)] ??
        WorkstationAssignmentPolicy(
          hallName: hallName,
          examTitle: examTitle,
          mode: WorkstationAssignmentMode.freeSeating,
          distributionMode: WorkstationDistributionMode.fixed,
        );
  }

  void setAssignmentPolicy({
    required String hallName,
    required String examTitle,
    required WorkstationAssignmentMode mode,
    required WorkstationDistributionMode distributionMode,
  }) {
    assignmentPolicies[_policyKey(hallName, examTitle)] =
        WorkstationAssignmentPolicy(
          hallName: hallName,
          examTitle: examTitle,
          mode: mode,
          distributionMode: distributionMode,
        );
    assignmentPolicies.refresh();
  }

  List<CandidateWorkstationAssignment> assignmentsForHall(
    String hallName, {
    String? examTitle,
  }) {
    final items = workstationAssignments.where((assignment) {
      if (assignment.status == WorkstationAssignmentStatus.released) return false;
      if (assignment.hallName != hallName) return false;
      if (examTitle != null && assignment.examTitle != examTitle) return false;
      return true;
    }).toList();
    items.sort((a, b) => a.seatNumber.compareTo(b.seatNumber));
    return items;
  }

  CandidateWorkstationAssignment? assignmentForCandidate({
    required String registrationNumber,
    required String examTitle,
  }) {
    final reg = registrationNumber.trim().toUpperCase();
    for (final assignment in workstationAssignments.reversed) {
      if (assignment.status == WorkstationAssignmentStatus.released) continue;
      if (assignment.registrationNumber.trim().toUpperCase() == reg &&
          assignment.examTitle == examTitle) {
        return assignment;
      }
    }
    return null;
  }

  CandidateWorkstationAssignment? assignmentForWorkstation({
    required String workstationId,
    required String hallName,
    required String seatNumber,
    required String examTitle,
  }) {
    for (final assignment in workstationAssignments.reversed) {
      if (assignment.status == WorkstationAssignmentStatus.released) continue;
      if (assignment.examTitle != examTitle) continue;
      final sameDevice = assignment.workstationId == workstationId;
      final sameSeat = assignment.hallName == hallName &&
          assignment.seatNumber == seatNumber;
      if (sameDevice || sameSeat) return assignment;
    }
    return null;
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

  SeatMapRecord? findWorkstation(String workstationId) {
    for (final seat in seats) {
      if (seat.workstationId == workstationId) return seat;
    }
    return null;
  }

  Future<CandidateWorkstationAssignment> reserveWorkstation({
    required CandidateAssignmentRequest candidate,
    required String destinationSeatNumber,
    required WorkstationAssignmentSource source,
    String assignedBy = 'Invigilator',
  }) async {
    await ensureLoaded();

    final existing = assignmentForCandidate(
      registrationNumber: candidate.registrationNumber,
      examTitle: candidate.examTitle,
    );
    if (existing?.isLocked == true) {
      throw StateError(
        'Candidate is already locked to ${existing!.seatNumber}. Use Reassign Workstation instead.',
      );
    }

    final destination = findSeat(candidate.hallName, destinationSeatNumber);
    if (destination == null) {
      throw StateError('The selected workstation does not exist.');
    }
    if (destination.state != SeatOccupancyState.empty) {
      throw StateError('The selected workstation is not available.');
    }

    final occupant = assignmentForWorkstation(
      workstationId: destination.workstationId,
      hallName: destination.hallName,
      seatNumber: destination.seatNumber,
      examTitle: candidate.examTitle,
    );
    if (occupant != null &&
        occupant.registrationNumber != candidate.registrationNumber) {
      throw StateError('The selected workstation is already reserved.');
    }

    if (existing != null) {
      _releaseAssignment(existing, clearSeat: true);
    }

    final now = DateTime.now();
    final assignment = CandidateWorkstationAssignment(
      id: 'ASSIGN-${now.microsecondsSinceEpoch}',
      registrationNumber: candidate.registrationNumber,
      candidateName: candidate.candidateName,
      examTitle: candidate.examTitle,
      hallName: candidate.hallName,
      seatNumber: destination.seatNumber,
      workstationId: destination.workstationId,
      status: WorkstationAssignmentStatus.reserved,
      source: source,
      assignedAt: now,
      assignedBy: assignedBy,
    );

    workstationAssignments.add(assignment);
    _replaceSeat(
      destination.copyWith(
        candidateName: candidate.candidateName,
        registrationNumber: candidate.registrationNumber,
        examTitle: candidate.examTitle,
        state: SeatOccupancyState.expected,
      ),
    );
    workstationAssignments.refresh();
    return assignment;
  }

  Future<List<CandidateWorkstationAssignment>> distributeCandidates({
    required String hallName,
    required String examTitle,
    required List<CandidateAssignmentRequest> candidates,
    required WorkstationDistributionMode distributionMode,
  }) async {
    await ensureLoaded();

    final unlockedExisting = workstationAssignments
        .where(
          (assignment) =>
              assignment.hallName == hallName &&
              assignment.examTitle == examTitle &&
              assignment.status == WorkstationAssignmentStatus.reserved,
        )
        .toList();
    for (final assignment in unlockedExisting) {
      _releaseAssignment(assignment, clearSeat: true);
    }

    final pending = candidates.where((candidate) {
      final existing = assignmentForCandidate(
        registrationNumber: candidate.registrationNumber,
        examTitle: candidate.examTitle,
      );
      return existing == null;
    }).toList();

    final available = availableSeatsForHall(hallName);
    if (available.length < pending.length) {
      throw StateError(
        'Only ${available.length} healthy workstations are available for ${pending.length} unassigned candidates.',
      );
    }

    final orderedSeats = List<SeatMapRecord>.from(available);
    if (distributionMode == WorkstationDistributionMode.mixed) {
      orderedSeats.shuffle(Random(DateTime.now().microsecondsSinceEpoch));
    } else {
      orderedSeats.sort((a, b) => a.seatNumber.compareTo(b.seatNumber));
      pending.sort(
        (a, b) => a.registrationNumber.compareTo(b.registrationNumber),
      );
    }

    final created = <CandidateWorkstationAssignment>[];
    for (var index = 0; index < pending.length; index++) {
      created.add(
        await reserveWorkstation(
          candidate: pending[index],
          destinationSeatNumber: orderedSeats[index].seatNumber,
          source: distributionMode == WorkstationDistributionMode.fixed
              ? WorkstationAssignmentSource.systemFixed
              : WorkstationAssignmentSource.systemMixed,
          assignedBy: 'System',
        ),
      );
    }

    return created;
  }

  /// Enforces the security rule: after a successful exam login the candidate
  /// is locked to that workstation. A second workstation cannot claim the same
  /// candidate and an occupied workstation cannot claim another candidate.
  Future<WorkstationLoginDecision> claimWorkstationOnLogin({
    required String registrationNumber,
    required String candidateName,
    required String examTitle,
    required String hallName,
    required String seatNumber,
    required String workstationId,
  }) async {
    await ensureLoaded();

    if (hallName.trim().isEmpty ||
        seatNumber.trim().isEmpty ||
        workstationId.trim().isEmpty) {
      return const WorkstationLoginDecision(
        type: WorkstationLoginDecisionType.workstationNotConfigured,
        message:
            'This workstation has not been assigned to a hall and physical seat.',
      );
    }

    final physicalSeat = findSeat(hallName, seatNumber);
    if (physicalSeat == null) {
      return WorkstationLoginDecision(
        type: WorkstationLoginDecisionType.workstationNotConfigured,
        message: '$hallName / $seatNumber is not registered in the hall layout.',
      );
    }
    if (physicalSeat.state == SeatOccupancyState.issue) {
      return WorkstationLoginDecision(
        type: WorkstationLoginDecisionType.workstationUnavailable,
        message: '$seatNumber is isolated because of a technical issue.',
      );
    }

    final candidateAssignment = assignmentForCandidate(
      registrationNumber: registrationNumber,
      examTitle: examTitle,
    );

    if (candidateAssignment?.isLocked == true) {
      if (candidateAssignment!.workstationId == workstationId) {
        return WorkstationLoginDecision(
          type: WorkstationLoginDecisionType.allowed,
          message: 'Candidate session is already locked to this workstation.',
          assignment: candidateAssignment,
        );
      }
      return WorkstationLoginDecision(
        type: WorkstationLoginDecisionType.candidateLockedElsewhere,
        message:
            'Session already active at ${candidateAssignment.seatNumber}. Contact an invigilator to change workstation.',
        assignment: candidateAssignment,
      );
    }

    final workstationAssignment = assignmentForWorkstation(
      workstationId: workstationId,
      hallName: hallName,
      seatNumber: seatNumber,
      examTitle: examTitle,
    );
    if (workstationAssignment != null &&
        workstationAssignment.registrationNumber.trim().toUpperCase() !=
            registrationNumber.trim().toUpperCase()) {
      return WorkstationLoginDecision(
        type: WorkstationLoginDecisionType.workstationOccupied,
        message:
            '$seatNumber is reserved or locked for another candidate. Contact an invigilator.',
        assignment: workstationAssignment,
      );
    }

    if (candidateAssignment?.isReserved == true) {
      final matchesReservedSeat = candidateAssignment!.hallName == hallName &&
          candidateAssignment.seatNumber == seatNumber;
      if (!matchesReservedSeat) {
        return WorkstationLoginDecision(
          type: WorkstationLoginDecisionType.candidateAssignedElsewhere,
          message:
              'You are assigned to ${candidateAssignment.seatNumber}. Contact an invigilator if a change is required.',
          assignment: candidateAssignment,
        );
      }
      final locked = candidateAssignment.copyWith(
        workstationId: workstationId,
        status: WorkstationAssignmentStatus.locked,
        lockedAt: DateTime.now(),
      );
      _replaceAssignment(candidateAssignment, locked);
      _bindSeatToCandidate(
        physicalSeat,
        registrationNumber: registrationNumber,
        candidateName: candidateName,
        examTitle: examTitle,
        workstationId: workstationId,
        state: SeatOccupancyState.inExam,
      );
      return WorkstationLoginDecision(
        type: WorkstationLoginDecisionType.allowed,
        message: 'Reserved workstation confirmed and session locked.',
        assignment: locked,
      );
    }

    final policy = policyFor(hallName: hallName, examTitle: examTitle);
    if (policy.mode == WorkstationAssignmentMode.manual) {
      return const WorkstationLoginDecision(
        type: WorkstationLoginDecisionType.manualAssignmentRequired,
        message:
            'This exam uses Manual Assignment. Ask the invigilator to assign a workstation before login.',
      );
    }
    if (policy.mode == WorkstationAssignmentMode.systemDistribution) {
      return const WorkstationLoginDecision(
        type: WorkstationLoginDecisionType.systemDistributionRequired,
        message:
            'This exam uses System Distribution and no workstation has been assigned to this candidate yet.',
      );
    }

    final now = DateTime.now();
    final assignment = CandidateWorkstationAssignment(
      id: 'LOCK-${now.microsecondsSinceEpoch}',
      registrationNumber: registrationNumber,
      candidateName: candidateName,
      examTitle: examTitle,
      hallName: hallName,
      seatNumber: seatNumber,
      workstationId: workstationId,
      status: WorkstationAssignmentStatus.locked,
      source: WorkstationAssignmentSource.freeLogin,
      assignedAt: now,
      assignedBy: 'Candidate login',
      lockedAt: now,
    );
    workstationAssignments.add(assignment);
    workstationAssignments.refresh();
    _bindSeatToCandidate(
      physicalSeat,
      registrationNumber: registrationNumber,
      candidateName: candidateName,
      examTitle: examTitle,
      workstationId: workstationId,
      state: SeatOccupancyState.inExam,
    );

    return WorkstationLoginDecision(
      type: WorkstationLoginDecisionType.allowed,
      message: 'Free seating accepted. Session locked to $seatNumber.',
      assignment: assignment,
    );
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
    _recordInvigilatorReassignment(candidate, destination, event);

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

  void _bindSeatToCandidate(
    SeatMapRecord seat, {
    required String registrationNumber,
    required String candidateName,
    required String examTitle,
    required String workstationId,
    required SeatOccupancyState state,
  }) {
    _replaceSeat(
      seat.copyWith(
        candidateName: candidateName,
        registrationNumber: registrationNumber,
        examTitle: examTitle,
        workstationId: workstationId,
        state: state,
      ),
    );
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

  void _replaceAssignment(
    CandidateWorkstationAssignment current,
    CandidateWorkstationAssignment updated,
  ) {
    final index = workstationAssignments.indexWhere((a) => a.id == current.id);
    if (index < 0) return;
    workstationAssignments[index] = updated;
    workstationAssignments.refresh();
  }

  void _releaseAssignment(
    CandidateWorkstationAssignment assignment, {
    required bool clearSeat,
  }) {
    final released = assignment.copyWith(
      status: WorkstationAssignmentStatus.released,
    );
    _replaceAssignment(assignment, released);

    if (!clearSeat) return;
    final seat = findSeat(assignment.hallName, assignment.seatNumber);
    if (seat == null) return;
    if (seat.registrationNumber == assignment.registrationNumber &&
        seat.state == SeatOccupancyState.expected) {
      _replaceSeat(
        seat.copyWith(
          candidateName: '',
          registrationNumber: '',
          examTitle: '',
          state: SeatOccupancyState.empty,
        ),
      );
    }
  }

  void _recordInvigilatorReassignment(
    CandidateActionContext candidate,
    SeatMapRecord destination,
    SeatReassignmentRecord event,
  ) {
    final existing = assignmentForCandidate(
      registrationNumber: candidate.registrationNumber,
      examTitle: candidate.examTitle,
    );
    if (existing != null) {
      _releaseAssignment(existing, clearSeat: false);
    }

    workstationAssignments.add(
      CandidateWorkstationAssignment(
        id: 'LOCK-${event.id}',
        registrationNumber: candidate.registrationNumber,
        candidateName: candidate.candidateName,
        examTitle: candidate.examTitle,
        hallName: candidate.hallName,
        seatNumber: destination.seatNumber,
        workstationId: destination.workstationId,
        status: WorkstationAssignmentStatus.locked,
        source: WorkstationAssignmentSource.invigilatorReassignment,
        assignedAt: event.createdAt,
        assignedBy: 'Invigilator',
        lockedAt: event.createdAt,
      ),
    );
    workstationAssignments.refresh();
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

  void _seedAssignmentPolicies() {
    setAssignmentPolicy(
      hallName: 'Hall A',
      examTitle: 'CSC 305 - Data Structures',
      mode: WorkstationAssignmentMode.freeSeating,
      distributionMode: WorkstationDistributionMode.fixed,
    );
    setAssignmentPolicy(
      hallName: 'Hall B',
      examTitle: 'GST 201 - Use of English',
      mode: WorkstationAssignmentMode.freeSeating,
      distributionMode: WorkstationDistributionMode.fixed,
    );
  }

  void _seedAssignmentsFromCurrentSeats() {
    if (workstationAssignments.isNotEmpty) return;
    final now = DateTime.now().subtract(const Duration(minutes: 22));

    for (final seat in seats) {
      if (seat.registrationNumber.isEmpty || seat.candidateName.isEmpty) continue;
      final locked = seat.state == SeatOccupancyState.inExam ||
          seat.state == SeatOccupancyState.submitted ||
          seat.state == SeatOccupancyState.issue ||
          seat.state == SeatOccupancyState.malpractice;
      workstationAssignments.add(
        CandidateWorkstationAssignment(
          id: 'DEMO-${seat.hallName}-${seat.seatNumber}',
          registrationNumber: seat.registrationNumber,
          candidateName: seat.candidateName,
          examTitle: seat.examTitle,
          hallName: seat.hallName,
          seatNumber: seat.seatNumber,
          workstationId: seat.workstationId,
          status: locked
              ? WorkstationAssignmentStatus.locked
              : WorkstationAssignmentStatus.reserved,
          source: locked
              ? WorkstationAssignmentSource.freeLogin
              : WorkstationAssignmentSource.manual,
          assignedAt: now,
          assignedBy: locked ? 'Candidate login' : 'Invigilator',
          lockedAt: locked ? now.add(const Duration(minutes: 2)) : null,
        ),
      );
    }
    workstationAssignments.refresh();
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
