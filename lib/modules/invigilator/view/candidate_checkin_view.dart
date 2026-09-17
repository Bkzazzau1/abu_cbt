import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/ks_status_chip.dart';
import '../../../data/models/attendance_models.dart';
import '../../../data/models/checkin_models.dart';
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
      maxContentWidth: 1240,
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
                final wide = constraints.maxWidth >= 900;
                final verification = _VerificationPanel(
                  record: record,
                  controller: controller,
                );
                final assignment = _AssignmentPanel(
                  record: record,
                  controller: controller,
                );

                if (!wide) {
                  return Column(
                    children: [
                      verification,
                      const SizedBox(height: 14),
                      assignment,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: verification),
                    const SizedBox(width: 14),
                    Expanded(flex: 2, child: assignment),
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
    final cs = Theme.of(context).colorScheme;
    return LightPanel(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          CircleAvatar(
            radius: 27,
            backgroundColor: cs.primary.withValues(alpha: 0.10),
            child: Icon(Icons.person_outline, color: cs.primary, size: 30),
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
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.66),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${record.hallName} • Seat ${record.seatNumber}',
                  style: TextStyle(
                    color: cs.primary,
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
      ('Expected', Icons.event_seat_outlined),
      ('Checked In', Icons.how_to_reg_outlined),
      ('Verified', Icons.verified_user_outlined),
      ('Authorized', Icons.lock_open_outlined),
      ('In Exam', Icons.task_alt_outlined),
    ];

    return LightPanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          if (compact) {
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
    final cs = Theme.of(context).colorScheme;
    final emphasized = active || complete;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: active ? cs.primary.withValues(alpha: 0.09) : null,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: emphasized ? cs.primary.withValues(alpha: 0.34) : cs.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            complete ? Icons.check_circle : icon,
            size: 18,
            color: emphasized ? cs.primary : cs.onSurface.withValues(alpha: 0.48),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                color: emphasized
                    ? cs.onSurface
                    : cs.onSurface.withValues(alpha: 0.58),
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
        ? 'Biometric identity mismatch. Candidate must not be authorized until the issue is resolved.'
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
            'Verification Checks',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'All three checks must pass before authorization.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.64),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          _CheckRow(
            icon: Icons.face_retouching_natural_outlined,
            title: 'Identity & Biometric',
            subtitle: _identitySubtitle(record),
            complete: record.identityVerified,
            attention: record.identityState == IdentityVerificationState.mismatch ||
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
            icon: Icons.event_seat_outlined,
            title: 'Assigned Seat',
            subtitle: '${record.hallName} • Seat ${record.seatNumber}',
            complete: record.seatVerified,
            actionLabel: 'Confirm Seat',
            onPressed: checkedIn && !record.seatVerified ? controller.confirmSeat : null,
          ),
          const SizedBox(height: 10),
          _CheckRow(
            icon: Icons.menu_book_outlined,
            title: 'Assigned Exam',
            subtitle: record.examTitle.isEmpty ? 'No exam assigned' : record.examTitle,
            complete: record.examVerified,
            actionLabel: 'Confirm Exam',
            onPressed: checkedIn && !record.examVerified ? controller.confirmExam : null,
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
    final cs = Theme.of(context).colorScheme;
    final iconColor = attention
        ? const Color(0xFFF59E0B)
        : complete
            ? const Color(0xFF16A34A)
            : cs.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: iconColor.withValues(alpha: 0.10),
            ),
            child: Icon(complete ? Icons.check_circle_outline : icon, color: iconColor),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.64),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (complete)
            const KsStatusChip(label: 'Passed', tone: KsStatusChipTone.success)
          else
            OutlinedButton(
              onPressed: onPressed,
              child: Text(actionLabel),
            ),
        ],
      ),
    );
  }
}

class _AssignmentPanel extends StatelessWidget {
  const _AssignmentPanel({required this.record, required this.controller});

  final CandidateCheckInRecord record;
  final CandidateCheckInController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LightPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Candidate Assignment',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          _detail('Hall', record.hallName),
          _detail('Seat', record.seatNumber),
          _detail('Workstation', record.workstationId),
          _detail('Exam', record.examTitle),
          const Divider(height: 26),
          const Text(
            'Invigilator Note',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller.notesController,
            minLines: 3,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Add a note for manual review, mismatch, late arrival or other exception...',
              border: OutlineInputBorder(),
            ),
          ),
          if (record.note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Recorded: ${record.note}',
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: cs.onSurface.withValues(alpha: 0.68),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
    final next = _nextAction(record, controller);
    final cs = Theme.of(context).colorScheme;

    return LightPanel(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final description = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Next Action',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                next.description,
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.68),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              if (next.onPressed != null)
                FilledButton.icon(
                  onPressed: next.onPressed,
                  icon: Icon(next.icon),
                  label: Text(next.label),
                ),
              OutlinedButton.icon(
                onPressed: () => controller.flagIssue(),
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Flag Issue'),
              ),
              OutlinedButton.icon(
                onPressed: () => Get.toNamed(
                  Routes.incidentReport,
                  arguments: record,
                ),
                icon: const Icon(Icons.description_outlined),
                label: const Text('Incident'),
              ),
              if (record.status == CandidateCheckInStatus.pending ||
                  record.status == CandidateCheckInStatus.checkedIn)
                TextButton.icon(
                  onPressed: controller.markAbsent,
                  icon: const Icon(Icons.person_off_outlined),
                  label: const Text('Absent'),
                ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [description, const SizedBox(height: 12), actions],
            );
          }
          return Row(
            children: [
              Expanded(child: description),
              const SizedBox(width: 16),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _NextAction {
  const _NextAction({
    required this.label,
    required this.description,
    required this.icon,
    this.onPressed,
  });

  final String label;
  final String description;
  final IconData icon;
  final VoidCallback? onPressed;
}

_NextAction _nextAction(
  CandidateCheckInRecord record,
  CandidateCheckInController controller,
) {
  switch (record.status) {
    case CandidateCheckInStatus.pending:
      return _NextAction(
        label: 'Mark Checked In',
        description: 'Record the candidate arrival to begin verification.',
        icon: Icons.how_to_reg_outlined,
        onPressed: controller.markCheckedIn,
      );
    case CandidateCheckInStatus.checkedIn:
      if (record.identityState == IdentityVerificationState.manualReview) {
        return _NextAction(
          label: 'Approve Manual Review',
          description: 'Add a review note, approve identity, then complete seat and exam checks.',
          icon: Icons.manage_accounts_outlined,
          onPressed: controller.approveManualReview,
        );
      }
      if (record.identityState == IdentityVerificationState.mismatch ||
          record.status == CandidateCheckInStatus.issueFlagged) {
        return const _NextAction(
          label: 'Resolve Identity Issue',
          description: 'Authorization is blocked until the identity issue is resolved.',
          icon: Icons.warning_amber_outlined,
        );
      }
      if (!record.identityVerified) {
        return _NextAction(
          label: 'Verify Identity',
          description: 'Run the identity and biometric verification check.',
          icon: Icons.face_retouching_natural_outlined,
          onPressed: controller.runIdentityVerification,
        );
      }
      if (!record.seatVerified) {
        return _NextAction(
          label: 'Confirm Seat',
          description: 'Confirm that the candidate is seated at the assigned workstation.',
          icon: Icons.event_seat_outlined,
          onPressed: controller.confirmSeat,
        );
      }
      if (!record.examVerified) {
        return _NextAction(
          label: 'Confirm Exam',
          description: 'Confirm the candidate is assigned to the correct examination.',
          icon: Icons.menu_book_outlined,
          onPressed: controller.confirmExam,
        );
      }
      return const _NextAction(
        label: 'Verified',
        description: 'All verification checks are complete.',
        icon: Icons.verified_user_outlined,
      );
    case CandidateCheckInStatus.verified:
      return _NextAction(
        label: 'Authorize Candidate',
        description: 'All checks passed. Authorize the candidate to enter the examination.',
        icon: Icons.lock_open_outlined,
        onPressed: controller.authorize,
      );
    case CandidateCheckInStatus.authorized:
      return _NextAction(
        label: 'Mark In Exam',
        description: 'Candidate is authorized. Confirm that the examination has started.',
        icon: Icons.play_circle_outline,
        onPressed: controller.markInExam,
      );
    case CandidateCheckInStatus.inExam:
      return const _NextAction(
        label: 'Admission Complete',
        description: 'Candidate is verified, authorized and currently in the examination.',
        icon: Icons.task_alt_outlined,
      );
    case CandidateCheckInStatus.absent:
      return const _NextAction(
        label: 'Absent',
        description: 'Candidate is recorded as absent for this examination session.',
        icon: Icons.person_off_outlined,
      );
    case CandidateCheckInStatus.issueFlagged:
      return const _NextAction(
        label: 'Resolve Issue',
        description: 'This check-in is blocked. Review the issue or file an incident report.',
        icon: Icons.warning_amber_outlined,
      );
  }
}

Widget _detail(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
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

Widget _statusChip(CandidateCheckInStatus status) {
  switch (status) {
    case CandidateCheckInStatus.pending:
      return const KsStatusChip(label: 'Expected', tone: KsStatusChipTone.neutral);
    case CandidateCheckInStatus.checkedIn:
      return const KsStatusChip(label: 'Checked In', tone: KsStatusChipTone.info);
    case CandidateCheckInStatus.verified:
      return const KsStatusChip(label: 'Verified', tone: KsStatusChipTone.success);
    case CandidateCheckInStatus.authorized:
      return const KsStatusChip(label: 'Authorized', tone: KsStatusChipTone.success);
    case CandidateCheckInStatus.inExam:
      return const KsStatusChip(label: 'In Exam', tone: KsStatusChipTone.accent);
    case CandidateCheckInStatus.absent:
      return const KsStatusChip(label: 'Absent', tone: KsStatusChipTone.danger);
    case CandidateCheckInStatus.issueFlagged:
      return const KsStatusChip(label: 'Attention', tone: KsStatusChipTone.warningSoft);
  }
}
