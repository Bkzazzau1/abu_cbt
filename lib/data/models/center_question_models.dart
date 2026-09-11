enum CenterQuestionType {
  objectiveSingle,
  objectiveMultiple,
  fillBlank,
  essay,
  dragDrop,
  whiteboard,
  trueFalse,
  shortAnswer,
}

class CenterQuestion {
  CenterQuestion({
    required this.id,
    required this.type,
    required this.questionText,
    this.options = const [],
    this.correctIndexes = const [],
    this.correctTextAnswers = const [],
    this.dragItems = const [],
    this.dropTargets = const [],
    this.whiteboardPrompt,
    this.imagePath,
    this.imageCaption,
    this.points = 1,
  });

  final String id;
  final CenterQuestionType type;
  final String questionText;

  final List<String> options;
  final List<int> correctIndexes;

  final List<String> correctTextAnswers;

  final List<String> dragItems;
  final List<String> dropTargets;

  final String? whiteboardPrompt;

  final String? imagePath;
  final String? imageCaption;

  final int points;
}

class CenterCandidateAnswer {
  CenterCandidateAnswer({
    required this.questionId,
    this.selectedIndexes = const [],
    this.textAnswer,
    this.dragAssignments = const {},
    this.whiteboardStrokeCount = 0,
  });

  final String questionId;
  final List<int> selectedIndexes;
  final String? textAnswer;
  final Map<String, String> dragAssignments;
  final int whiteboardStrokeCount;

  CenterCandidateAnswer copyWith({
    String? questionId,
    List<int>? selectedIndexes,
    String? textAnswer,
    Map<String, String>? dragAssignments,
    int? whiteboardStrokeCount,
  }) {
    return CenterCandidateAnswer(
      questionId: questionId ?? this.questionId,
      selectedIndexes: selectedIndexes ?? this.selectedIndexes,
      textAnswer: textAnswer ?? this.textAnswer,
      dragAssignments: dragAssignments ?? this.dragAssignments,
      whiteboardStrokeCount:
          whiteboardStrokeCount ?? this.whiteboardStrokeCount,
    );
  }
}
