import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/ks_status_chip.dart';
import '../../../data/models/center_exam_models.dart';
import '../../../data/models/workstation_models.dart';
import '../../../data/services/network_health_service.dart';
import '../../demo/abu_demo_theme.dart';
import '../controller/center_exam_run_controller.dart';
import '../models/whiteboard_models.dart';
import '../widgets/multi_format_question_renderer.dart';
import '../widgets/scientific_calculator_dialog.dart';
import '../widgets/whiteboard_editor_dialog.dart';

class CenterExamRunView extends GetView<CenterExamRunController> {
  const CenterExamRunView({super.key});

  @override
  Widget build(BuildContext context) {
    final network = Get.isRegistered<NetworkHealthService>()
        ? Get.find<NetworkHealthService>()
        : null;

    return Theme(
      data: abuDemoTheme(),
      child: Builder(
        builder: (context) {
          final cs = Theme.of(context).colorScheme;
          return Scaffold(
            backgroundColor: abuCanvas,
            bottomNavigationBar: Obx(
              () => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    'Camera monitoring: ${controller.objectDetectionStatus.value}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: abuMuted),
                  ),
                ),
              ),
            ),
            body: Obx(() {
              if (controller.isLoadingExam.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final exam = controller.exam.value;
              if (exam == null) {
                return Center(
                  child: Text(
                    controller.examLoadError.value.isEmpty
                        ? 'No exam loaded.'
                        : controller.examLoadError.value,
                  ),
                );
              }

              final q = controller.currentQuestion;
              final mm = (controller.secondsLeft.value ~/ 60)
                  .toString()
                  .padLeft(2, '0');
              final ss = (controller.secondsLeft.value % 60).toString().padLeft(
                2,
                '0',
              );
              final networkStatus =
                  network?.status.value ?? NetworkHealthStatus.online;

              return SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1600),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final desktop = constraints.maxWidth >= 1080;

                          if (!desktop) {
                            return Column(
                              children: [
                                _buildUltraCompactHeader(
                                  context,
                                  cs,
                                  exam,
                                  mm,
                                  ss,
                                  networkStatus,
                                ),
                                const SizedBox(height: 10),
                                _buildMobileNavigator(cs),
                                const SizedBox(height: 10),
                                Expanded(
                                  child: _buildQuestionWorkspace(
                                    context,
                                    q,
                                    cs,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildActionBar(cs, compact: true),
                              ],
                            );
                          }

                          return Column(
                            children: [
                              _buildUltraCompactHeader(
                                context,
                                cs,
                                exam,
                                mm,
                                ss,
                                networkStatus,
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 240,
                                      child: _buildSlimNavigator(cs),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Expanded(
                                            child: _buildQuestionWorkspace(
                                              context,
                                              q,
                                              cs,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          _buildActionBar(cs, compact: false),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildUltraCompactHeader(
    BuildContext context,
    ColorScheme cs,
    CenterExam exam,
    String mm,
    String ss,
    NetworkHealthStatus networkStatus,
  ) {
    return _Card(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          const KsStatusChip(label: 'SECURE', tone: KsStatusChipTone.accent),
          const SizedBox(width: 8),
          _networkBadge(networkStatus),
          const SizedBox(width: 20),
          IconButton.filledTonal(
            onPressed: () => _openScientificCalculator(context),
            tooltip: 'Scientific Calculator',
            icon: const Icon(Icons.calculate_outlined),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${exam.courseCode}: ${exam.courseTitle}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            width: 110,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cs.primary.withValues(alpha: 0.30)),
            ),
            child: Text(
              '$mm:$ss',
              style: TextStyle(
                color: cs.primary,
                fontWeight: FontWeight.w900,
                fontSize: 22,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlimNavigator(ColorScheme cs) {
    return _Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NAVIGATOR (${controller.currentIndex.value + 1}/${controller.totalQuestions})',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.zero,
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: controller.totalQuestions,
              itemBuilder: (_, i) {
                final isCurrent = i == controller.currentIndex.value;
                final answered = controller.isAnswered(i);
                final flagged = controller.isFlagged(i);

                return InkWell(
                  onTap: () => controller.jumpTo(i),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? cs.primary
                          : (flagged
                                ? Colors.orange.withValues(alpha: 0.20)
                                : (answered
                                      ? cs.primary.withValues(alpha: 0.10)
                                      : cs.surfaceContainerHighest)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCurrent
                            ? cs.primary
                            : (flagged
                                  ? Colors.orange
                                  : cs.outlineVariant.withValues(alpha: 0.20)),
                        width: isCurrent ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isCurrent
                            ? cs.onPrimary
                            : (flagged ? Colors.orange : cs.onSurface),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileNavigator(ColorScheme cs) {
    return _Card(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(controller.totalQuestions, (i) {
          final isCurrent = i == controller.currentIndex.value;
          final answered = controller.isAnswered(i);
          final bg = isCurrent
              ? cs.primary
              : (answered
                    ? cs.primary.withValues(alpha: 0.1)
                    : cs.surfaceContainerHighest);
          final fg = isCurrent ? cs.onPrimary : cs.onSurface;
          return InkWell(
            onTap: () => controller.jumpTo(i),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCurrent
                      ? cs.primary
                      : cs.outlineVariant.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                '${i + 1}',
                style: TextStyle(color: fg, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildQuestionWorkspace(
    BuildContext context,
    CenterQuestion q,
    ColorScheme cs,
  ) {
    return _Card(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuestionHeader(cs),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value:
                (controller.currentIndex.value + 1) / controller.totalQuestions,
            minHeight: 4,
            borderRadius: BorderRadius.circular(10),
            backgroundColor: cs.primary.withValues(alpha: 0.10),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: DefaultTextStyle(
                style: TextStyle(fontSize: 18, color: cs.onSurface),
                child: _buildQuestionInput(context, q),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionHeader(ColorScheme cs) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'QUESTION ${controller.currentIndex.value + 1}',
          style: TextStyle(
            color: cs.primary,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 12),
        KsStatusChip(label: 'UNANSWERED: ${controller.unansweredCount}'),
        const Spacer(),
        IconButton.filledTonal(
          onPressed: controller.toggleFlagCurrentQuestion,
          icon: Icon(
            controller.isFlagged(controller.currentIndex.value)
                ? Icons.flag
                : Icons.flag_outlined,
          ),
          color: controller.isFlagged(controller.currentIndex.value)
              ? Colors.orange
              : null,
        ),
      ],
    );
  }

  Widget _buildActionBar(ColorScheme cs, {required bool compact}) {
    if (compact) {
      return _Card(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: controller.currentIndex.value == 0
                    ? null
                    : controller.previous,
                icon: const Icon(Icons.keyboard_arrow_left_rounded),
                label: const Text('PREVIOUS'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: controller.isLastQuestion
                    ? controller.requestSubmit
                    : controller.next,
                icon: Icon(
                  controller.isLastQuestion
                      ? Icons.check_circle_rounded
                      : Icons.keyboard_arrow_right_rounded,
                ),
                label: Text(
                  controller.isLastQuestion ? 'SUBMIT EXAM' : 'SAVE & NEXT',
                ),
              ),
            ),
          ],
        ),
      );
    }

    return _Card(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: controller.currentIndex.value == 0
                ? null
                : controller.previous,
            icon: const Icon(Icons.keyboard_arrow_left_rounded),
            label: const Text('PREVIOUS'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: controller.isLastQuestion
                ? controller.requestSubmit
                : controller.next,
            icon: Icon(
              controller.isLastQuestion
                  ? Icons.check_circle_rounded
                  : Icons.keyboard_arrow_right_rounded,
            ),
            label: Text(
              controller.isLastQuestion ? 'SUBMIT EXAM' : 'SAVE & NEXT',
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionInput(BuildContext context, CenterQuestion q) {
    return MultiFormatQuestionRenderer(
      question: q,
      answer: controller.currentAnswer,
      onSingleSelect: controller.pickSingle,
      onMultiToggle: controller.toggleMultiple,
      onTextChanged: controller.updateTextAnswer,
      onDragAssignmentsChanged: controller.updateDragAssignments,
      onOpenWhiteboard: () => _openWhiteboardEditor(context, q),
    );
  }

  Future<void> _openWhiteboardEditor(
    BuildContext context,
    CenterQuestion question,
  ) async {
    if (question.type != CenterQuestionType.whiteboard) return;
    final result = await showDialog<List<WhiteboardStrokeData>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => WhiteboardEditorDialog(
        initialStrokes: controller.currentWhiteboardStrokes,
        prompt: question.whiteboardPrompt,
      ),
    );

    if (result == null) return;
    if (controller.currentQuestion.id != question.id) return;
    controller.saveCurrentWhiteboardStrokes(result);
  }

  Future<void> _openScientificCalculator(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => const ScientificCalculatorDialog(),
    );
  }

  Widget _networkBadge(NetworkHealthStatus status) {
    return KsStatusChip(
      label: status.name.toUpperCase(),
      tone: switch (status) {
        NetworkHealthStatus.online => KsStatusChipTone.success,
        NetworkHealthStatus.lowNetwork => KsStatusChipTone.warning,
        NetworkHealthStatus.offline => KsStatusChipTone.danger,
      },
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, required this.padding});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: abuLine),
    ),
    child: Padding(padding: padding, child: child),
  );
}
