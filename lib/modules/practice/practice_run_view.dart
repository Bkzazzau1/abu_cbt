import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/center_exam_models.dart';
import '../demo/abu_demo_theme.dart';
import '../exam/controller/center_exam_run_controller.dart';
import '../exam/models/whiteboard_models.dart';
import '../exam/widgets/multi_format_question_renderer.dart';
import '../exam/widgets/scientific_calculator_dialog.dart';
import '../exam/widgets/whiteboard_editor_dialog.dart';
import 'practice_ui.dart';

class PracticeRunView extends GetView<CenterExamRunController> {
  const PracticeRunView({super.key});
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: Obx(() {
      if (controller.isLoadingExam.value) {
        return const PracticeScaffold(
          child: Center(child: CircularProgressIndicator()),
        );
      }
      final exam = controller.exam.value;
      if (exam == null) {
        return PracticeScaffold(
          child: PracticeTitle(
            'No examination loaded',
            controller.examLoadError.value.isEmpty
                ? 'Open a course from the practice centre to begin.'
                : controller.examLoadError.value,
          ),
        );
      }
      // Read here so navigation is observed before deferred layout builders run.
      final q = controller.currentQuestion;
      final seconds = controller.secondsLeft.value;
      final time =
          '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
      return PracticeScaffold(
        section: '${exam.courseCode} · Practice examination',
        scroll: false,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: seconds < 300
                ? const Color(0xFFFFF0E8)
                : const Color(0xFFEEF4EF),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Column(
            children: [
              Obx(
                () => Text(
                  'Camera: ${controller.objectDetectionStatus.value}',
                  style: const TextStyle(fontSize: 10, color: abuMuted),
                ),
              ),
              const Text(
                'TIME REMAINING',
                style: TextStyle(
                  fontSize: 8,
                  letterSpacing: 1,
                  color: abuMuted,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                time,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: seconds < 300 ? Colors.deepOrange : abuGreen,
                ),
              ),
            ],
          ),
        ),
        child: Builder(
          builder: (context) => LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth >= 920;
              final workspace = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      Text(
                        exam.courseTitle,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => showDialog<void>(
                              context: context,
                              builder: (_) =>
                                  const ScientificCalculatorDialog(),
                            ),
                            tooltip: 'Open calculator',
                            icon: const Icon(
                              Icons.calculate_outlined,
                              size: 21,
                            ),
                          ),
                          if (!wide)
                            TextButton.icon(
                              onPressed: () => showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                showDragHandle: true,
                                builder: (sheetContext) => SizedBox(
                                  height:
                                      MediaQuery.sizeOf(context).height * .7,
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Obx(
                                      () => palette(
                                        context,
                                        onJump: () =>
                                            Navigator.pop(sheetContext),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              icon: const Icon(Icons.grid_view, size: 17),
                              label: const Text('Questions'),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: PracticeCard(
                      padding: EdgeInsets.all(wide ? 30 : 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 10,
                            runSpacing: 8,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  PracticeTag(
                                    'QUESTION ${controller.currentIndex.value + 1} OF ${controller.totalQuestions}',
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${q.points} ${q.points == 1 ? 'mark' : 'marks'}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: abuMuted,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton.icon(
                                onPressed: controller.toggleFlagCurrentQuestion,
                                icon: Icon(
                                  controller.isFlagged(
                                        controller.currentIndex.value,
                                      )
                                      ? Icons.flag
                                      : Icons.flag_outlined,
                                  size: 17,
                                ),
                                label: Text(
                                  controller.isFlagged(
                                        controller.currentIndex.value,
                                      )
                                      ? 'Flagged for review'
                                      : 'Flag for review',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 16),
                          Expanded(
                            child: SingleChildScrollView(
                              child: MultiFormatQuestionRenderer(
                                question: q,
                                answer: controller.currentAnswer,
                                onSingleSelect: controller.pickSingle,
                                onMultiToggle: controller.toggleMultiple,
                                onTextChanged: controller.updateTextAnswer,
                                onDragAssignmentsChanged:
                                    controller.updateDragAssignments,
                                onOpenWhiteboard: () => whiteboard(context, q),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed: controller.currentIndex.value == 0
                                    ? null
                                    : controller.previous,
                                icon: const Icon(Icons.arrow_back, size: 16),
                                label: const Text('Previous'),
                              ),
                              const Spacer(),
                              FilledButton.icon(
                                onPressed: controller.isLastQuestion
                                    ? () => review(context)
                                    : controller.next,
                                icon: Icon(
                                  controller.isLastQuestion
                                      ? Icons.fact_check_outlined
                                      : Icons.arrow_forward,
                                  size: 16,
                                ),
                                label: Text(
                                  controller.isLastQuestion ? 'Review' : 'Next',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      const Text(
                        'Responses retained in this session',
                        style: TextStyle(color: abuMuted, fontSize: 10),
                      ),
                      Text(
                        '${controller.totalQuestions - controller.unansweredCount} of ${controller.totalQuestions} answered',
                        style: const TextStyle(color: abuMuted, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              );
              if (!wide) return workspace;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: workspace),
                  const SizedBox(width: 26),
                  SizedBox(
                    width: 280,
                    child: PracticeCard(
                      padding: const EdgeInsets.all(22),
                      child: palette(context),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }),
  );

  Widget palette(BuildContext context, {VoidCallback? onJump}) {
    final answered = controller.totalQuestions - controller.unansweredCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Your progress',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
        ),
        const SizedBox(height: 10),
        Text(
          '$answered of ${controller.totalQuestions} questions answered',
          style: const TextStyle(color: abuMuted, fontSize: 11),
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: answered / controller.totalQuestions,
          minHeight: 5,
          borderRadius: BorderRadius.circular(4),
          backgroundColor: const Color(0xFFE9EEEA),
          color: abuGreen,
        ),
        const SizedBox(height: 26),
        const Text(
          'QUESTION NAVIGATOR',
          style: TextStyle(
            fontSize: 9,
            letterSpacing: 1.4,
            color: abuMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 10,
              children: List.generate(controller.totalQuestions, (i) {
                final selected = i == controller.currentIndex.value;
                final flagged = controller.isFlagged(i);
                final done = controller.isAnswered(i);
                return Semantics(
                  label:
                      'Question ${i + 1}, ${done ? 'answered' : 'unanswered'}${flagged ? ', flagged' : ''}',
                  selected: selected,
                  child: SizedBox(
                    width: 39,
                    height: 40,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: selected
                            ? abuGreen
                            : flagged
                            ? const Color(0xFFFFF0D9)
                            : done
                            ? const Color(0xFFE4F0E7)
                            : Colors.white,
                        foregroundColor: selected ? Colors.white : abuInk,
                        side: BorderSide(
                          color: selected
                              ? abuGreen
                              : flagged
                              ? const Color(0xFFDFB770)
                              : abuLine,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      onPressed: () {
                        controller.jumpTo(i);
                        onJump?.call();
                      },
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            PracticeTag('Answered'),
            PracticeTag('Flagged', amber: true),
            Text(
              'White · Unanswered',
              style: TextStyle(color: abuMuted, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {
            onJump?.call();
            review(context);
          },
          icon: const Icon(Icons.fact_check_outlined, size: 17),
          label: const Text('Review & submit'),
        ),
        const SizedBox(height: 14),
        const Text(
          'You can revisit any question before submitting.',
          style: TextStyle(color: abuMuted, fontSize: 11, height: 1.7),
        ),
      ],
    );
  }

  Future<void> review(BuildContext context) => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Review your responses'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Take a final look before you finish. Select a question below to return to it.',
                style: TextStyle(color: abuMuted, height: 1.7, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  PracticeTag(
                    '${controller.totalQuestions - controller.unansweredCount} answered',
                  ),
                  PracticeTag(
                    '${controller.unansweredCount} unanswered',
                    amber: true,
                  ),
                  PracticeTag(
                    '${controller.flaggedQuestionIds.length} flagged',
                    amber: true,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...List.generate(
                controller.totalQuestions,
                (i) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(
                    controller.isFlagged(i)
                        ? Icons.flag_outlined
                        : controller.isAnswered(i)
                        ? Icons.check_circle_outline
                        : Icons.circle_outlined,
                    color: controller.isFlagged(i) ? Colors.orange : abuGreen,
                    size: 19,
                  ),
                  title: Text('Question ${i + 1}'),
                  trailing: Text(
                    controller.isAnswered(i) ? 'Answered' : 'Unanswered',
                    style: const TextStyle(color: abuMuted, fontSize: 11),
                  ),
                  onTap: () {
                    Navigator.pop(dialogContext);
                    controller.jumpTo(i);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Keep working'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            controller.requestSubmit();
          },
          child: const Text('Continue to submit'),
        ),
      ],
    ),
  );

  Future<void> whiteboard(BuildContext context, CenterQuestion question) async {
    final result = await showDialog<List<WhiteboardStrokeData>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => WhiteboardEditorDialog(
        initialStrokes: controller.currentWhiteboardStrokes,
        prompt: question.whiteboardPrompt,
      ),
    );
    if (result != null && controller.currentQuestion.id == question.id) {
      controller.saveCurrentWhiteboardStrokes(result);
    }
  }
}
