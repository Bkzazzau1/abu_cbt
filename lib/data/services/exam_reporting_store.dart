import 'package:get/get.dart';

import '../models/exam_control_audit_models.dart';
import '../models/incident_models.dart';
import '../models/malpractice_models.dart';

class ExamReportingStore extends GetxService {
  final incidentReports = <IncidentReportModel>[].obs;
  final malpracticeReports = <MalpracticeReportModel>[].obs;
  final examControlEvents = <ExamControlAuditRecord>[].obs;

  bool _seeded = false;

  @override
  void onInit() {
    super.onInit();
    ensureSeeded();
  }

  void ensureSeeded() {
    if (_seeded) return;
    _seeded = true;

    final now = DateTime.now();
    incidentReports.assignAll([
      IncidentReportModel(
        id: 'INC-DEMO-001',
        workstationId: 'ABU-CBT-A34-WS',
        hallName: 'Hall A',
        seatNumber: 'A-34',
        candidateName: 'Fadila Umar',
        registrationNumber: 'ABU/CSC/034',
        examTitle: 'CSC 305 - Data Structures',
        type: IncidentType.networkProblem,
        severity: IncidentSeverity.medium,
        description: 'Network latency rose above the hall operating threshold.',
        actionTaken:
            'Connection checked; workstation remained under observation.',
        evidenceNote: 'Latency monitor recorded repeated spikes.',
        reportedBy: 'Amina Yusuf',
        reportedAtIso:
            now.subtract(const Duration(minutes: 31)).toIso8601String(),
      ),
      IncidentReportModel(
        id: 'INC-DEMO-002',
        workstationId: 'ABU-CBT-B07-WS',
        hallName: 'Hall B',
        seatNumber: 'B-07',
        candidateName: 'Abubakar Sani',
        registrationNumber: 'ABU/GST/055',
        examTitle: 'GST 201 - Use of English',
        type: IncidentType.deviceIssue,
        severity: IncidentSeverity.low,
        description: 'Mouse intermittently stopped responding during the exam.',
        actionTaken:
            'Peripheral replaced and candidate continued without losing answers.',
        evidenceNote: 'Replacement logged by technical support.',
        reportedBy: 'Musa Ibrahim',
        reportedAtIso:
            now.subtract(const Duration(minutes: 19)).toIso8601String(),
      ),
    ]);

    malpracticeReports.assignAll([
      MalpracticeReportModel(
        id: 'MAL-DEMO-001',
        workstationId: 'ABU-CBT-A19-WS',
        centerName: 'ABU',
        hallName: 'Hall A',
        seatNumber: 'A-19',
        candidateName: 'Halima Sani',
        registrationNumber: 'ABU/CSC/019',
        examTitle: 'CSC 305 - Data Structures',
        type: MalpracticeType.phoneUse,
        severity: MalpracticeSeverity.major,
        description:
            'Invigilator observed a phone being handled beneath the desk.',
        actionTaken: 'Device secured and candidate placed under formal review.',
        evidenceNote:
            'Local detection event and invigilator observation recorded.',
        reportedBy: 'Chief Invigilator',
        reportedAtIso:
            now.subtract(const Duration(minutes: 24)).toIso8601String(),
      ),
    ]);

    examControlEvents.assignAll([
      ExamControlAuditRecord(
        id: 'CTRL-DEMO-001',
        registrationNumber: 'ABU/CSC/013',
        candidateName: 'Safiya Ahmad',
        examTitle: 'CSC 305 - Data Structures',
        hallName: 'Hall A',
        seatNumber: 'A-13',
        workstationId: 'ABU-CBT-A13-WS',
        type: ExamControlAuditType.forceSubmitted,
        createdAt: now.subtract(const Duration(minutes: 14)),
        actedBy: 'Chief Invigilator',
        note: 'Candidate submission confirmed after a workstation issue.',
      ),
      ExamControlAuditRecord(
        id: 'CTRL-DEMO-002',
        registrationNumber: 'ABU/CSC/017',
        candidateName: 'Rukayya Adamu',
        examTitle: 'CSC 305 - Data Structures',
        hallName: 'Hall A',
        seatNumber: 'A-17',
        workstationId: 'ABU-CBT-A17-WS',
        type: ExamControlAuditType.paused,
        createdAt: now.subtract(const Duration(minutes: 18)),
        actedBy: 'Amina Yusuf',
        note: 'Exam paused briefly while the candidate workstation was checked.',
      ),
      ExamControlAuditRecord(
        id: 'CTRL-DEMO-003',
        registrationNumber: 'ABU/CSC/017',
        candidateName: 'Rukayya Adamu',
        examTitle: 'CSC 305 - Data Structures',
        hallName: 'Hall A',
        seatNumber: 'A-17',
        workstationId: 'ABU-CBT-A17-WS',
        type: ExamControlAuditType.resumed,
        createdAt: now.subtract(const Duration(minutes: 16)),
        actedBy: 'Amina Yusuf',
        note: 'Candidate exam resumed after workstation verification.',
      ),
    ]);
  }

  void addIncident(IncidentReportModel report) {
    ensureSeeded();
    incidentReports.insert(0, report);
  }

  void addMalpractice(MalpracticeReportModel report) {
    ensureSeeded();
    malpracticeReports.insert(0, report);
  }

  void addExamControlEvent(ExamControlAuditRecord event) {
    ensureSeeded();
    examControlEvents.insert(0, event);
  }
}
