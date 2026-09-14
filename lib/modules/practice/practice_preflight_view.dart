import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../data/models/center_exam_models.dart';
import '../demo/abu_demo_theme.dart';
import '../portal/controller/center_exam_portal_controller.dart';
import 'practice_ui.dart';

CenterExam? practiceExamArgument() {
  final arg = Get.arguments;
  if (arg is CenterExam) return arg;
  if (arg is Map && arg['exam'] is CenterExam) return arg['exam'] as CenterExam;
  return null;
}

class PracticePreflightView extends StatefulWidget {
  const PracticePreflightView({super.key, this.confirmation = false});
  final bool confirmation;
  @override
  State<PracticePreflightView> createState() => _PracticePreflightViewState();
}

class _PracticePreflightViewState extends State<PracticePreflightView> {
  bool confirmed = false;
  @override
  Widget build(BuildContext context) {
    final exam = practiceExamArgument();
    final candidate = Get.isRegistered<CenterExamPortalController>()
        ? Get.find<CenterExamPortalController>().candidate.value
        : null;
    if (exam == null) {
      return PracticeScaffold(
        onBack: returnToPractice,
        child: const PracticeTitle(
          'Choose a practice course',
          'Return to the practice centre to select a course.',
        ),
      );
    }
    return PracticeScaffold(
      section: '${exam.courseCode} · Before you begin',
      onBack: () => Get.back(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          practiceSteps(widget.confirmation ? 1 : 0),
          PracticeTitle(
            widget.confirmation
                ? 'Everything ready? Let’s begin.'
                : 'Take a moment before you start.',
            widget.confirmation
                ? 'Confirm your candidate details. Your timer starts only when you begin the examination.'
                : 'A few simple guidelines to help you get the most out of this practice session.',
          ),
          const SizedBox(height: 28),
          const Text(
            'During the exam, your camera checks for possible phones on this device. '
            'Detection flags are sent to the exam officer for review.',
            style: TextStyle(color: abuMuted, fontSize: 12, height: 1.6),
          ),
          const SizedBox(height: 16),
          practiceColumns(
            PracticeCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.confirmation) ...[
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: const Color(0xFFEAF1E8),
                          backgroundImage: candidate == null
                              ? null
                              : AssetImage(candidate.photoAsset),
                          child: candidate == null
                              ? const Icon(Icons.person_outline)
                              : null,
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                candidate?.fullName ?? 'Practice candidate',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                candidate?.registrationNumber ?? 'Demo session',
                                style: const TextStyle(
                                  color: abuMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    practiceDetail(
                      Icons.school_outlined,
                      'Department',
                      candidate?.department ?? 'Demo',
                    ),
                    practiceDetail(
                      Icons.layers_outlined,
                      'Level',
                      candidate?.level ?? 'Demo',
                    ),
                    practiceDetail(
                      Icons.auto_stories_outlined,
                      'Course',
                      exam.courseCode,
                    ),
                    practiceDetail(
                      Icons.timer_outlined,
                      'Time allowance',
                      '${exam.durationMinutes} minutes',
                    ),
                    const SizedBox(height: 24),
                    Material(
                      color: const Color(0xFFF2F6F2),
                      borderRadius: BorderRadius.circular(10),
                      child: CheckboxListTile(
                        controlAffinity: ListTileControlAffinity.leading,
                        value: confirmed,
                        onChanged: (v) => setState(() => confirmed = v!),
                        title: const Text(
                          'These are my details, and I am ready to begin.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text(
                          'I understand that this is a timed practice session.',
                          style: TextStyle(color: abuMuted, fontSize: 11),
                        ),
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'How your practice session works',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    for (final rule in [
                      (
                        Icons.touch_app_outlined,
                        'Choose the right response',
                        'Follow the instruction for each question. You may select an option, write a response, match items or use the drawing board.',
                      ),
                      (
                        Icons.grid_view_outlined,
                        'Move freely between questions',
                        'Use the numbered question panel or Previous and Next. Your responses are kept while this session remains open.',
                      ),
                      (
                        Icons.flag_outlined,
                        'Flag anything you want to revisit',
                        'Mark a question for review and return to it from the question panel. You can change answers before submitting.',
                      ),
                      (
                        Icons.timer_outlined,
                        'Keep an eye on the timer',
                        'The timer begins after confirmation. When time runs out, follow the prompt to submit your responses and view your summary.',
                      ),
                      (
                        Icons.fact_check_outlined,
                        'Review before submitting',
                        'The review screen shows answered, unanswered and flagged questions. Written and drawing answers may need manual review.',
                      ),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F5EF),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Icon(rule.$1, color: abuGreen, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rule.$2,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    rule.$3,
                                    style: const TextStyle(
                                      color: abuMuted,
                                      fontSize: 12,
                                      height: 1.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  const SizedBox(height: 14),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    runSpacing: 12,
                    spacing: 14,
                    children: [
                      OutlinedButton(
                        onPressed: () => Get.back(),
                        child: Text(
                          widget.confirmation
                              ? 'Back to instructions'
                              : 'Back to courses',
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: widget.confirmation && !confirmed
                            ? null
                            : () {
                                if (widget.confirmation) {
                                  Get.offNamed(
                                    Routes.centerExamRun,
                                    arguments: exam,
                                  );
                                } else {
                                  Get.toNamed(
                                    Routes.centerExamConfirmation,
                                    arguments: exam,
                                  );
                                }
                              },
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        label: Text(
                          widget.confirmation
                              ? 'Begin examination'
                              : 'Continue to confirmation',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PracticeCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PracticeTag(exam.courseCode),
                      const SizedBox(height: 18),
                      Text(
                        exam.courseTitle,
                        style: const TextStyle(
                          fontSize: 22,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      practiceDetail(
                        Icons.timer_outlined,
                        'Duration',
                        '${exam.durationMinutes} minutes',
                      ),
                      practiceDetail(
                        Icons.quiz_outlined,
                        'Questions',
                        '${exam.questions.length}',
                      ),
                      practiceDetail(
                        Icons.edit_note_outlined,
                        'Format',
                        'Mixed questions',
                      ),
                      const SizedBox(height: 12),
                      const PracticeTag('PRACTICE · NO ACADEMIC CREDIT'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const PracticeCard(
                  color: Color(0xFFEEF3ED),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline, color: abuGreen),
                      SizedBox(height: 14),
                      Text(
                        'Give yourself a clear start',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 9),
                      Text(
                        'Keep the app open during your session. Refreshing or closing it may lose your practice responses.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.8,
                          color: abuMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
