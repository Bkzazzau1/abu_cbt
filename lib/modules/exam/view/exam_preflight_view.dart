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

  /// true = candidate/exam record confirmation; false = examination rules.
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
            Container(color: abuCanvas.withValues(alpha: 0.90)),
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
                              ? _MissingExam(
                                  onReturn: () =>
                                      Get.offAllNamed(Routes.centerPortal),
                                )
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _StepBar(
                                      verificationActive: widget.confirmation,
                                      instructionsActive: !widget.confirmation,
                                    ),
                                    const SizedBox(height: 28),
                                    Text(
                                      widget.confirmation
                                          ? 'Verify your candidate and examination record'
                                          : 'Read the official examination instructions',
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
                                          ? 'Confirm that the university record shown below belongs to you and that the current examination is correct.'
                                          : 'Read these rules carefully. Fingerprint authentication is the final step after this page; the examination timer has not started yet.',
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
                                            ? _VerificationCard(
                                                candidateName:
                                                    candidate?.fullName ??
                                                    'Candidate',
                                                registrationNumber: candidate
                                                        ?.registrationNumber ??
                                                    '--',
                                                department:
                                                    candidate?.department ?? '--',
                                                level: candidate?.level ?? '--',
                                                programme:
                                                    candidate?.programme ?? '--',
                                                exam: exam,
                                                confirmed: confirmed,
                                                onChanged: (value) => setState(
                                                  () => confirmed = value,
                                                ),
                                              )
                                            : const _InstructionCard();
                                        final examCard =
                                            _ExamSummaryCard(exam: exam);

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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                      verification: widget.confirmation,
                                      enabled:
                                          !widget.confirmation || confirmed,
                                      onBack: () => Get.back(),
                                      onNext: () {
                                        if (widget.confirmation) {
                                          Get.toNamed(
                                            Routes.centerExamInstruction,
                                            arguments: exam,
                                          );
                                        } else {
                                          Get.toNamed(
                                            Routes.centerExamFingerprint,
                                            arguments: exam,
                                          );
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
                  '$courseCode · EXAMINATION ACCESS',
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
  const _StepBar({
    required this.verificationActive,
    required this.instructionsActive,
  });

  final bool verificationActive;
  final bool instructionsActive;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Step(
            number: '1',
            label: 'Candidate details',
            active: verificationActive,
            complete: instructionsActive,
          ),
          const _StepDivider(),
          _Step(
            number: '2',
            label: 'Instructions',
            active: instructionsActive,
            complete: false,
          ),
          const _StepDivider(),
          const _Step(
            number: '3',
            label: 'Fingerprint',
            active: false,
            complete: false,
          ),
          const _StepDivider(),
          const _Step(
            number: '4',
            label: 'Examination',
            active: false,
            complete: false,
          ),
        ],
      ),
    );
  }
}

class _StepDivider extends StatelessWidget {
  const _StepDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: abuLine,
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.label,
    required this.active,
    required this.complete,
  });

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
          backgroundColor:
              active || complete ? abuGreen : const Color(0xFFE4E8E5),
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

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({
    required this.candidateName,
    required this.registrationNumber,
    required this.department,
    required this.level,
    required this.programme,
    required this.exam,
    required this.confirmed,
    required this.onChanged,
  });

  final String candidateName;
  final String registrationNumber;
  final String department;
  final String level;
  final String programme;
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
            'University candidate record',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'These details are supplied by the university. Students cannot create or edit this record from the examination portal.',
            style: TextStyle(color: abuMuted, fontSize: 11, height: 1.6),
          ),
          const SizedBox(height: 22),
          _Detail('Candidate name', candidateName),
          _Detail('Registration number', registrationNumber),
          _Detail('Department', department),
          _Detail('Level', level),
          _Detail('Programme', programme),
          _Detail('Course', '${exam.courseCode} · ${exam.courseTitle}'),
          _Detail('Venue', exam.venue),
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
                'I confirm that the candidate and examination details displayed are correct.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  height: 1.45,
                ),
              ),
              subtitle: const Padding(
                padding: EdgeInsets.only(top: 5),
                child: Text(
                  'This does not start the examination timer. Fingerprint authentication is still required before the exam opens.',
                  style: TextStyle(
                    color: abuMuted,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
        'Only the authorised candidate may sit the examination. Remain at your assigned workstation and seat throughout the session.',
      ),
      (
        Icons.visibility_outlined,
        'Integrity monitoring',
        'Camera, workstation and examination-integrity signals may be monitored. Alerts are reviewed by authorised invigilators.',
      ),
      (
        Icons.devices_other_outlined,
        'Unauthorised devices',
        'Do not use phones, external storage, secondary devices or unauthorised materials during the examination.',
      ),
      (
        Icons.timer_outlined,
        'Time control',
        'The examination is timed. The timer starts only after successful fingerprint authentication opens the examination screen.',
      ),
      (
        Icons.save_outlined,
        'Answer retention',
        'Responses are retained during the examination. Review flagged or unanswered questions before final submission.',
      ),
      (
        Icons.support_agent_outlined,
        'Technical issue',
        'If you experience a workstation, camera, fingerprint-reader or network problem, remain seated and signal the invigilator.',
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
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          rule.$3,
                          style: const TextStyle(
                            color: abuMuted,
                            fontSize: 12,
                            height: 1.65,
                          ),
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
            style: const TextStyle(
              color: abuGreen,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            exam.courseTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              height: 1.25,
            ),
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
              'The examination remains locked until the final fingerprint step is completed successfully.',
              style: TextStyle(
                color: Color(0xFF8A5B18),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.verification,
    required this.enabled,
    required this.onBack,
    required this.onNext,
  });

  final bool verification;
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
          label: Text(
            verification ? 'Back to dashboard' : 'Back to candidate details',
          ),
        ),
        FilledButton.icon(
          onPressed: enabled ? onNext : null,
          icon: const Icon(Icons.arrow_forward_rounded, size: 17),
          label: Text(
            verification
                ? 'CONTINUE TO INSTRUCTIONS'
                : 'PROCEED TO FINGERPRINT',
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: abuLine),
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
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 145,
            child: Text(
              label,
              style: const TextStyle(color: abuMuted, fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: abuInk,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
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
          const Icon(Icons.event_busy_outlined, color: abuMuted, size: 42),
          const SizedBox(height: 14),
          const Text(
            'Examination session unavailable',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Return to the examination dashboard and select the current examination again.',
            textAlign: TextAlign.center,
            style: TextStyle(color: abuMuted, height: 1.6),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: onReturn,
            child: const Text('Return to dashboard'),
          ),
        ],
      ),
    );
  }
}
