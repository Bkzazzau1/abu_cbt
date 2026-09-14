import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../data/models/center_exam_models.dart';
import '../../auth/demo_auth.dart';
import '../../demo/abu_demo_theme.dart';
import '../../portal/controller/center_exam_portal_controller.dart';

class CurrentExamPortalView extends StatefulWidget {
  const CurrentExamPortalView({super.key});

  @override
  State<CurrentExamPortalView> createState() => _CurrentExamPortalViewState();
}

class _CurrentExamPortalViewState extends State<CurrentExamPortalView> {
  late final CenterExamPortalController portal;

  @override
  void initState() {
    super.initState();
    portal = Get.find<CenterExamPortalController>();
    if (portal.candidate.value == null && DemoAuth.instance.student != null) {
      portal.loadCandidateSession(DemoAuth.instance.student!, persist: false);
    }
  }

  CenterExam? _currentExam(List<CenterExam> exams) {
    for (final exam in exams) {
      if (exam.questions.isNotEmpty && exam.status == CenterExamStatus.dueNow) {
        return exam;
      }
    }
    return null;
  }

  void _startExam(CenterExam source) {
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
      questions: [...source.questions],
    );
    Get.toNamed(Routes.centerExamConfirmation, arguments: exam);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: abuDemoTheme(),
      child: Scaffold(
        backgroundColor: abuCanvas,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/senate.png', fit: BoxFit.cover),
            Container(color: abuCanvas.withValues(alpha: 0.90)),
            SafeArea(
              child: Column(
                children: [
                  _Header(onSignOut: DemoAuth.instance.signOut),
                  Expanded(
                    child: Obx(() {
                      final candidate = portal.candidate.value;
                      final exam = _currentExam(portal.exams.toList());
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 42),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1080),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'STUDENT EXAMINATION DASHBOARD',
                                  style: TextStyle(
                                    color: abuGreen,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Welcome, ${candidate?.fullName.split(' ').first ?? 'Candidate'}',
                                  style: const TextStyle(
                                    color: abuInk,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.8,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final wide = constraints.maxWidth >= 800;
                                    final examCard = exam == null
                                        ? const _NoExamCard()
                                        : _ExamCard(
                                            exam: exam,
                                            onStart: () => _startExam(exam),
                                          );
                                    final recordCard = _CandidateRecordCard(
                                      name: candidate?.fullName ?? 'Candidate',
                                      registrationNumber:
                                          candidate?.registrationNumber ?? '--',
                                      department: candidate?.department ?? '--',
                                      level: candidate?.level ?? '--',
                                      programme: candidate?.programme ?? '--',
                                      photoAsset: candidate?.photoAsset,
                                      onDeviceRegistration: () =>
                                          Get.toNamed(Routes.deviceRegistration),
                                    );

                                    if (!wide) {
                                      return Column(
                                        children: [
                                          examCard,
                                          const SizedBox(height: 18),
                                          recordCard,
                                        ],
                                      );
                                    }

                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(flex: 3, child: examCard),
                                        const SizedBox(width: 22),
                                        Expanded(flex: 2, child: recordCard),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onSignOut});

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: abuLine)),
      ),
      child: Row(
        children: [
          Image.asset('assets/abulogo.png', width: 42, height: 48),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ahmadu Bello University, Zaria',
                  style: TextStyle(
                    color: abuInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'SECURE CBT EXAMINATION PORTAL',
                  style: TextStyle(
                    color: abuMuted,
                    fontSize: 9,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  const _ExamCard({required this.exam, required this.onStart});

  final CenterExam exam;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: abuLine),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F2EB),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Text(
              'CURRENT EXAMINATION',
              style: TextStyle(
                color: abuGreen,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            exam.courseCode,
            style: const TextStyle(
              color: abuGreen,
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            exam.courseTitle,
            style: const TextStyle(
              color: abuInk,
              fontWeight: FontWeight.w800,
              fontSize: 28,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: abuLine),
          _Info(Icons.timer_outlined, 'Duration', '${exam.durationMinutes} minutes'),
          _Info(Icons.quiz_outlined, 'Questions', '${exam.questions.length}'),
          _Info(Icons.location_on_outlined, 'Examination hall', exam.venue),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 13),
                child: Text('START EXAMINATION'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CandidateRecordCard extends StatelessWidget {
  const _CandidateRecordCard({
    required this.name,
    required this.registrationNumber,
    required this.department,
    required this.level,
    required this.programme,
    required this.photoAsset,
    required this.onDeviceRegistration,
  });

  final String name;
  final String registrationNumber;
  final String department;
  final String level;
  final String programme;
  final String? photoAsset;
  final VoidCallback onDeviceRegistration;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: abuLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CANDIDATE RECORD',
            style: TextStyle(
              color: abuGreen,
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFEAF1E8),
                backgroundImage:
                    photoAsset == null ? null : AssetImage(photoAsset!),
                child: photoAsset == null
                    ? const Icon(Icons.person_outline, color: abuGreen)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      registrationNumber,
                      style: const TextStyle(color: abuMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: abuLine),
          _Info(Icons.school_outlined, 'Department', department),
          _Info(Icons.layers_outlined, 'Level', level),
          _Info(Icons.badge_outlined, 'Programme', programme),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onDeviceRegistration,
              icon: const Icon(Icons.computer_rounded, size: 17),
              label: const Text('Device registration'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoExamCard extends StatelessWidget {
  const _NoExamCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: abuLine),
      ),
      child: const Column(
        children: [
          Icon(Icons.event_busy_outlined, color: abuMuted, size: 38),
          SizedBox(height: 14),
          Text(
            'No active examination',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
          ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: abuGreen, size: 18),
          const SizedBox(width: 10),
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(color: abuMuted, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: abuInk,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
