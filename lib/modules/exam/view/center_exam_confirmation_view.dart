import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/ks_page_shell.dart';
import '../../../core/widgets/ks_status_chip.dart';
import '../../../data/models/center_exam_models.dart';
import '../../../data/models/workstation_models.dart';
import '../../../data/services/workstation_service.dart';
import '../../portal/controller/center_exam_portal_controller.dart';

class CenterExamConfirmationView extends StatefulWidget {
  const CenterExamConfirmationView({super.key});

  @override
  State<CenterExamConfirmationView> createState() =>
      _CenterExamConfirmationViewState();
}

class _CenterExamConfirmationViewState
    extends State<CenterExamConfirmationView> {
  bool _confirmedIdentity = false;
  WorkstationRegistration? _registration;

  @override
  void initState() {
    super.initState();
    _loadRegistration();
  }

  Future<void> _loadRegistration() async {
    final candidateRegistrationNumber =
        Get.isRegistered<CenterExamPortalController>()
        ? Get.find<CenterExamPortalController>()
                  .candidate
                  .value
                  ?.registrationNumber ??
              ''
        : '';
    final reg = candidateRegistrationNumber.trim().isEmpty
        ? await WorkstationService.loadOrCreate()
        : await WorkstationService.ensureAssignmentFromAttendance(
            candidateRegistrationNumber: candidateRegistrationNumber,
          );
    if (!mounted) return;
    setState(() => _registration = reg);
  }

  CenterExam? _extractExam() {
    final arg = Get.arguments;
    if (arg is CenterExam) return arg;
    if (arg is Map<String, dynamic> && arg['exam'] is CenterExam) {
      return arg['exam'] as CenterExam;
    }
    return null;
  }

  String _extractString(String key, String fallback) {
    final arg = Get.arguments;
    if (arg is Map<String, dynamic> && arg[key] is String) {
      return arg[key] as String;
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final exam = _extractExam();
    final cs = Theme.of(context).colorScheme;
    final candidate = Get.isRegistered<CenterExamPortalController>()
        ? Get.find<CenterExamPortalController>().candidate.value
        : null;

    final seatId = _registration?.seatNumber.trim().isNotEmpty == true
        ? _registration!.seatNumber
        : _extractString('seatId', '--');
    final hallName = _registration?.hallName.trim().isNotEmpty == true
        ? _registration!.hallName
        : _extractString('hallName', '--');
    final deviceId = _registration?.workstationId.trim().isNotEmpty == true
        ? _registration!.workstationId
        : _extractString('deviceId', '--');

    if (exam == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Candidate Confirmation')),
        body: const Center(child: Text('No exam loaded.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Candidate Confirmation'),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: KsPageShell(
        padding: const EdgeInsets.fromLTRB(16, 92, 16, 20),
        maxContentWidth: 980,
        child: ListView(
          children: [
            GlassCard(
              tone: GlassCardTone.primary,
              showGlow: true,
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const KsStatusChip(
                    label: 'Secure Verification',
                    tone: KsStatusChipTone.accent,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Confirm your identity before starting the exam',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Please review your candidate details, assigned seat, and workstation information carefully. If anything is incorrect, notify the invigilator immediately.',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.74),
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 760;

                final identityCard = GlassCard(
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
                      const SizedBox(height: 14),
                      _InfoLine(
                        label: 'Name',
                        value: candidate?.fullName ?? 'Unknown Candidate',
                        strong: true,
                      ),
                      _InfoLine(
                        label: 'Reg No',
                        value: candidate?.registrationNumber ?? 'Not Available',
                      ),
                      _InfoLine(
                        label: 'Course',
                        value: '${exam.courseCode} - ${exam.courseTitle}',
                      ),
                      _InfoLine(label: 'Exam Title', value: exam.courseTitle),
                    ],
                  ),
                );

                final stationCard = GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Seat & Workstation',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _InfoLine(label: 'Seat ID', value: seatId, strong: true),
                      _InfoLine(label: 'Hall', value: hallName),
                      _InfoLine(
                        label: 'Device ID',
                        value: deviceId,
                        strong: true,
                      ),
                      _InfoLine(label: 'Exam Date', value: exam.dateLabel),
                      _InfoLine(
                        label: 'Time',
                        value: '${exam.startTime} - ${exam.endTime}',
                      ),
                    ],
                  ),
                );

                if (compact) {
                  return Column(
                    children: [
                      identityCard,
                      const SizedBox(height: 16),
                      stationCard,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: identityCard),
                    const SizedBox(width: 16),
                    Expanded(child: stationCard),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            GlassCard(
              tone: GlassCardTone.warning,
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.campaign_outlined, color: cs.primary, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Invigilator Note',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Raise your hand if your details are incorrect or if you are not seated at your assigned terminal.',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            GlassCard(
              padding: const EdgeInsets.all(18),
              child: Theme(
                data: Theme.of(context).copyWith(
                  checkboxTheme: CheckboxThemeData(
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                ),
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _confirmedIdentity,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (value) {
                    setState(() => _confirmedIdentity = value ?? false);
                  },
                  title: const Text(
                    'I confirm that this identity and workstation assignment are mine.',
                    style: TextStyle(fontWeight: FontWeight.w700, height: 1.4),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'You must confirm this before the exam session begins.',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _confirmedIdentity
                  ? () => Get.offNamed(Routes.centerExamRun, arguments: exam)
                  : null,
              icon: const Icon(Icons.verified_user_outlined),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              label: const Text(
                'Confirm and Start Exam',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: Get.back,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: cs.onSurface.withValues(alpha: 0.92),
            fontSize: 14,
            height: 1.5,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.62),
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
