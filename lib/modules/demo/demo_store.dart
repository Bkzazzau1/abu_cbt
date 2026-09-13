import 'package:flutter/foundation.dart';

class DemoExam {
  DemoExam(
    this.code,
    this.title,
    this.hall,
    this.time,
    this.candidates, {
    this.status = 'Scheduled',
    this.duration = 60,
  });
  final String code, title, hall, time;
  final int candidates, duration;
  String status;
}

class DemoCandidate {
  DemoCandidate(
    this.name,
    this.number,
    this.department,
    this.seat, {
    this.checkedIn = false,
  });
  final String name, number, department, seat;
  bool checkedIn;
}

class DemoQuestion {
  DemoQuestion(this.course, this.prompt, this.options, this.answer);
  final String course, prompt;
  final List<String> options;
  final int answer;
  bool approved = false;
}

class DemoIncident {
  DemoIncident(this.title, this.location, this.severity);
  final String title, location, severity;
  bool resolved = false;
}

/// Shared, deliberately in-memory state for the presentation demo.
class DemoStore extends ChangeNotifier {
  static final instance = DemoStore();
  String role = 'Administrator';
  String semester = 'First semester';
  bool shuffle = true, showResults = false, notifications = true;
  final exams = <DemoExam>[
    DemoExam(
      'COS 301',
      'Data Structures & Algorithms',
      'Hall A',
      '09:00 AM',
      48,
      status: 'In progress',
      duration: 90,
    ),
    DemoExam('MTH 201', 'Mathematical Methods I', 'Hall B', '11:30 AM', 36),
    DemoExam('GST 101', 'Use of English', 'Hall A', '02:00 PM', 60),
    DemoExam(
      'BIO 201',
      'Cell Biology',
      'Hall C',
      'Tomorrow · 09:00 AM',
      42,
      status: 'Draft',
    ),
  ];
  final candidates = <DemoCandidate>[
    DemoCandidate(
      'Zainab Musa',
      'ABU/CSC/001',
      'Computer Science',
      'A01',
      checkedIn: true,
    ),
    DemoCandidate('Ibrahim Bashir Yahaya', 'ABU/MTH/004', 'Mathematics', 'B02'),
    DemoCandidate(
      'Maryam Bello',
      'ABU/GST/011',
      'General Studies',
      'A03',
      checkedIn: true,
    ),
    DemoCandidate(
      'Sadiq Lawal',
      'ABU/CSC/008',
      'Computer Science',
      'A04',
      checkedIn: true,
    ),
    DemoCandidate('Fatima Musa', 'ABU/BIO/002', 'Biological Sciences', 'C05'),
    DemoCandidate('Umar Aliyu', 'ABU/CHM/007', 'Chemistry', 'B06'),
    DemoCandidate(
      'Aisha Bello',
      'ABU/PHY/003',
      'Physics',
      'C07',
      checkedIn: true,
    ),
  ];
  final questions = <DemoQuestion>[
    DemoQuestion(
      'COS 301',
      'Which data structure follows the last-in, first-out principle?',
      ['Queue', 'Stack', 'Array', 'Tree'],
      1,
    )..approved = true,
    DemoQuestion(
      'COS 301',
      'What is the time complexity of binary search on a sorted array?',
      ['O(n)', 'O(n²)', 'O(log n)', 'O(1)'],
      2,
    )..approved = true,
    DemoQuestion('MTH 201', 'What is the derivative of x²?', [
      'x',
      '2x',
      'x³',
      '2',
    ], 1),
    DemoQuestion('GST 101', 'Choose the synonym of concise.', [
      'Lengthy',
      'Brief',
      'Complex',
      'Unclear',
    ], 1),
  ];
  final incidents = <DemoIncident>[
    DemoIncident('Workstation A12 disconnected', 'Hall A · Seat A12', 'High'),
    DemoIncident(
      'Candidate requested a replacement mouse',
      'Hall B · Seat B06',
      'Low',
    ),
  ];
  final activity = <String>[
    'Hall A session started · 09:00 AM',
    'Zainab Musa checked in · 08:52 AM',
    'COS 301 questions approved · 08:40 AM',
  ];
  void update(String message, VoidCallback action) {
    action();
    activity.insert(0, '$message · just now');
    notifyListeners();
  }
}
