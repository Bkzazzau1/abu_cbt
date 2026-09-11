import '../models/attendance_models.dart';

class AttendanceMockService {
  static Future<List<AttendanceRecord>> loadAttendance() async {
    await Future.delayed(const Duration(milliseconds: 350));

    return <AttendanceRecord>[
      AttendanceRecord(
        candidateName: 'Zainab Musa',
        registrationNumber: 'KASU/CSC/001',
        hallName: 'Hall A',
        seatNumber: 'A-01',
        examTitle: 'CSC 305 - Data Structures',
        state: AttendanceState.inExam,
        workstationId: 'KASU-CBT-A12F-93KD-7M21',
      ),
      AttendanceRecord(
        candidateName: 'Ibrahim Bashir Yahaya',
        registrationNumber: 'KASU/MTH/004',
        hallName: 'Hall A',
        seatNumber: 'A-02',
        examTitle: 'MTH 202 - Linear Algebra',
        state: AttendanceState.seated,
        workstationId: 'KASU-CBT-B74L-18QX-4N22',
      ),
      AttendanceRecord(
        candidateName: 'Maryam Bello',
        registrationNumber: 'KASU/GST/011',
        hallName: 'Hall A',
        seatNumber: 'A-03',
        examTitle: 'GST 201 - Use of English',
        state: AttendanceState.submitted,
        workstationId: 'KASU-CBT-C99P-55LM-2T77',
      ),
      AttendanceRecord(
        candidateName: 'Sadiq Lawal',
        registrationNumber: 'KASU/CSC/008',
        hallName: 'Hall A',
        seatNumber: 'A-04',
        examTitle: 'CSC 305 - Data Structures',
        state: AttendanceState.present,
        workstationId: 'KASU-CBT-D43R-29HJ-8W10',
      ),
      AttendanceRecord(
        candidateName: 'Fatima Musa',
        registrationNumber: 'KASU/BIO/002',
        hallName: 'Hall B',
        seatNumber: 'B-01',
        examTitle: 'BIO 201 - Genetics',
        state: AttendanceState.authorized,
        workstationId: 'KASU-CBT-E18X-64BV-5K31',
      ),
      AttendanceRecord(
        candidateName: 'Umar Aliyu',
        registrationNumber: 'KASU/CHM/007',
        hallName: 'Hall B',
        seatNumber: 'B-02',
        examTitle: 'CHM 204 - Organic Chemistry',
        state: AttendanceState.absent,
        workstationId: 'KASU-CBT-F22M-87ZT-9P44',
      ),
      AttendanceRecord(
        candidateName: 'Aisha Bello',
        registrationNumber: 'KASU/PHY/003',
        hallName: 'Hall B',
        seatNumber: 'B-03',
        examTitle: 'PHY 210 - Mechanics',
        state: AttendanceState.expected,
        workstationId: 'KASU-CBT-G88M-22QR-4N18',
      ),
    ];
  }
}
