import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../data/models/center_exam_models.dart';
import '../auth/demo_auth.dart';
import '../demo/abu_demo_theme.dart';
import '../demo/demo_store.dart';
import '../portal/controller/center_exam_portal_controller.dart';
import 'practice_ui.dart';

class PracticePortalView extends StatefulWidget {
  const PracticePortalView({super.key});
  @override
  State<PracticePortalView> createState() => _PracticePortalViewState();
}

class _PracticePortalViewState extends State<PracticePortalView> {
  String filter = 'All courses', query = '';
  late final CenterExamPortalController portal;
  @override
  void initState() {
    super.initState();
    portal = Get.find<CenterExamPortalController>();
    if (portal.candidate.value == null) {
      portal.loadCandidateSession(DemoAuth.instance.student!, persist: false);
    }
  }

  void begin(CenterExam source) {
    final questions = [...source.questions];
    if (DemoStore.instance.shuffle) questions.shuffle();
    final exam = CenterExam(
      id: source.id,
      courseCode: source.courseCode,
      courseTitle: source.courseTitle,
      venue: source.venue,
      dateLabel: source.dateLabel,
      startTime: source.startTime,
      endTime: source.endTime,
      status: CenterExamStatus.dueNow,
      durationMinutes: source.durationMinutes,
      questions: questions,
    );
    Get.toNamed(Routes.centerExamInstruction, arguments: exam);
  }

  @override
  Widget build(BuildContext context) => PracticeScaffold(
    onBack: () => Get.offAllNamed(Routes.demo),
    trailing: CircleAvatar(
      backgroundColor: Color(0xFFE6EEE8),
      child: Text(
        DemoAuth.instance.account!.initials,
        style: TextStyle(
          color: abuGreen,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    child: Obx(() {
      final candidate = portal.candidate.value;
      final exams = portal.exams.where((e) => e.questions.isNotEmpty).toList();
      final filtered = exams
          .where(
            (e) =>
                '${e.courseCode} ${e.courseTitle}'.toLowerCase().contains(
                  query,
                ) &&
                (filter == 'All courses' ||
                    (filter == 'Completed'
                        ? e.status == CenterExamStatus.completed
                        : e.status != CenterExamStatus.completed)),
          )
          .toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'LEARN. PRACTISE. BUILD CONFIDENCE.',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
              color: abuGreen,
            ),
          ),
          const SizedBox(height: 12),
          PracticeTitle(
            'Your next exam starts with preparation.',
            'Welcome back, ${candidate?.fullName.split(' ').first ?? 'student'}. Make yourself familiar with the examination experience.',
          ),
          const SizedBox(height: 28),
          practiceColumns(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: abuGreen,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.auto_stories_outlined,
                            color: Color(0xFFD4E4CB),
                            size: 21,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'YOUR PRACTICE SPACE',
                            style: TextStyle(
                              color: Color(0xFFD4E4CB),
                              fontSize: 10,
                              letterSpacing: 1.6,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'A little practice.\nA more confident you.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 31,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.7,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Explore question formats, get comfortable with the timer,\nand learn how to review your answers before submission.',
                        style: TextStyle(
                          color: Color(0xFFD8E5DC),
                          fontSize: 13,
                          height: 1.8,
                        ),
                      ),
                      const SizedBox(height: 26),
                      Wrap(
                        spacing: 14,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: abuGreen,
                            ),
                            onPressed: exams.isEmpty
                                ? null
                                : () => begin(exams.first),
                            icon: const Icon(Icons.arrow_forward, size: 18),
                            label: const Text('Start a practice session'),
                          ),
                          const Text(
                            'Practice only · No academic credit',
                            style: TextStyle(
                              color: Color(0xFFCDDFD1),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 18,
                  runSpacing: 14,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Available practice courses',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(
                      width: 240,
                      child: TextField(
                        onChanged: (v) =>
                            setState(() => query = v.toLowerCase()),
                        decoration: const InputDecoration(
                          hintText: 'Find a course',
                          prefixIcon: Icon(Icons.search, size: 19),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['All courses', 'Not completed', 'Completed']
                      .map(
                        (f) => ChoiceChip(
                          label: Text(f, style: const TextStyle(fontSize: 11)),
                          selected: filter == f,
                          showCheckmark: false,
                          onSelected: (_) => setState(() => filter = f),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 18),
                if (filtered.isEmpty)
                  const PracticeCard(
                    child: Column(
                      children: [
                        Icon(Icons.search_off, size: 34, color: abuMuted),
                        SizedBox(height: 12),
                        Text('No courses match this view.'),
                        SizedBox(height: 6),
                        Text(
                          'Try another search or choose All courses.',
                          style: TextStyle(color: abuMuted),
                        ),
                      ],
                    ),
                  ),
                ...filtered.map(
                  (exam) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: PracticeCard(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              PracticeTag(exam.courseCode),
                              if (exam.status == CenterExamStatus.completed)
                                const PracticeTag('Completed'),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            exam.courseTitle,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 24,
                            runSpacing: 16,
                            children: [
                              Text(
                                '${exam.questions.length} questions  ·  ${exam.durationMinutes} minutes  ·  Mixed formats',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: abuMuted,
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => begin(exam),
                                icon: const Icon(Icons.arrow_forward, size: 16),
                                label: Text(
                                  exam.status == CenterExamStatus.completed
                                      ? 'Practise again'
                                      : 'View instructions',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PracticeCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFFEAF1E8),
                            backgroundImage: candidate == null
                                ? null
                                : AssetImage(candidate.photoAsset),
                            child: candidate == null
                                ? const Icon(Icons.person_outline)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  candidate?.fullName ?? 'Student',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  candidate?.registrationNumber ??
                                      'Not available',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: abuMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      const Divider(),
                      practiceDetail(
                        Icons.school_outlined,
                        'Department',
                        candidate?.department ?? 'Computer Science',
                      ),
                      practiceDetail(
                        Icons.layers_outlined,
                        'Level',
                        candidate?.level ?? '300 Level',
                      ),
                      practiceDetail(
                        Icons.task_alt,
                        'Completed',
                        '${exams.where((e) => e.status == CenterExamStatus.completed).length} / ${exams.length} courses',
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => Get.toNamed(Routes.deviceRegistration),
                        icon: const Icon(Icons.dns_outlined, size: 16),
                        label: const Text('Register / manage workstation'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const PracticeCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Before you begin',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 20),
                      _Tip(
                        '01',
                        'Settle into your space',
                        'Find a quiet place and allow enough time for your session.',
                      ),
                      _Tip(
                        '02',
                        'Read every question',
                        'Some questions accept more than one answer or a written response.',
                      ),
                      _Tip(
                        '03',
                        'Review at your pace',
                        'Flag questions and return to them before your time runs out.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'Practice responses stay within this demo. Keep the application open until you finish.',
                    style: TextStyle(
                      fontSize: 11,
                      color: abuMuted,
                      height: 1.7,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }),
  );
}

class _Tip extends StatelessWidget {
  const _Tip(this.number, this.title, this.text);
  final String number, title, text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: const TextStyle(
            color: abuGreen,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.7,
                  color: abuMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
