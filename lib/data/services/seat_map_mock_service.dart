import '../models/seat_map_models.dart';

class SeatMapMockService {
  static Future<List<SeatMapRecord>> loadSeatMap() async {
    await Future.delayed(const Duration(milliseconds: 350));

    return <SeatMapRecord>[
      SeatMapRecord(
        hallName: 'Hall A',
        seatNumber: 'A-01',
        candidateName: 'Zainab Musa',
        registrationNumber: 'KASU/CSC/001',
        examTitle: 'CSC 305 - Data Structures',
        workstationId: 'KASU-CBT-A12F-93KD-7M21',
        state: SeatOccupancyState.inExam,
      ),
      SeatMapRecord(
        hallName: 'Hall A',
        seatNumber: 'A-02',
        candidateName: 'Ibrahim Bashir Yahaya',
        registrationNumber: 'KASU/MTH/004',
        examTitle: 'MTH 202 - Linear Algebra',
        workstationId: 'KASU-CBT-B74L-18QX-4N22',
        state: SeatOccupancyState.seated,
      ),
      SeatMapRecord(
        hallName: 'Hall A',
        seatNumber: 'A-03',
        candidateName: 'Maryam Bello',
        registrationNumber: 'KASU/GST/011',
        examTitle: 'GST 201 - Use of English',
        workstationId: 'KASU-CBT-C99P-55LM-2T77',
        state: SeatOccupancyState.submitted,
      ),
      SeatMapRecord(
        hallName: 'Hall A',
        seatNumber: 'A-04',
        candidateName: 'Sadiq Lawal',
        registrationNumber: 'KASU/CSC/008',
        examTitle: 'CSC 305 - Data Structures',
        workstationId: 'KASU-CBT-D43R-29HJ-8W10',
        state: SeatOccupancyState.issue,
      ),
      SeatMapRecord(
        hallName: 'Hall B',
        seatNumber: 'B-01',
        candidateName: 'Fatima Musa',
        registrationNumber: 'KASU/BIO/002',
        examTitle: 'BIO 201 - Genetics',
        workstationId: 'KASU-CBT-E18X-64BV-5K31',
        state: SeatOccupancyState.malpractice,
      ),
      SeatMapRecord(
        hallName: 'Hall B',
        seatNumber: 'B-02',
        candidateName: 'Umar Aliyu',
        registrationNumber: 'KASU/CHM/007',
        examTitle: 'CHM 204 - Organic Chemistry',
        workstationId: 'KASU-CBT-F22M-87ZT-9P44',
        state: SeatOccupancyState.absent,
      ),
      SeatMapRecord(
        hallName: 'Hall B',
        seatNumber: 'B-03',
        candidateName: '',
        registrationNumber: '',
        examTitle: '',
        workstationId: 'KASU-CBT-G88M-22QR-4N18',
        state: SeatOccupancyState.empty,
      ),
      SeatMapRecord(
        hallName: 'Hall B',
        seatNumber: 'B-04',
        candidateName: 'Aisha Bello',
        registrationNumber: 'KASU/PHY/003',
        examTitle: 'PHY 210 - Mechanics',
        workstationId: 'KASU-CBT-H10P-11TS-7Q20',
        state: SeatOccupancyState.expected,
      ),
    ];
  }
}
