import '../models/exam_session_models.dart';

class ExamSessionMockService {
  static Future<ExamSessionSummary> loadCurrentSession() async {
    await Future.delayed(const Duration(milliseconds: 400));

    return ExamSessionSummary(
      sessionId: 'session-csc305-hall-a-2026-03-06',
      examTitle: 'Data Structures Mid-Semester CBT',
      courseCode: 'CSC 305',
      hallName: 'Hall A',
      dateLabel: '06/03/2026',
      startTime: '10:00 AM',
      endTime: '11:00 AM',
      state: ExamSessionState.running,
      totalCandidates: 120,
      expectedCount: 120,
      checkedInCount: 108,
      authorizedCount: 102,
      inExamCount: 96,
      submittedCount: 24,
      offlineCount: 3,
      incidentCount: 4,
      malpracticeCount: 1,
    );
  }
}
