import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/ks_page_shell.dart';
import '../../../data/models/center_exam_models.dart';
import '../../portal/controller/center_exam_portal_controller.dart';

class CenterExamInstructionView extends StatelessWidget {
  const CenterExamInstructionView({super.key});

  CenterExam? _extractExam() {
    final arg = Get.arguments;
    if (arg is CenterExam) return arg;
    if (arg is Map<String, dynamic> && arg['exam'] is CenterExam) {
      return arg['exam'] as CenterExam;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final exam = _extractExam();
    final cs = Theme.of(context).colorScheme;

    final candidate = Get.isRegistered<CenterExamPortalController>()
        ? Get.find<CenterExamPortalController>().candidate.value
        : null;

    if (exam == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Exam Instructions')),
        body: const Center(child: Text('No exam loaded.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Briefing'),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: KsPageShell(
        padding: const EdgeInsets.fromLTRB(16, 92, 16, 20),
        maxContentWidth: 980,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            /// HERO EXAM CARD
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Examination',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),

                  Text(
                    '${exam.courseCode} • ${exam.courseTitle}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _InfoChip(
                        label: 'Duration',
                        value: '${exam.durationMinutes} mins',
                      ),
                      _InfoChip(
                        label: 'Questions',
                        value: '${exam.questions.length}',
                      ),
                      _InfoChip(label: 'Date', value: exam.dateLabel),
                      _InfoChip(
                        label: 'Time',
                        value: '${exam.startTime} - ${exam.endTime}',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            /// CANDIDATE CARD
            if (candidate != null) ...[
              const SizedBox(height: 18),

              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Candidate Identity',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      candidate.fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text('Reg No: ${candidate.registrationNumber}'),

                    const SizedBox(height: 4),

                    Text('${candidate.department} • ${candidate.programme}'),
                  ],
                ),
              ),
            ],

            /// RULES
            const SizedBox(height: 18),

            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Examination Rules',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),

                  SizedBox(height: 12),

                  _RuleLine(
                    text:
                        'Questions may include objective, essay, fill-in-the-blank, drag-and-drop, or whiteboard formats.',
                  ),

                  _RuleLine(
                    text:
                        'Use the question navigator to move between questions.',
                  ),

                  _RuleLine(
                    text:
                        'Unanswered questions are allowed but will be scored zero.',
                  ),

                  _RuleLine(
                    text:
                        'Do not close, refresh, or switch away from the exam application.',
                  ),
                ],
              ),
            ),

            /// WARNING
            const SizedBox(height: 18),

            GlassCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 26, color: cs.error),
                  const SizedBox(width: 10),

                  const Expanded(
                    child: Text(
                      'Once you tap "Start Exam", the timer begins immediately and will continue until submission or timeout.',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),

            /// ACTIONS
            const SizedBox(height: 26),

            FilledButton.icon(
              icon: const Icon(Icons.play_arrow_rounded),
              onPressed: () {
                Get.toNamed(
                  Routes.centerExamConfirmation,
                  arguments: {'exam': exam},
                );
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              label: const Text(
                'Start Exam',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),

            const SizedBox(height: 10),

            OutlinedButton(onPressed: Get.back, child: const Text('Back')),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: cs.surfaceContainerHighest,
      ),
      child: Text(
        '$label • $value',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _RuleLine extends StatelessWidget {
  const _RuleLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
