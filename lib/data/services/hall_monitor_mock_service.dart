import '../models/hall_monitor_models.dart';

class HallMonitorMockService {
  static Future<List<HallMonitorRecord>> loadHallRecords() async {
    await Future.delayed(const Duration(milliseconds: 350));

    return [
      ..._buildHall(
        hallName: 'Hall A',
        seatPrefix: 'A',
        examTitle: 'CSC 305 - Data Structures',
        registrationPrefix: 'ABU/CSC',
        workstationPrefix: 'ABU-CBT-A',
        offset: 0,
      ),
      ..._buildHall(
        hallName: 'Hall B',
        seatPrefix: 'B',
        examTitle: 'GST 201 - Use of English',
        registrationPrefix: 'ABU/GST',
        workstationPrefix: 'ABU-CBT-B',
        offset: 48,
      ),
    ];
  }

  static List<HallMonitorRecord> _buildHall({
    required String hallName,
    required String seatPrefix,
    required String examTitle,
    required String registrationPrefix,
    required String workstationPrefix,
    required int offset,
  }) {
    return List.generate(48, (index) {
      final seatIndex = index + 1;
      final state = _stateForSeat(seatIndex);
      final seatNumber = '$seatPrefix-${seatIndex.toString().padLeft(2, '0')}';
      final hasCandidate = state != HallCandidateLiveState.ready;
      final nameIndex = (offset + index) % _candidateNames.length;

      return HallMonitorRecord(
        workstationId:
            '$workstationPrefix${seatIndex.toString().padLeft(2, '0')}-WS',
        hallName: hallName,
        seatNumber: seatNumber,
        candidateName: hasCandidate ? _candidateNames[nameIndex] : '',
        registrationNumber: hasCandidate
            ? '$registrationPrefix/${(offset + seatIndex).toString().padLeft(3, '0')}'
            : '',
        examTitle: hasCandidate ? examTitle : '',
        state: state,
        lastSeenLabel: _lastSeenForSeat(seatIndex, state),
        hasIncident: state == HallCandidateLiveState.issueFlagged,
        hasMalpractice: state == HallCandidateLiveState.malpracticeFlagged,
      );
    });
  }

  static HallCandidateLiveState _stateForSeat(int seat) {
    if (seat == 7 || seat == 34) return HallCandidateLiveState.issueFlagged;
    if (seat == 19) return HallCandidateLiveState.malpracticeFlagged;
    if (seat == 9) return HallCandidateLiveState.offline;
    if (seat == 11 || seat == 42) return HallCandidateLiveState.absent;
    if (seat == 15 || seat == 31 || seat == 46) {
      return HallCandidateLiveState.ready;
    }
    if (seat == 4 || seat == 22 || seat == 39) {
      return HallCandidateLiveState.checkedIn;
    }
    if (seat == 2 || seat == 28) return HallCandidateLiveState.authorized;
    if (seat == 13 || seat == 24 || seat == 37 || seat == 45) {
      return HallCandidateLiveState.submitted;
    }
    return HallCandidateLiveState.inExam;
  }

  static String _lastSeenForSeat(int seat, HallCandidateLiveState state) {
    if (state == HallCandidateLiveState.offline) return '4 min ago';
    if (state == HallCandidateLiveState.absent ||
        state == HallCandidateLiveState.ready) {
      return '-';
    }
    if (seat % 7 == 0) return '1 min ago';
    if (seat % 11 == 0) return '35 sec ago';
    return 'Just now';
  }

  static const _candidateNames = <String>[
    'Zainab Musa',
    'Ibrahim Bashir Yahaya',
    'Maryam Bello',
    'Sadiq Lawal',
    'Fatima Musa',
    'Umar Aliyu',
    'Aisha Bello',
    'Abubakar Sani',
    'Khadija Abdullahi',
    'Muhammad Kabir',
    'Hauwa Ibrahim',
    'Usman Garba',
    'Safiya Ahmad',
    'Yusuf Suleiman',
    'Nafisa Ismail',
    'Aminu Mohammed',
    'Rukayya Adamu',
    'Bashir Haruna',
    'Halima Sani',
    'Musa Abdullahi',
    'Jamila Ibrahim',
    'Abdullahi Umar',
    "Asma'u Bello",
    'Mustapha Garba',
    'Rahma Yusuf',
    'Nasir Ahmad',
    'Zahra Mohammed',
    'Aliyu Sani',
    'Habiba Musa',
    'Ibrahim Suleiman',
    'Amina Abdullahi',
    'Salisu Haruna',
    'Nura Kabir',
    'Fadila Umar',
    'Murtala Ahmad',
    'Sadiya Garba',
    'Khalid Ibrahim',
    'Bilal Musa',
    'Hafsat Bello',
    'Ismail Yusuf',
    'Farida Sani',
    'Mahmud Abdullahi',
    'Aisha Kabir',
    'Anas Mohammed',
    'Maryam Sani',
    'Hamza Bello',
    'Zulaihat Umar',
    'Abdulrahman Musa',
  ];
}
