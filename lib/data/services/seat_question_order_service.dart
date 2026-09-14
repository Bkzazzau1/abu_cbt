import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/center_exam_models.dart';

/// Version 1: stable hash ordering followed by a numbered-seat rotation.
/// Consecutive seat numbers differ at every position for banks of size > 1.
/// Orders repeat after the bank size; this is not a secrecy mechanism.
class SeatQuestionOrderService {
  static CenterExam forSeat(CenterExam exam, String seatNumber) {
    final seat = seatNumber.trim().toUpperCase();
    if (seat.isEmpty || exam.questions.length < 2) return exam;

    final suffix = RegExp(r'^(.*?)(\d+)$').firstMatch(seat);
    final group = suffix?.group(1) ?? seat;
    final number = suffix == null
        ? BigInt.zero
        : BigInt.parse(suffix.group(2)!);
    // Course/session metadata is shared even when demo exam IDs are per student.
    final seed = jsonEncode([
      'seat-order-v1',
      exam.courseCode,
      exam.dateLabel,
      exam.startTime,
      group,
    ]);
    final keys = <String, String>{
      for (final q in exam.questions)
        q.id: sha256.convert(utf8.encode(jsonEncode([seed, q.id]))).toString(),
    };
    final ordered = List<CenterQuestion>.of(exam.questions)
      ..sort((a, b) {
        final comparison = keys[a.id]!.compareTo(keys[b.id]!);
        return comparison == 0 ? a.id.compareTo(b.id) : comparison;
      });
    final offset = (number % BigInt.from(ordered.length)).toInt();
    return CenterExam(
      id: exam.id,
      courseCode: exam.courseCode,
      courseTitle: exam.courseTitle,
      venue: exam.venue,
      dateLabel: exam.dateLabel,
      startTime: exam.startTime,
      endTime: exam.endTime,
      status: exam.status,
      durationMinutes: exam.durationMinutes,
      questions: List.unmodifiable([
        ...ordered.skip(offset),
        ...ordered.take(offset),
      ]),
    );
  }
}
