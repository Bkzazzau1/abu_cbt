import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../data/models/center_exam_models.dart';
import '../../demo/abu_demo_theme.dart';
import '../../portal/controller/center_exam_portal_controller.dart';

CenterExam? currentExamArgument() {
  final arg = Get.arguments;
  if (arg is CenterExam) return arg;
  if (arg is Map && arg['exam'] is CenterExam) return arg['exam'] as CenterExam;
  return null;
}

class ExamPreflightView extends StatefulWidget {
  const ExamPreflightView({super.key, this.confirmation = false});

  final bool confirmation;

  @override
  State<ExamPreflightView> createState() => _ExamPreflightViewState();
}

class _ExamPreflightViewState extends State<ExamPreflightView> {
  bool confirmed = false;

  @override
  Widget build(BuildContext context) {
    final exam = currentExamArgument();
    final candidate = Get.isRegistered<CenterExamPortalController>()
        ? Get.find<CenterExamPortalController>().candidate.value
        : null;

    return Theme(
      data: abuDemoTheme(),
      child: Scaffold(
        backgroundColor: abuCanvas,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/senate.png', fit: BoxFit.cover),
            Container(color: abuCanvas.withValues(alpha: 0.9)),
            SafeArea(
              child: Column(
                children: [
                  _Header(
                    courseCode: exam?.courseCode ?? 'Examination',
                    onBack: () => Get.back(),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 42),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1050),
                          child: exam == null
                              ? _MissingExam(onReturn: () => Get.offAllNamed(Routes.centerPortal))
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _StepBar(confirmation: widget.confirmation),
                                    const SizedBox(height: 28),
                                    Text(
                                      widget.confirmation
                                          ? 'Confirm candidate and examination details'
                                          : 'Official examination instructions',
                                      style: const TextStyle(
                                        color: abuInk,
                                        fontSize: 30,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      widget.confirmation
                                          ? 'Your examination timer starts immediately after you select Begin Examination.'
                                          : 'Read the instructions carefully. This is an official timed examination and all examination rules apply.',
                                      style: const TextStyle(
                                        color: abuMuted,
                                        fontSize: 13,
                                        height: 1.6,
                                      ),
                                    ),
                                    const SizedBox(height: 26),
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        final wide = constraints.maxWidth >= 780;
                                        final main = widget.confirmation
                                            ? _ConfirmationCard(
                                                candidateName: candidate?.fullName ?? 'Candidate',
                                                registrationNumber: candidate?.registrationNumber ?? '--',
                                                department: candidate?.department ?? '--',
                                                level: candidate?.level ?? '--',
                                                exam: exam,
                                                confirmed: confirmed,
                                                onChanged: (value) => setState(() => confirmed = value),
                                              )
                                            : const _InstructionCard();
                                        final examCard = _ExamSummaryCard(exam: exam);
                                        if (!wide) {
                                          return Column(
                                            children: [
                                              main,
                                              const SizedBox(height: 18),
                                              examCard,
                                            ],
                                          );
                                        }
                                        return Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(flex: 3, child: main),
                                            const SizedBox(width: 22),
                                            Expanded(flex: 2, child: examCard),
                                          ],
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 22),
                                    _ActionBar(
                                      confirmation: widget.confirmation,
                                      enabled: !widget.confirmation || confirmed,
                                      onBack: () => Get.back(),
                                      onNext: () {
                                        if (widget.confirmation) {
                                          Get.offNamed(Routes.centerExamRun, arguments: exam);
                                        } else {
                                          Get.toNamed(Routes.centerExamConfirmation, arguments: exam);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
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
  const _Header({required this.courseCode, required this.onBack});
  final String courseCode;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: abuLine)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 6),
          Image.asset('assets/abulogo.png', width: 40, height: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ahmadu Bello University, Zaria',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  '$courseCode · SECURE CBT EXAMINATION',
                  style: const TextStyle(
                    color: abuMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F2EB),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Text(
              'OFFICIAL EXAM',
              style: TextStyle(
                color: abuGreen,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepBar extends StatelessWidget {
  const _StepBar({required this.confirmation});
  final bool confirmation;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Step(number: '1', label: 'Instructions', active: !confirmation, complete: confirmation),
        const Expanded(child: Divider(color: abuLine, indent: 10, endIndent: 10)),
        _Step(number: '2', label: 'Confirmation', active: confirmation, complete: false),
        const Expanded(child: Divider(color: abuLine, indent: 10, endIndent: 10)),
        const _Step(number: '3', label: 'Examination', active: false, complete: false),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.label, required this.active, required this.complete});
  final String number;
  final String label;
  final bool active;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: active || complete ? abuGreen : const Color(0xFFE4E8E5),
          child: complete
              ? const Icon(Icons.check, color: Colors.white, size: 15)
              : Text(
                  number,
                  style: TextStyle(
                    color: active ? Colors.white : abuMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: active || complete ? abuInk : abuMuted,
            fontSize: 11,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _InstructionCard extends StatelessWidget {
  const _InstructionCard();

  @override
  Widget build(BuildContext context) {
    final rules = <(IconData, String, String)>[
      (
        Icons.person_outline_rounded,
        'Candidate identity',
        'Only the verified candidate may sit this examination. Remain at your assigned workstation and seat throughout the session.',
      ),
      (
        Icons.visibility_outlined,
        'Integrity monitoring',
        'Camera, workstation and examination-integrity signals may be monitored. Alerts are reviewed by authorised invigilators.',
      ),
      (
        Icons.devices_other_outlined,
        'Unauthorised devices',
        'Do not use phones, external storage, secondary devices or any unauthorised material during the examination.',
      ),
      (
        Icons.timer_outlined,
        'Time control',
        'The examination is timed. The system may submit automatically when the authorised duration expires.',
      ),
      (
        Icons.save_outlined,
        'Answer retention',
        'Your responses are retained during the examination. Review flagged or unanswered questions before final submission.',
      ),
      (
        Icons.support_agent_outlined,
        'Technical issue',
        'If you experience a workstation, camera or network problem, remain seated and signal the invigilator immediately.',
      ),
    ];

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Examination rules',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 22),
          ...rules.map(
            (rule) => Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF4EF),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(rule.$1, color: abuGreen, size: 19),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rule.$2,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          rule.$3,
                          style: const TextStyle(color: abuMuted, fontSize: 12, height: 1.65),
                        ),
                      ],
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

class _ConfirmationCard extends StatelessWidget {
  const _ConfirmationCard({
    required this.candidateName,
    required this.registrationNumber,
    required this.department,
    required this.level,
    required this.exam,
    required this.confirmed,
    required this.onChanged,
  });

  final String candidateName;
  final String registrationNumber;
  final String department;
  final String level;
  final CenterExam exam;
  final bool confirmed;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Candidate confirmation',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 22),
          _Detail('Candidate name', candidateName),
          _Detail('Registration number', registrationNumber),
          _Detail('Department', department),
          _Detail('Level', level),
          _Detail('Course', '${exam.courseCode} · ${exam.courseTitle}'),
          _Detail('Duration', '${exam.durationMinutes} minutes'),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDCE7DD)),
            ),
            child: CheckboxListTile(
              value: confirmed,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (value) => onChanged(value ?? false),
              title: const Text(
                'I confirm that these details are mine and I am ready to begin this official examination.',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, height: 1.45),
              ),
              subtitle: const Padding(
                padding: EdgeInsets.only(top: 5),
                child: Text(
                  'Selecting Begin Examination starts the official timer and examination monitoring.',
                  style: TextStyle(color: abuMuted, fontSize: 11, height: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamSummaryCard extends StatelessWidget {
  const _ExamSummaryCard({required this.exam});
  final CenterExam exam;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'EXAMINATION DETAILS',
            style: TextStyle(
              color: abuGreen,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            exam.courseCode,
            style: const TextStyle(color: abuGreen, fontWeight: FontWeight.w800, fontSize: 14),
          ),
          const SizedBox(height: 5),
          Text(
            exam.courseTitle,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22, height: 1.25),
          ),
          const SizedBox(height: 20),
          const Divider(color: abuLine),
          _Detail('Duration', '${exam.durationMinutes} minutes'),
          _Detail('Questions', '${exam.questions.length}'),
          _Detail('Venue', exam.venue),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF1D3A7)),
            ),
            child: const Text(
              'Do not close, refresh or leave the examination application after the timer starts.',
              style: TextStyle(color: Color(0xFF8A5B18), fontSize: 11, fontWeight: FontWeight.w700, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.confirmation,
    required this.enabled,
    required this.onBack,
    required this.onNext,
  });

  final bool confirmation;
  final bool enabled;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 14,
      runSpacing: 12,
      children: [
        OutlinedButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded, size: 17),
          label: Text(confirmation ? 'Back to instructions' : 'Back to current exam'),
        ),
        FilledButton.icon(
          onPressed: enabled ? onNext : null,
          icon: Icon(confirmation ? Icons.play_arrow_rounded : Icons.arrow_forward_rounded),
          label: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Text(confirmation ? 'BEGIN EXAMINATION' : 'CONTINUE TO CONFIRMATION'),
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: abuLine),
        boxShadow: const [
          BoxShadow(color: Color(0x0C000000), blurRadius: 22, offset: Offset(0, 8)),
        ],
      ),
      child: child,
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(label, style: const TextStyle(color: abuMuted, fontSize: 12)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissingExam extends StatelessWidget {
  const _MissingExam({required this.onReturn});
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFB07500), size: 42),
          const SizedBox(height: 14),
          const Text(
            'No examination was loaded',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Return to the examination portal and ask an invigilator for assistance if the issue continues.',
            textAlign: TextAlign.center,
            style: TextStyle(color: abuMuted, height: 1.6),
          ),
          const SizedBox(height: 18),
          FilledButton(onPressed: onReturn, child: const Text('RETURN TO EXAMINATION PORTAL')),
        ],
      ),
    );
  }
}
