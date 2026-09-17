import '../models/seat_map_models.dart';

class SeatMapMockService {
  static Future<List<SeatMapRecord>> loadSeatMap() async {
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

  static List<SeatMapRecord> _buildHall({
    required String hallName,
    required String seatPrefix,
    required String examTitle,
    required String registrationPrefix,
    required String workstationPrefix,
    required int offset,
  }) {
    return List.generate(48, (index) {
      final seatIndex = index + 1;
      final seatNumber = '$seatPrefix-${seatIndex.toString().padLeft(2, '0')}';
      final state = _stateForSeat(seatIndex);
      final hasCandidate = _stateHasActiveBinding(state);
      final nameIndex = (offset + index) % _candidateNames.length;

      return SeatMapRecord(
        hallName: hallName,
        seatNumber: seatNumber,
        candidateName: hasCandidate ? _candidateNames[nameIndex] : '',
        registrationNumber: hasCandidate
            ? '$registrationPrefix/${(offset + seatIndex).toString().padLeft(3, '0')}'
            : '',
        examTitle: hasCandidate ? examTitle : '',
        workstationId:
            '$workstationPrefix${seatIndex.toString().padLeft(2, '0')}-WS',
        state: state,
      );
    });
  }

  /// The hall map represents physical workstation occupancy, not a permanent
  /// student-to-seat timetable. Expected and absent candidates therefore do
  /// not consume a seat. A reservation is added dynamically by the
  /// workstation assignment engine when Manual/System allocation is used.
  static SeatOccupancyState _stateForSeat(int seat) {
    if (seat == 7 || seat == 34) return SeatOccupancyState.issue;
    if (seat == 19) return SeatOccupancyState.malpractice;
    if (seat == 4 ||
        seat == 11 ||
        seat == 15 ||
        seat == 22 ||
        seat == 31 ||
        seat == 39 ||
        seat == 42 ||
        seat == 46) {
      return SeatOccupancyState.empty;
    }
    if (seat == 2 || seat == 28) return SeatOccupancyState.seated;
    if (seat == 5 || seat == 26) return SeatOccupancyState.authorized;
    if (seat == 13 || seat == 24 || seat == 37 || seat == 45) {
      return SeatOccupancyState.submitted;
    }
    return SeatOccupancyState.inExam;
  }

  static bool _stateHasActiveBinding(SeatOccupancyState state) {
    return switch (state) {
      SeatOccupancyState.empty ||
      SeatOccupancyState.expected ||
      SeatOccupancyState.absent => false,
      _ => true,
    };
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
