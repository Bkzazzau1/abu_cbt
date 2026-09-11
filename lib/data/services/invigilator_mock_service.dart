import '../models/invigilator_models.dart';
import '../models/workstation_models.dart';

class InvigilatorMockService {
  static Future<List<InvigilatorWorkstationRecord>> loadWorkstations() async {
    await Future.delayed(const Duration(milliseconds: 400));

    return <InvigilatorWorkstationRecord>[
      InvigilatorWorkstationRecord(
        workstationId: 'KASU-CBT-A12F-93KD-7M21',
        centerName: 'KASU',
        hallName: 'Hall A',
        seatNumber: 'A-01',
        status: WorkstationStatus.whitelisted,
        usageState: WorkstationUsageState.inExam,
        appInstalled: true,
        candidateName: 'Zainab Musa',
        registrationNumber: 'KASU/CSC/001',
        examTitle: 'CSC 305 - Data Structures',
        lastSeenLabel: 'Just now',
      ),
      InvigilatorWorkstationRecord(
        workstationId: 'KASU-CBT-B74L-18QX-4N22',
        centerName: 'KASU',
        hallName: 'Hall A',
        seatNumber: 'A-02',
        status: WorkstationStatus.whitelisted,
        usageState: WorkstationUsageState.candidateLoggedIn,
        appInstalled: true,
        candidateName: 'Bashir Yahaya',
        registrationNumber: 'KASU/MTH/004',
        examTitle: 'MTH 202 - Linear Algebra',
        lastSeenLabel: '1 min ago',
      ),
      InvigilatorWorkstationRecord(
        workstationId: 'KASU-CBT-C99P-55LM-2T77',
        centerName: 'KASU',
        hallName: 'Hall A',
        seatNumber: 'A-03',
        status: WorkstationStatus.pending,
        usageState: WorkstationUsageState.inactive,
        appInstalled: true,
        candidateName: '',
        registrationNumber: '',
        examTitle: '',
        lastSeenLabel: '5 min ago',
      ),
      InvigilatorWorkstationRecord(
        workstationId: 'KASU-CBT-D43R-29HJ-8W10',
        centerName: 'KASU',
        hallName: 'Hall A',
        seatNumber: 'A-04',
        status: WorkstationStatus.whitelisted,
        usageState: WorkstationUsageState.submitted,
        appInstalled: true,
        candidateName: 'Maryam Bello',
        registrationNumber: 'KASU/GST/011',
        examTitle: 'GST 201 - Use of English',
        lastSeenLabel: '2 min ago',
      ),
      InvigilatorWorkstationRecord(
        workstationId: 'KASU-CBT-E18X-64BV-5K31',
        centerName: 'KASU',
        hallName: 'Hall B',
        seatNumber: 'B-01',
        status: WorkstationStatus.disabled,
        usageState: WorkstationUsageState.inactive,
        appInstalled: true,
        candidateName: '',
        registrationNumber: '',
        examTitle: '',
        lastSeenLabel: '10 min ago',
      ),
      InvigilatorWorkstationRecord(
        workstationId: 'KASU-CBT-F22M-87ZT-9P44',
        centerName: 'KASU',
        hallName: 'Hall B',
        seatNumber: 'B-02',
        status: WorkstationStatus.revoked,
        usageState: WorkstationUsageState.inactive,
        appInstalled: false,
        candidateName: '',
        registrationNumber: '',
        examTitle: '',
        lastSeenLabel: '30 min ago',
      ),
    ];
  }
}
