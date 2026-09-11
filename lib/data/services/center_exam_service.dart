import '../models/center_exam_models.dart';

class CenterExamService {
  static final Map<String, _CandidateSeed> _candidateSeeds = {
    'KASU/CSC/001': _CandidateSeed(
      password: 'cbt001',
      candidate: CenterCandidate(
        registrationNumber: 'KASU/CSC/001',
        fullName: 'Zainab Musa',
        level: '300 Level',
        photoAsset: 'assets/student_profiles/zainab_musa.png',
        department: 'Computer Science',
        programme: 'Part-Time',
      ),
    ),
    'KASU/MTH/004': _CandidateSeed(
      password: 'cbt004',
      candidate: CenterCandidate(
        registrationNumber: 'KASU/MTH/004',
        fullName: 'Ibrahim Bashir Yahaya',
        level: '200 Level',
        photoAsset: 'assets/student_profiles/ibrahim_yahaya.png',
        department: 'Mathematics',
        programme: 'Full-Time',
      ),
    ),
    'KASU/GST/011': _CandidateSeed(
      password: 'cbt011',
      candidate: CenterCandidate(
        registrationNumber: 'KASU/GST/011',
        fullName: 'Maryam Bello',
        level: '200 Level',
        photoAsset: 'assets/student_profiles/maryam_bello.png',
        department: 'General Studies',
        programme: 'Full-Time',
      ),
    ),
    'KASU/CSC/008': _CandidateSeed(
      password: 'cbt008',
      candidate: CenterCandidate(
        registrationNumber: 'KASU/CSC/008',
        fullName: 'Sadiq Lawal',
        level: '300 Level',
        photoAsset: 'assets/student_profiles/sadiq_lawal.png',
        department: 'Computer Science',
        programme: 'Full-Time',
      ),
    ),
    'KASU/BIO/002': _CandidateSeed(
      password: 'cbt002',
      candidate: CenterCandidate(
        registrationNumber: 'KASU/BIO/002',
        fullName: 'Fatima Musa',
        level: '200 Level',
        photoAsset: 'assets/student_profiles/fatima_musa.png',
        department: 'Biological Sciences',
        programme: 'Full-Time',
      ),
    ),
    'KASU/CHM/007': _CandidateSeed(
      password: 'cbt007',
      candidate: CenterCandidate(
        registrationNumber: 'KASU/CHM/007',
        fullName: 'Umar Aliyu',
        level: '200 Level',
        photoAsset: 'assets/student_profiles/umar_aliyu.png',
        department: 'Chemistry',
        programme: 'Full-Time',
      ),
    ),
    'KASU/PHY/003': _CandidateSeed(
      password: 'cbt003',
      candidate: CenterCandidate(
        registrationNumber: 'KASU/PHY/003',
        fullName: 'Aisha Bello',
        level: '200 Level',
        photoAsset: 'assets/student_profiles/aisha_bello.png',
        department: 'Physics',
        programme: 'Full-Time',
      ),
    ),
  };

  static Future<CenterLoginResult?> login({
    required String registrationNumber,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 650));

    final regNo = registrationNumber.trim().toUpperCase();
    final pass = password.trim();
    if (regNo.isEmpty || pass.isEmpty) {
      return null;
    }

    final seed = _candidateSeeds[regNo];
    if (seed == null || seed.password != pass) {
      return null;
    }

    return CenterLoginResult(
      candidate: seed.candidate,
      exams: _buildExamPlan(seed.candidate.registrationNumber),
    );
  }

  static CenterLoginResult? restoreCandidateSession(String registrationNumber) {
    final regNo = registrationNumber.trim().toUpperCase();
    if (regNo.isEmpty) {
      return null;
    }

    final seed = _candidateSeeds[regNo];
    if (seed == null) {
      return null;
    }

    return CenterLoginResult(
      candidate: seed.candidate,
      exams: _buildExamPlan(seed.candidate.registrationNumber),
    );
  }

  static List<CenterExam> _buildExamPlan(String regNo) {
    switch (regNo) {
      case 'KASU/CSC/001':
        return [
          _dueExam(
            id: 'csc001-due',
            code: 'CSC 305',
            title: 'Data Structures',
            venue: 'CBT Hall A',
            date: '06/03/2026',
            start: '10:00 AM',
            end: '11:00 AM',
            duration: 60,
            questions: _csc305Questions(),
          ),
          _upcomingExam(
            id: 'csc001-upcoming',
            code: 'CSC 312',
            title: 'Operating Systems',
            venue: 'CBT Hall A',
            date: '10/03/2026',
            start: '09:00 AM',
            end: '10:00 AM',
          ),
          _completedExam(
            id: 'csc001-completed',
            code: 'GST 201',
            title: 'Use of English',
            venue: 'CBT Hall B',
            date: '01/03/2026',
            start: '08:00 AM',
            end: '09:00 AM',
          ),
          _closedExam(
            id: 'csc001-closed',
            code: 'CSC 211',
            title: 'Digital Logic',
            venue: 'CBT Hall A',
            date: '25/02/2026',
            start: '12:00 PM',
            end: '01:00 PM',
          ),
        ];
      case 'KASU/MTH/004':
        return [
          _dueExam(
            id: 'mth004-due',
            code: 'MTH 202',
            title: 'Linear Algebra',
            venue: 'CBT Hall A',
            date: '06/03/2026',
            start: '10:00 AM',
            end: '11:00 AM',
            duration: 60,
            questions: _mth202Questions(),
          ),
          _upcomingExam(
            id: 'mth004-upcoming',
            code: 'STA 204',
            title: 'Probability Theory',
            venue: 'CBT Hall A',
            date: '11/03/2026',
            start: '11:00 AM',
            end: '12:00 PM',
          ),
          _completedExam(
            id: 'mth004-completed',
            code: 'GST 201',
            title: 'Use of English',
            venue: 'CBT Hall B',
            date: '01/03/2026',
            start: '08:00 AM',
            end: '09:00 AM',
          ),
        ];
      case 'KASU/GST/011':
        return [
          _dueExam(
            id: 'gst011-due',
            code: 'GST 201',
            title: 'Use of English',
            venue: 'CBT Hall B',
            date: '06/03/2026',
            start: '10:00 AM',
            end: '11:00 AM',
            duration: 60,
            questions: _gst201Questions(),
          ),
          _upcomingExam(
            id: 'gst011-upcoming',
            code: 'GST 203',
            title: 'Nigerian Peoples and Culture',
            venue: 'CBT Hall B',
            date: '12/03/2026',
            start: '09:00 AM',
            end: '10:00 AM',
          ),
          _completedExam(
            id: 'gst011-completed',
            code: 'EDS 101',
            title: 'Entrepreneurship Basics',
            venue: 'CBT Hall B',
            date: '27/02/2026',
            start: '01:00 PM',
            end: '02:00 PM',
          ),
        ];
      case 'KASU/CSC/008':
        return [
          _dueExam(
            id: 'csc008-due',
            code: 'CSC 305',
            title: 'Data Structures',
            venue: 'CBT Hall A',
            date: '06/03/2026',
            start: '10:00 AM',
            end: '11:00 AM',
            duration: 60,
            questions: _csc305Questions(),
          ),
          _upcomingExam(
            id: 'csc008-upcoming',
            code: 'CSC 307',
            title: 'Database Systems',
            venue: 'CBT Hall A',
            date: '10/03/2026',
            start: '12:00 PM',
            end: '01:00 PM',
          ),
          _completedExam(
            id: 'csc008-completed',
            code: 'MTH 201',
            title: 'Discrete Mathematics',
            venue: 'CBT Hall A',
            date: '02/03/2026',
            start: '09:00 AM',
            end: '10:00 AM',
          ),
        ];
      case 'KASU/BIO/002':
        return [
          _dueExam(
            id: 'bio002-due',
            code: 'BIO 201',
            title: 'Genetics',
            venue: 'CBT Hall B',
            date: '06/03/2026',
            start: '10:00 AM',
            end: '11:00 AM',
            duration: 60,
            questions: _bio201Questions(),
          ),
          _upcomingExam(
            id: 'bio002-upcoming',
            code: 'BIO 207',
            title: 'Cell Biology',
            venue: 'CBT Hall B',
            date: '13/03/2026',
            start: '11:00 AM',
            end: '12:00 PM',
          ),
          _completedExam(
            id: 'bio002-completed',
            code: 'CHM 201',
            title: 'General Biochemistry',
            venue: 'CBT Hall B',
            date: '28/02/2026',
            start: '10:00 AM',
            end: '11:00 AM',
          ),
        ];
      case 'KASU/CHM/007':
        return [
          _dueExam(
            id: 'chm007-due',
            code: 'CHM 204',
            title: 'Organic Chemistry',
            venue: 'CBT Hall B',
            date: '06/03/2026',
            start: '10:00 AM',
            end: '11:00 AM',
            duration: 60,
            questions: _chm204Questions(),
          ),
          _upcomingExam(
            id: 'chm007-upcoming',
            code: 'CHM 206',
            title: 'Physical Chemistry',
            venue: 'CBT Hall B',
            date: '14/03/2026',
            start: '09:00 AM',
            end: '10:00 AM',
          ),
          _completedExam(
            id: 'chm007-completed',
            code: 'BIO 201',
            title: 'Genetics',
            venue: 'CBT Hall B',
            date: '27/02/2026',
            start: '02:00 PM',
            end: '03:00 PM',
          ),
        ];
      case 'KASU/PHY/003':
        return [
          _dueExam(
            id: 'phy003-due',
            code: 'PHY 210',
            title: 'Mechanics',
            venue: 'CBT Hall A',
            date: '06/03/2026',
            start: '10:00 AM',
            end: '11:00 AM',
            duration: 60,
            questions: _phy210Questions(),
          ),
          _upcomingExam(
            id: 'phy003-upcoming',
            code: 'PHY 214',
            title: 'Electricity and Magnetism',
            venue: 'CBT Hall A',
            date: '15/03/2026',
            start: '01:00 PM',
            end: '02:00 PM',
          ),
          _completedExam(
            id: 'phy003-completed',
            code: 'MTH 202',
            title: 'Linear Algebra',
            venue: 'CBT Hall A',
            date: '01/03/2026',
            start: '11:00 AM',
            end: '12:00 PM',
          ),
        ];
      default:
        return <CenterExam>[];
    }
  }

  static CenterExam _dueExam({
    required String id,
    required String code,
    required String title,
    required String venue,
    required String date,
    required String start,
    required String end,
    required int duration,
    required List<CenterQuestion> questions,
  }) {
    return CenterExam(
      id: id,
      courseCode: code,
      courseTitle: title,
      venue: venue,
      dateLabel: date,
      startTime: start,
      endTime: end,
      status: CenterExamStatus.dueNow,
      durationMinutes: duration,
      questions: questions,
    );
  }

  static CenterExam _upcomingExam({
    required String id,
    required String code,
    required String title,
    required String venue,
    required String date,
    required String start,
    required String end,
  }) {
    return CenterExam(
      id: id,
      courseCode: code,
      courseTitle: title,
      venue: venue,
      dateLabel: date,
      startTime: start,
      endTime: end,
      status: CenterExamStatus.upcoming,
      durationMinutes: 60,
      questions: const [],
    );
  }

  static CenterExam _completedExam({
    required String id,
    required String code,
    required String title,
    required String venue,
    required String date,
    required String start,
    required String end,
  }) {
    return CenterExam(
      id: id,
      courseCode: code,
      courseTitle: title,
      venue: venue,
      dateLabel: date,
      startTime: start,
      endTime: end,
      status: CenterExamStatus.completed,
      durationMinutes: 60,
      questions: const [],
    );
  }

  static CenterExam _closedExam({
    required String id,
    required String code,
    required String title,
    required String venue,
    required String date,
    required String start,
    required String end,
  }) {
    return CenterExam(
      id: id,
      courseCode: code,
      courseTitle: title,
      venue: venue,
      dateLabel: date,
      startTime: start,
      endTime: end,
      status: CenterExamStatus.closed,
      durationMinutes: 60,
      questions: const [],
    );
  }

  static List<CenterQuestion> _csc305Questions() {
    return [
      _singleChoice(
        id: 'csc-q1',
        text: 'Which data structure uses LIFO ordering?',
        options: ['Queue', 'Stack', 'Tree', 'Graph'],
        correct: 1,
      ),
      _multiChoice(
        id: 'csc-q2',
        text: 'Select all linear data structures.',
        options: ['Stack', 'Queue', 'Graph', 'Trie'],
        correctIndexes: const [0, 1],
      ),
      _fillBlank(
        id: 'csc-q3',
        text:
            'Based on the complexity chart, average lookup for hash table is ____.',
        imagePath: 'assets/exam_images/hash_lookup_chart.png',
        imageCaption: 'Figure 1: Lookup complexity summary',
        answers: const ['o(1)', 'O(1)'],
      ),
      _dragDrop(
        id: 'csc-q4',
        text: 'Match each data structure with its typical operation.',
        dragItems: const ['Stack', 'Queue', 'Hash Table'],
        dropTargets: const ['Push/Pop', 'Enqueue/Dequeue', 'Key Lookup'],
      ),
      _whiteboard(
        id: 'csc-q5',
        text:
            'Study the tree below and redraw the traversal path on the whiteboard.',
        imagePath: 'assets/exam_images/tree_traversal_prompt.png',
        imageCaption: 'Figure 2: Binary Tree',
        prompt: 'Redraw the tree and annotate preorder traversal.',
        points: 5,
      ),
      _essay(
        id: 'csc-q6',
        text:
            'Explain one advantage and one limitation of linked lists compared to arrays.',
        points: 5,
      ),
    ];
  }

  static List<CenterQuestion> _mth202Questions() {
    return [
      _singleChoice(
        id: 'mth-q1',
        text: 'A matrix with equal rows and columns is called what?',
        options: ['Rectangular', 'Identity', 'Square', 'Diagonal'],
        correct: 2,
      ),
      _trueFalse(
        id: 'mth-q2',
        text: 'Determinant of a singular matrix is zero.',
        isTrue: true,
      ),
      _fillBlank(
        id: 'mth-q3',
        text: 'Determinant of [[a,b],[c,d]] is ____.',
        answers: const ['ad-bc', 'a d - b c'],
      ),
      _shortAnswer(
        id: 'mth-q4',
        text: 'State one condition for vectors to be linearly independent.',
        points: 2,
      ),
      _singleChoice(
        id: 'mth-q5',
        text: 'Rank of matrix equals?',
        options: [
          'Number of columns always',
          'Number of non-zero entries',
          'Maximum independent rows/columns',
          'Trace value',
        ],
        correct: 2,
      ),
    ];
  }

  static List<CenterQuestion> _gst201Questions() {
    return [
      _singleChoice(
        id: 'gst-q1',
        text: 'Choose the correctly punctuated sentence.',
        options: [
          'Its raining heavily.',
          'It\'s raining heavily.',
          'Its\' raining heavily.',
          'Its raining, heavily.',
        ],
        correct: 1,
      ),
      _singleChoice(
        id: 'gst-q2',
        text: 'Select the synonym of "concise".',
        options: ['Lengthy', 'Brief', 'Unclear', 'Complex'],
        correct: 1,
      ),
      _fillBlank(
        id: 'gst-q3',
        text: 'Write the correct article: "___ hour ago".',
        answers: const ['an'],
      ),
      _essay(
        id: 'gst-q4',
        text: 'Write a short paragraph on effective communication in exams.',
        points: 4,
      ),
    ];
  }

  static List<CenterQuestion> _bio201Questions() {
    return [
      _singleChoice(
        id: 'bio-q1',
        text: 'DNA stands for?',
        options: [
          'Deoxyribonucleic Acid',
          'Dinucleic Acid',
          'Dual Ribonucleic Acid',
          'Deoxy Ribose Network',
        ],
        correct: 0,
      ),
      _singleChoice(
        id: 'bio-q2',
        text: 'Unit of heredity is called?',
        options: ['Cell', 'Gene', 'Chromosome', 'Allele'],
        correct: 1,
      ),
      _singleChoice(
        id: 'bio-q3',
        text: 'Study the diagram and identify the highlighted phase.',
        imagePath: 'assets/exam_images/mitosis_phase.png',
        imageCaption: 'Figure 3: Cell division snapshot',
        options: ['Prophase', 'Metaphase', 'Anaphase', 'Telophase'],
        correct: 1,
      ),
      _shortAnswer(
        id: 'bio-q4',
        text: 'State one difference between genotype and phenotype.',
        points: 2,
      ),
    ];
  }

  static List<CenterQuestion> _chm204Questions() {
    return [
      _singleChoice(
        id: 'chm-q1',
        text: 'Carbon has valency of?',
        options: ['2', '3', '4', '6'],
        correct: 2,
      ),
      _singleChoice(
        id: 'chm-q2',
        text: 'Functional group in alcohol is?',
        options: ['-COOH', '-CHO', '-OH', '-NH2'],
        correct: 2,
      ),
      _trueFalse(
        id: 'chm-q3',
        text: 'All alkanes are unsaturated hydrocarbons.',
        isTrue: false,
      ),
      _dragDrop(
        id: 'chm-q4',
        text: 'Match compound class to the functional group.',
        dragItems: const ['Alcohol', 'Carboxylic Acid', 'Aldehyde'],
        dropTargets: const ['-OH', '-COOH', '-CHO'],
      ),
    ];
  }

  static List<CenterQuestion> _phy210Questions() {
    return [
      _singleChoice(
        id: 'phy-q1',
        text: 'SI unit of force is?',
        options: ['Joule', 'Newton', 'Pascal', 'Watt'],
        correct: 1,
      ),
      _singleChoice(
        id: 'phy-q2',
        text: 'Acceleration due to gravity on Earth is approximately?',
        options: ['9.8 m/s^2', '8.9 m/s^2', '10.8 m/s^2', '7.8 m/s^2'],
        correct: 0,
      ),
      _singleChoice(
        id: 'phy-q3',
        text: 'Study the graph and identify the motion represented.',
        imagePath: 'assets/exam_images/velocity_time_graph.png',
        imageCaption: 'Figure 4: Velocity-time graph',
        options: [
          'Uniform acceleration',
          'Constant velocity',
          'Uniform deceleration',
          'Oscillatory motion',
        ],
        correct: 0,
      ),
      _shortAnswer(
        id: 'phy-q4',
        text: 'Define momentum in one sentence.',
        points: 2,
      ),
    ];
  }

  static CenterQuestion _singleChoice({
    required String id,
    required String text,
    required List<String> options,
    required int correct,
    String? imagePath,
    String? imageCaption,
    int points = 1,
  }) {
    return CenterQuestion(
      id: id,
      type: CenterQuestionType.objectiveSingle,
      questionText: text,
      options: options,
      correctIndexes: [correct],
      imagePath: imagePath,
      imageCaption: imageCaption,
      points: points,
    );
  }

  static CenterQuestion _multiChoice({
    required String id,
    required String text,
    required List<String> options,
    required List<int> correctIndexes,
    int points = 1,
  }) {
    return CenterQuestion(
      id: id,
      type: CenterQuestionType.objectiveMultiple,
      questionText: text,
      options: options,
      correctIndexes: correctIndexes,
      points: points,
    );
  }

  static CenterQuestion _trueFalse({
    required String id,
    required String text,
    required bool isTrue,
    int points = 1,
  }) {
    return CenterQuestion(
      id: id,
      type: CenterQuestionType.trueFalse,
      questionText: text,
      options: const ['True', 'False'],
      correctIndexes: [isTrue ? 0 : 1],
      points: points,
    );
  }

  static CenterQuestion _fillBlank({
    required String id,
    required String text,
    required List<String> answers,
    String? imagePath,
    String? imageCaption,
    int points = 1,
  }) {
    return CenterQuestion(
      id: id,
      type: CenterQuestionType.fillBlank,
      questionText: text,
      correctTextAnswers: answers,
      imagePath: imagePath,
      imageCaption: imageCaption,
      points: points,
    );
  }

  static CenterQuestion _essay({
    required String id,
    required String text,
    int points = 5,
  }) {
    return CenterQuestion(
      id: id,
      type: CenterQuestionType.essay,
      questionText: text,
      points: points,
    );
  }

  static CenterQuestion _shortAnswer({
    required String id,
    required String text,
    int points = 2,
  }) {
    return CenterQuestion(
      id: id,
      type: CenterQuestionType.shortAnswer,
      questionText: text,
      points: points,
    );
  }

  static CenterQuestion _whiteboard({
    required String id,
    required String text,
    required String prompt,
    String? imagePath,
    String? imageCaption,
    int points = 5,
  }) {
    return CenterQuestion(
      id: id,
      type: CenterQuestionType.whiteboard,
      questionText: text,
      whiteboardPrompt: prompt,
      imagePath: imagePath,
      imageCaption: imageCaption,
      points: points,
    );
  }

  static CenterQuestion _dragDrop({
    required String id,
    required String text,
    required List<String> dragItems,
    required List<String> dropTargets,
    int points = 2,
  }) {
    return CenterQuestion(
      id: id,
      type: CenterQuestionType.dragDrop,
      questionText: text,
      dragItems: dragItems,
      dropTargets: dropTargets,
      points: points,
    );
  }
}

class _CandidateSeed {
  _CandidateSeed({required this.password, required this.candidate});

  final String password;
  final CenterCandidate candidate;
}
