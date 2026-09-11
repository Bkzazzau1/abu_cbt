enum ExamSessionState { notStarted, running, paused, closed }

class ExamSessionSummary {
  ExamSessionSummary({
    required this.sessionId,
    required this.examTitle,
    required this.courseCode,
    required this.hallName,
    required this.dateLabel,
    required this.startTime,
    required this.endTime,
    required this.state,
    required this.totalCandidates,
    required this.expectedCount,
    required this.checkedInCount,
    required this.authorizedCount,
    required this.inExamCount,
    required this.submittedCount,
    required this.offlineCount,
    required this.incidentCount,
    required this.malpracticeCount,
  });

  final String sessionId;
  final String examTitle;
  final String courseCode;
  final String hallName;
  final String dateLabel;
  final String startTime;
  final String endTime;
  final ExamSessionState state;
  final int totalCandidates;
  final int expectedCount;
  final int checkedInCount;
  final int authorizedCount;
  final int inExamCount;
  final int submittedCount;
  final int offlineCount;
  final int incidentCount;
  final int malpracticeCount;

  ExamSessionSummary copyWith({
    String? sessionId,
    String? examTitle,
    String? courseCode,
    String? hallName,
    String? dateLabel,
    String? startTime,
    String? endTime,
    ExamSessionState? state,
    int? totalCandidates,
    int? expectedCount,
    int? checkedInCount,
    int? authorizedCount,
    int? inExamCount,
    int? submittedCount,
    int? offlineCount,
    int? incidentCount,
    int? malpracticeCount,
  }) {
    return ExamSessionSummary(
      sessionId: sessionId ?? this.sessionId,
      examTitle: examTitle ?? this.examTitle,
      courseCode: courseCode ?? this.courseCode,
      hallName: hallName ?? this.hallName,
      dateLabel: dateLabel ?? this.dateLabel,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      state: state ?? this.state,
      totalCandidates: totalCandidates ?? this.totalCandidates,
      expectedCount: expectedCount ?? this.expectedCount,
      checkedInCount: checkedInCount ?? this.checkedInCount,
      authorizedCount: authorizedCount ?? this.authorizedCount,
      inExamCount: inExamCount ?? this.inExamCount,
      submittedCount: submittedCount ?? this.submittedCount,
      offlineCount: offlineCount ?? this.offlineCount,
      incidentCount: incidentCount ?? this.incidentCount,
      malpracticeCount: malpracticeCount ?? this.malpracticeCount,
    );
  }
}
