import 'package:abu_zaria_cbt/data/models/center_exam_models.dart';
import 'package:abu_zaria_cbt/data/services/center_exam_service.dart';
import 'package:abu_zaria_cbt/data/services/seat_question_order_service.dart';
import 'package:abu_zaria_cbt/modules/exam/controller/center_exam_run_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = CenterExamService.restoreCandidateSession(
    'ABU/CSC/001',
  )!.exams.first;
  List<String> ids(CenterExam exam) => exam.questions.map((q) => q.id).toList();

  test('order is repeatable, normalized, and leaves the bank intact', () {
    final original = ids(source);
    final first = SeatQuestionOrderService.forSeat(source, 'A-01');
    expect(ids(SeatQuestionOrderService.forSeat(source, ' a-1 ')), ids(first));
    expect(ids(SeatQuestionOrderService.forSeat(first, 'A-01')), ids(first));
    expect(ids(source), original);
    expect(ids(first).toSet(), original.toSet());
    for (final question in first.questions) {
      expect(
        identical(
          question,
          source.questions.firstWhere((q) => q.id == question.id),
        ),
        isTrue,
      );
    }
  });

  test(
    'consecutive seats differ at every position including rotation boundary',
    () {
      for (var seat = 1; seat < 30; seat++) {
        final left = ids(SeatQuestionOrderService.forSeat(source, 'A-$seat'));
        final right = ids(
          SeatQuestionOrderService.forSeat(source, 'A-${seat + 1}'),
        );
        for (var i = 0; i < left.length; i++) {
          expect(left[i], isNot(right[i]));
        }
      }
    },
  );

  test('unassigned practice retains source order', () {
    expect(SeatQuestionOrderService.forSeat(source, ' '), same(source));
  });

  test('grading and navigation keep answers attached to question IDs', () {
    final controller = CenterExamRunController();
    controller.exam.value = SeatQuestionOrderService.forSeat(source, 'A-02');
    final singleIndex = controller.exam.value!.questions.indexWhere(
      (q) => q.type == CenterQuestionType.objectiveSingle,
    );
    controller.jumpTo(singleIndex);
    final question = controller.currentQuestion;
    controller.pickSingle(question.correctIndexes.first);
    controller.jumpTo((singleIndex + 1) % controller.totalQuestions);
    controller.jumpTo(singleIndex);
    expect(controller.selectedSingleIndex, question.correctIndexes.first);
    expect(controller.answers[question.id]!.questionId, question.id);
    expect(controller.score, question.points);
    controller.onClose();
  });
}
