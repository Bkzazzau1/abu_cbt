import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/ks_status_chip.dart';
import '../../../data/models/attendance_models.dart';
import '../../../data/models/checkin_models.dart';
import '../../demo/abu_demo_theme.dart';
import '../controller/candidate_checkin_controller.dart';
import '../widgets/invigilator_light_panel.dart';
import '../widgets/invigilator_light_scaffold.dart';
import '../widgets/invigilator_top_actions.dart';

class CandidateCheckInView extends GetView<CandidateCheckInController> {
  const CandidateCheckInView({super.key});

  @override
  Widget build(BuildContext context) {
    return InvigilatorLightScaffold(
      title: 'Candidate Check-In',
      actions: buildInvigilatorTopActions(showSeatMap: true),
      maxContentWidth: 1220,
      body: Obx(() {
        final record = controller.record.value;
        if (record == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          children: [
            _CandidateHeader(record: record),
            const SizedBox(height: 14),
            _AdmissionProgress(record: record),
            if (record.needsAttention) ...[
              const SizedBox(height: 14),
              _AttentionBanner(record: record),
            ],
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final verification = _VerificationPanel(
                  record: record,
                  controller: controller,
                );
                final workstation = _WorkstationPanel(record: record);

                if (constraints.maxWidth < 900) {
                  return Column(
                    children: [
                      verification,
                      const SizedBox(height: 14),
                      workstation,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: verification),
                    const SizedBox(width: 14),
                    Expanded(flex: 2, child: workstation),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            _NextActionPanel(record: record, controller: controller),
          ],
        );
      }),
    );
  }
}

class _CandidateHeader extends StatelessWidget {
  const _CandidateHeader({required this.record});

  final CandidateCheckInRecord record;

  @override
  Widget build(BuildContext context) {
    return LightPanel(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 27,
            backgroundColor: Color(0xFFE8F2EB),
            child: Icon(Icons.person_outline, color: abuGreen, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.candidateName.isEmpty
                      ? 'Candidate not identified'
                      : record.candidateName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  record.registrationNumber.isEmpty
                      ? 'Registration number unavailable'
                      : record.registrationNumber,
                  style: const TextStyle(
                    color: abuMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  record.hallName.isEmpty ? 'Hall not assigned' : record.hallName,
                  style: const TextStyle(
                    color: abuGreen,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          _statusChip(record.status),
        ],
      ),
    );
  }
}

class _AdmissionProgress extends StatelessWidget {
  const _AdmissionProgress({required this.record});

  final CandidateCheckInRecord record;

  @override
  Widget build(BuildContext context) {
    final current = _stageIndex(record.status);
    final steps = const [
      ('Expected', Icons.schedule_outlined),
      ('Checked In', Icons.how_to_reg_outlined),
      ('Verified', Icons.verified_user_outlined),
      ('Authorized', Icons.lock_open_outlined),
      ('In Exam', Icons.task_alt_outlined),
    ];

    return LightPanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 760) {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                steps.length,
                (index) => _ProgressStep(
                  label: steps[index].$1,
                  icon: steps[index].$2,
                  complete: index < current,
                  active: index == current,
                ),
              ),
            );
          }

          return Row(
            children: List.generate(steps.length, (index) {
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _ProgressStep(
                        label: steps[index].$1,
                        icon: steps[index].$2,
                        complete: index < current,
                        active: index == current,
                      ),
                    ),
                    if (index < steps.length - 1)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5),
                        child: Icon(Icons.chevron_right, size: 18),
                      ),
                  ],
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({
    required this.label,
    required this.icon,
    required this.complete,
    required this.active,
  });

  final String label;
  final IconData icon;
  final bool complete;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final emphasized = active || complete;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
      decoration: BoxDecoration(
        color: active ? abuGreen.withValues(alpha: 0.08) : null,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: emphasized ? abuGreen.withValues(alpha: 0.35) : abuLine,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            complete ? Icons.check_circle : icon,
            size: 18,
            color: emphasized ? abuGreen : abuMuted,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                color: emphasized ? abuInk : abuMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttentionBanner extends StatelessWidget {
  const _AttentionBanner({required this.record});

  final CandidateCheckInRecord record;

  @override
  Widget build(BuildContext context) {
    final mismatch = record.identityState == IdentityVerificationState.mismatch;
    final manual = record.identityState == IdentityVerificationState.manualReview;
    final message = mismatch
        ? 'Biometric identity mismatch. Do not authorize until identity is resolved.'
        : manual
        ? 'Biometric result requires manual invigilator review. Add a review note before approval.'
        : 'This candidate has a check-in issue requiring invigilator attention.';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Verification attention required',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(message, style: const TextStyle(height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationPanel extends StatelessWidget {
  const _VerificationPanel({required this.record, required this.controller});

  final CandidateCheckInRecord record;
  final CandidateCheckInController controller;

  @override
  Widget build(BuildContext context) {
    final checkedIn = record.status != CandidateCheckInStatus.pending;

    return LightPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Admission Verification',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Identity and exam eligibility must pass before authorization. Workstation allocation is handled separately.',
            style: TextStyle(
              color: abuMuted,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          _CheckRow(
            icon: Icons.face_retouching_natural_outlined,
            title: 'Identity & Biometric',
            subtitle: _identitySubtitle(record),
            complete: record.identityVerified,
            attention:
                record.identityState == IdentityVerificationState.mismatch ||
                record.identityState == IdentityVerificationState.manualReview,
            actionLabel: _identityActionLabel(record),
            onPressed: !checkedIn
                ? null
                : record.identityState == IdentityVerificationState.manualReview
                ? controller.approveManualReview
                : record.identityVerified
                ? null
                : controller.runIdentityVerification,
          ),
          const SizedBox(height: 10),
          _CheckRow(
            icon: Icons.menu_book_outlined,
            title: 'Exam Eligibility',
            subtitle: record.examTitle.isEmpty
                ? 'No exam assigned'
                : record.examTitle,
            complete: record.examVerified,
            actionLabel: 'Confirm Exam',
            onPressed: checkedIn && !record.examVerified
                ? controller.confirmExam
                : null,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller.notesController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Invigilator verification note',
              hintText: 'Required for manual identity review; optional otherwise.',
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
        ],
      ),
    );
  }

  String _identitySubtitle(CandidateCheckInRecord record) {
    final confidence = record.biometricConfidence > 0
        ? ' • ${record.biometricConfidence.toStringAsFixed(0)}% confidence'
        : '';
    switch (record.identityState) {
      case IdentityVerificationState.pending:
        return 'Awaiting identity verification$confidence';
      case IdentityVerificationState.matched:
        return 'Identity matched$confidence';
      case IdentityVerificationState.mismatch:
        return 'Identity mismatch$confidence';
      case IdentityVerificationState.manualReview:
        return 'Manual review required$confidence';
    }
  }

  String _identityActionLabel(CandidateCheckInRecord record) {
    switch (record.identityState) {
      case IdentityVerificationState.manualReview:
        return 'Approve Review';
      case IdentityVerificationState.mismatch:
        return 'Recheck Identity';
      case IdentityVerificationState.matched:
        return 'Verified';
      case IdentityVerificationState.pending:
        return 'Verify Identity';
    }
  }
}

class _WorkstationPanel extends StatelessWidget {
  const _WorkstationPanel({required this.record});

  final CandidateCheckInRecord record;

  @override
  Widget build(BuildContext context) {
    final assigned = record.hasWorkstationAssignment;

    return LightPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                assigned
                    ? Icons.desktop_windows_outlined
                    : Icons.event_seat_outlined,
                color: assigned ? abuGreen : abuMuted,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Workstation Allocation',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (assigned) ...[
            _DetailRow(label: 'Hall', value: record.hallName),
            _DetailRow(label: 'Physical seat', value: record.seatNumber),
            _DetailRow(label: 'Workstation', value: record.workstationId),
            const SizedBox(height: 8),
            const Text(
              'This is an exam-session workstation binding, not a permanent student seat.',
              style: TextStyle(
                color: abuMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: abuCanvas,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: abuLine),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No workstation assigned yet',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'This is valid. In Free Seating the workstation is chosen by the candidate and locked at successful login. Manual/System modes may reserve one before login.',
                    style: TextStyle(
                      color: abuMuted,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Get.offNamed(Routes.workstationAllocation),
              icon: const Icon(Icons.assignment_ind_outlined),
              label: const Text('Open Workstation Allocation'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.complete,
    required this.actionLabel,
    this.attention = false,
    this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool complete;
  final bool attention;
  final String actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final color = attention
        ? const Color(0xFFF59E0B)
        : complete
        ? abuGreen
        : abuMuted;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Icon(complete ? Icons.check_circle_outline : icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: abuMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (onPressed != null)
            TextButton(onPressed: onPressed, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _NextActionPanel extends StatelessWidget {
  const _NextActionPanel({required this.record, required this.controller});

  final CandidateCheckInRecord record;
  final CandidateCheckInController controller;

  @override
  Widget build(BuildContext context) {
    return LightPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Next Action',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          _primaryAction(record, controller),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (record.status != CandidateCheckInStatus.inExam &&
                  record.status != CandidateCheckInStatus.absent)
                OutlinedButton.icon(
                  onPressed: controller.markAbsent,
                  icon: const Icon(Icons.person_off_outlined),
                  label: const Text('Mark Absent'),
                ),
              OutlinedButton.icon(
                onPressed: () => Get.toNamed(
                  Routes.incidentReport,
                  arguments: record,
                ),
                icon: const Icon(Icons.report_problem_outlined),
                label: const Text('Report Incident'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _primaryAction(
    CandidateCheckInRecord record,
    CandidateCheckInController controller,
  ) {
    switch (record.status) {
      case CandidateCheckInStatus.pending:
        return FilledButton.icon(
          onPressed: controller.markCheckedIn,
          icon: const Icon(Icons.how_to_reg_outlined),
          label: const Text('Record Candidate Check-In'),
        );
      case CandidateCheckInStatus.checkedIn:
        if (!record.identityVerified) {
          if (record.identityState == IdentityVerificationState.manualReview) {
            return FilledButton.icon(
              onPressed: controller.approveManualReview,
              icon: const Icon(Icons.badge_outlined),
              label: const Text('Approve Manual Identity Review'),
            );
          }
          return FilledButton.icon(
            onPressed: controller.runIdentityVerification,
            icon: const Icon(Icons.fingerprint),
            label: const Text('Verify Identity'),
          );
        }
        if (!record.examVerified) {
          return FilledButton.icon(
            onPressed: controller.confirmExam,
            icon: const Icon(Icons.menu_book_outlined),
            label: const Text('Confirm Exam Eligibility'),
          );
        }
        return const Text('Verification checks complete.');
      case CandidateCheckInStatus.verified:
        return FilledButton.icon(
          onPressed: controller.authorize,
          icon: const Icon(Icons.verified_user_outlined),
          label: const Text('Authorize Candidate'),
        );
      case CandidateCheckInStatus.authorized:
        return const _InfoAction(
          icon: Icons.login_outlined,
          title: 'Authorized — awaiting workstation login',
          message:
              'The active allocation policy will determine the workstation. In Exam is recorded after a successful workstation login lock.',
        );
      case CandidateCheckInStatus.inExam:
        return const _InfoAction(
          icon: Icons.check_circle_outline,
          title: 'Candidate is in exam',
          message: 'A workstation login has been confirmed for this candidate.',
        );
      case CandidateCheckInStatus.absent:
        return const _InfoAction(
          icon: Icons.person_off_outlined,
          title: 'Candidate marked absent',
          message: 'No admission action is currently required.',
        );
      case CandidateCheckInStatus.issueFlagged:
        return const _InfoAction(
          icon: Icons.warning_amber_outlined,
          title: 'Resolve verification issue',
          message: 'Review the identity issue before candidate authorization.',
        );
    }
  }
}

class _InfoAction extends StatelessWidget {
  const _InfoAction({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: abuCanvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: abuLine),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: abuGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    color: abuMuted,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(
                color: abuMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

KsStatusChip _statusChip(CandidateCheckInStatus status) {
  switch (status) {
    case CandidateCheckInStatus.pending:
      return const KsStatusChip(
        label: 'Expected',
        tone: KsStatusChipTone.neutral,
      );
    case CandidateCheckInStatus.checkedIn:
      return const KsStatusChip(
        label: 'Checked In',
        tone: KsStatusChipTone.primary,
      );
    case CandidateCheckInStatus.verified:
      return const KsStatusChip(
        label: 'Verified',
        tone: KsStatusChipTone.success,
      );
    case CandidateCheckInStatus.authorized:
      return const KsStatusChip(
        label: 'Authorized',
        tone: KsStatusChipTone.success,
      );
    case CandidateCheckInStatus.inExam:
      return const KsStatusChip(
        label: 'In Exam',
        tone: KsStatusChipTone.success,
      );
    case CandidateCheckInStatus.absent:
      return const KsStatusChip(
        label: 'Absent',
        tone: KsStatusChipTone.neutral,
      );
    case CandidateCheckInStatus.issueFlagged:
      return const KsStatusChip(
        label: 'Attention',
        tone: KsStatusChipTone.warning,
      );
  }
}

int _stageIndex(CandidateCheckInStatus status) {
  switch (status) {
    case CandidateCheckInStatus.pending:
      return 0;
    case CandidateCheckInStatus.checkedIn:
    case CandidateCheckInStatus.issueFlagged:
      return 1;
    case CandidateCheckInStatus.verified:
      return 2;
    case CandidateCheckInStatus.authorized:
      return 3;
    case CandidateCheckInStatus.inExam:
      return 4;
    case CandidateCheckInStatus.absent:
      return 0;
  }
}
