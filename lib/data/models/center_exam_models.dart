import 'center_question_models.dart';

export 'center_question_models.dart';

enum CenterExamStatus { dueNow, upcoming, completed, closed }

class CenterCandidate {
  CenterCandidate({
    required this.registrationNumber,
    required this.fullName,
    required this.level,
    required this.photoAsset,
    required this.department,
    required this.programme,
  });

  final String registrationNumber;
  final String fullName;
  final String level;
  final String photoAsset;
  final String department;
  final String programme;
}

class CenterExam {
  CenterExam({
    required this.id,
    required this.courseCode,
    required this.courseTitle,
    required this.venue,
    required this.dateLabel,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.durationMinutes,
    required this.questions,
  });

  final String id;
  final String courseCode;
  final String courseTitle;
  final String venue;
  final String dateLabel;
  final String startTime;
  final String endTime;
  final CenterExamStatus status;
  final int durationMinutes;
  final List<CenterQuestion> questions;
}

class CenterLoginResult {
  CenterLoginResult({required this.candidate, required this.exams});

  final CenterCandidate candidate;
  final List<CenterExam> exams;
}
