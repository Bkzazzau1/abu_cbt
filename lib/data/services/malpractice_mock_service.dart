import '../models/malpractice_models.dart';

/// Sample malpractice reports for demos/presentations, so the dashboard's
/// report feed has realistic content without needing to actually file one
/// first. Reuses the same workstation/candidate identities as
/// [InvigilatorMockService] and [EvidenceMockService] so the dashboard reads
/// as one consistent scenario. These ids are local to this mock (prefixed
/// `DEMO-`) and are never submitted to a real backend, so escalating one
/// during a demo without a live server connected is a harmless no-op, same
/// as the other mock-seeded actions on this dashboard.
class MalpracticeMockService {
  static Future<List<MalpracticeReportModel>> loadReports() async {
    await Future.delayed(const Duration(milliseconds: 400));
    final now = DateTime.now().toUtc();

    return <MalpracticeReportModel>[
      MalpracticeReportModel(
        id: 'DEMO-report-001',
        workstationId: 'ABU-CBT-B74L-18QX-4N22',
        centerName: 'ABU',
        hallName: 'Hall A',
        seatNumber: 'A-02',
        candidateName: 'Bashir Yahaya',
        registrationNumber: 'ABU/MTH/004',
        examTitle: 'MTH 202 - Linear Algebra',
        type: MalpracticeType.impersonation,
        severity: MalpracticeSeverity.critical,
        description:
            'Identity snapshot did not match the enrolled photo twice during '
            'the exam window. Invigilator confirmed in person that the '
            'candidate seated at A-02 did not match the enrolled photo.',
        actionTaken:
            'Candidate paused, identity re-verified with registration desk, '
            'chief invigilator notified.',
        reportedBy: 'invigilator.a',
        reportedAtIso: now
            .subtract(const Duration(minutes: 8))
            .toIso8601String(),
        escalated: true,
        escalatedBy: 'invigilator.a',
        escalatedAtIso: now
            .subtract(const Duration(minutes: 7))
            .toIso8601String(),
      ),
      MalpracticeReportModel(
        id: 'DEMO-report-002',
        workstationId: 'ABU-CBT-A12F-93KD-7M21',
        centerName: 'ABU',
        hallName: 'Hall A',
        seatNumber: 'A-01',
        candidateName: 'Zainab Musa',
        registrationNumber: 'ABU/CSC/001',
        examTitle: 'CSC 305 - Data Structures',
        type: MalpracticeType.phoneUse,
        severity: MalpracticeSeverity.major,
        description:
            'Local camera detection flagged a possible phone at this seat '
            '(91% model confidence). Invigilator observed the candidate '
            'reach under the desk shortly after.',
        actionTaken: 'Candidate warned; seat monitored for remainder of exam.',
        reportedBy: 'invigilator.a',
        reportedAtIso: now
            .subtract(const Duration(minutes: 2))
            .toIso8601String(),
      ),
      MalpracticeReportModel(
        id: 'DEMO-report-003',
        workstationId: 'ABU-CBT-E18X-64BV-5K31',
        centerName: 'ABU',
        hallName: 'Hall B',
        seatNumber: 'B-01',
        candidateName: 'Ibrahim Sule',
        registrationNumber: 'ABU/PHY/007',
        examTitle: 'PHY 101 - General Physics',
        type: MalpracticeType.unauthorizedMaterial,
        severity: MalpracticeSeverity.moderate,
        description:
            'Unauthorized USB storage device connected during the exam. '
            'Device seized for inspection.',
        actionTaken: 'Device confiscated and logged with the exam officer.',
        reportedBy: 'invigilator.b',
        reportedAtIso: now
            .subtract(const Duration(minutes: 20))
            .toIso8601String(),
      ),
    ];
  }
}
