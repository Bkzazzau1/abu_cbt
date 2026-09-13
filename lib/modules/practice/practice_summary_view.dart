import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/center_exam_models.dart';
import '../demo/abu_demo_theme.dart';
import 'practice_ui.dart';

class PracticeSummaryView extends StatelessWidget {
  const PracticeSummaryView({super.key});
  @override
  Widget build(BuildContext context) {
    final data = Get.arguments is Map
        ? Get.arguments as Map
        : <String, dynamic>{};
    final exam = data['exam'] is CenterExam ? data['exam'] as CenterExam : null;
    final total = data['totalQuestions'] as int? ?? 0;
    final unanswered = data['unansweredCount'] as int? ?? 0;
    final score = data['score'] as int? ?? 0;
    final possible = data['totalPossibleAutoScore'] as int? ?? 0;
    final review = data['manualReviewCount'] as int? ?? 0;
    return PracticeScaffold(
      section: 'Practice summary',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          practiceSteps(3),
          practiceColumns(
            PracticeCard(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE9F2E8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 32,
                      color: abuGreen,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const PracticeTitle(
                    'Practice complete. Well done.',
                    'You’ve taken another step towards feeling confident on examination day.',
                  ),
                  const SizedBox(height: 30),
                  LayoutBuilder(
                    builder: (context, c) => Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        for (final metric in [
                          (
                            '${total - unanswered} / $total',
                            'Questions answered',
                          ),
                          ('$score / $possible', 'Auto-marked score'),
                          ('$review', 'Need manual review'),
                        ])
                          SizedBox(
                            width: c.maxWidth >= 600
                                ? (c.maxWidth - 32) / 3
                                : c.maxWidth,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F6F2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    metric.$1,
                                    style: const TextStyle(
                                      fontSize: 27,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    metric.$2,
                                    style: const TextStyle(
                                      color: abuMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    review > 0
                        ? 'Your auto-marked score covers supported objective questions only. Written responses and drawings are not included in that score.'
                        : 'This score is for practice only and does not contribute to your academic results.',
                    style: const TextStyle(
                      color: abuMuted,
                      fontSize: 13,
                      height: 1.8,
                    ),
                  ),
                  if (data['autoSubmitted'] == true) ...[
                    const SizedBox(height: 12),
                    const PracticeTag(
                      'Time elapsed · Automatically submitted',
                      amber: true,
                    ),
                  ],
                  const SizedBox(height: 30),
                  FilledButton.icon(
                    onPressed: returnToPractice,
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: const Text('Return to practice centre'),
                  ),
                ],
              ),
            ),
            PracticeCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Session summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 22),
                  PracticeTag(exam?.courseCode ?? 'PRACTICE'),
                  const SizedBox(height: 12),
                  Text(
                    exam?.courseTitle ?? 'Practice session',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  practiceDetail(Icons.quiz_outlined, 'Questions', '$total'),
                  practiceDetail(
                    Icons.radio_button_unchecked,
                    'Unanswered',
                    '$unanswered',
                  ),
                  practiceDetail(
                    Icons.timer_outlined,
                    'Time allowance',
                    '${exam?.durationMinutes ?? 0} minutes',
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Keep building your confidence',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Return to the practice centre to try another course or repeat this session. Each attempt is a fresh start.',
                    style: TextStyle(
                      color: abuMuted,
                      fontSize: 12,
                      height: 1.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
