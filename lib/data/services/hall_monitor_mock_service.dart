import '../models/hall_monitor_models.dart';

class HallMonitorMockService {
  static Future<List<HallMonitorRecord>> loadHallRecords() async {
    await Future.delayed(const Duration(milliseconds: 400));

    return <HallMonitorRecord>[
      HallMonitorRecord(
        workstationId: 'KASU-CBT-A12F-93KD-7M21',
        hallName: 'Hall A',
        seatNumber: 'A-01',
        candidateName: 'Zainab Musa',
        registrationNumber: 'KASU/CSC/001',
        examTitle: 'CSC 305 - Data Structures',
        state: HallCandidateLiveState.inExam,
        lastSeenLabel: 'Just now',
        hasIncident: false,
        hasMalpractice: false,
      ),
      HallMonitorRecord(
        workstationId: 'KASU-CBT-B74L-18QX-4N22',
        hallName: 'Hall A',
        seatNumber: 'A-02',
        candidateName: 'Ibrahim Bashir Yahaya',
        registrationNumber: 'KASU/MTH/004',
        examTitle: 'MTH 202 - Linear Algebra',
        state: HallCandidateLiveState.checkedIn,
        lastSeenLabel: '1 min ago',
        hasIncident: false,
        hasMalpractice: false,
      ),
      HallMonitorRecord(
        workstationId: 'KASU-CBT-C99P-55LM-2T77',
        hallName: 'Hall A',
        seatNumber: 'A-03',
        candidateName: 'Maryam Bello',
        registrationNumber: 'KASU/GST/011',
        examTitle: 'GST 201 - Use of English',
        state: HallCandidateLiveState.submitted,
        lastSeenLabel: '2 min ago',
        hasIncident: false,
        hasMalpractice: false,
      ),
      HallMonitorRecord(
        workstationId: 'KASU-CBT-D43R-29HJ-8W10',
        hallName: 'Hall A',
        seatNumber: 'A-04',
        candidateName: 'Sadiq Lawal',
        registrationNumber: 'KASU/CSC/008',
        examTitle: 'CSC 305 - Data Structures',
        state: HallCandidateLiveState.issueFlagged,
        lastSeenLabel: 'Just now',
        hasIncident: true,
        hasMalpractice: false,
      ),
      HallMonitorRecord(
        workstationId: 'KASU-CBT-E18X-64BV-5K31',
        hallName: 'Hall B',
        seatNumber: 'B-01',
        candidateName: 'Fatima Musa',
        registrationNumber: 'KASU/BIO/002',
        examTitle: 'BIO 201 - Genetics',
        state: HallCandidateLiveState.malpracticeFlagged,
        lastSeenLabel: 'Just now',
        hasIncident: false,
        hasMalpractice: true,
      ),
      HallMonitorRecord(
        workstationId: 'KASU-CBT-F22M-87ZT-9P44',
        hallName: 'Hall B',
        seatNumber: 'B-02',
        candidateName: 'Umar Aliyu',
        registrationNumber: 'KASU/CHM/007',
        examTitle: 'CHM 204 - Organic Chemistry',
        state: HallCandidateLiveState.offline,
        lastSeenLabel: '4 min ago',
        hasIncident: false,
        hasMalpractice: false,
      ),
    ];
  }
}
