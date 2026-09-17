import 'package:get/get.dart';

import '../models/candidate_action_models.dart';
import '../models/seat_map_models.dart';
import 'seat_map_mock_service.dart';

class InvigilatorDemoStore extends GetxService {
  final seats = <SeatMapRecord>[].obs;
  final seatReassignments = <SeatReassignmentRecord>[].obs;

  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    seats.assignAll(await SeatMapMockService.loadSeatMap());
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
    return event;
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
}
