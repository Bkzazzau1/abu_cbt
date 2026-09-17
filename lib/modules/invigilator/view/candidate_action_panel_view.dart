import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/ks_status_chip.dart';
import '../../../data/models/candidate_action_models.dart';
import '../../demo/abu_demo_theme.dart';
import '../controller/candidate_action_panel_controller.dart';
import '../widgets/invigilator_light_panel.dart';
import '../widgets/invigilator_light_scaffold.dart';
import '../widgets/invigilator_top_actions.dart';

class CandidateActionPanelView extends GetView<CandidateActionPanelController> {
  const CandidateActionPanelView({super.key});

  @override
  Widget build(BuildContext context) {
    return InvigilatorLightScaffold(
      title: 'Candidate Actions',
      actions: buildInvigilatorTopActions(showSeatMap: true),
      maxContentWidth: 1240,
      body: Obx(() {
        final record = controller.contextRecord.value;
        if (record == null) {
          return const Center(child: Text('No candidate action context found.'));
        }

        return ListView(
          children: [
            _CandidateHeader(record: record),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 980;
                final intervention = Column(
                  children: [
                    _SeatReassignmentCard(controller: controller),
                    const SizedBox(height: 14),
                    _InvigilatorNoteCard(controller: controller),
                  ],
                );
                final controls = Column(
                  children: [
                    _ExamControlsCard(
                      controller: controller,
                      record: record,
                    ),
                    const SizedBox(height: 14),
                    _ReportingCard(record: record),
                  ],
                );

                if (!wide) {
                  return Column(
                    children: [
                      controls,
                      const SizedBox(height: 14),
                      intervention,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: intervention),
                    const SizedBox(width: 14),
                    Expanded(flex: 3, child: controls),
                  ],
                );
              },
            ),
          ],
        );
      }),
    );
  }
}

class _CandidateHeader extends StatelessWidget {
  const _CandidateHeader({required this.record});

  final CandidateActionContext record;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return LightPanel(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;

          final identity = Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: cs.primary.withValues(alpha: 0.10),
                child: Icon(Icons.person_outline, color: cs.primary, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.candidateName.isEmpty
                          ? 'Unknown Candidate'
                          : record.candidateName,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      record.registrationNumber.isEmpty
                          ? '-'
                          : record.registrationNumber,
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.66),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _stateChip(record.currentState),
            ],
          );

          final details = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _contextPill(Icons.meeting_room_outlined, record.hallName),
              _contextPill(
                Icons.event_seat_outlined,
                'Seat ${record.seatNumber}',
              ),
              _contextPill(Icons.desktop_windows_outlined, record.workstationId),
              _contextPill(Icons.menu_book_outlined, record.examTitle),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                identity,
                const SizedBox(height: 12),
                details,
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 2, child: identity),
              const SizedBox(width: 18),
              Expanded(flex: 3, child: details),
            ],
          );
        },
      ),
    );
  }
}

class _SeatReassignmentCard extends StatelessWidget {
  const _SeatReassignmentCard({required this.controller});

  final CandidateActionPanelController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return LightPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.swap_horiz_outlined, color: cs.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Seat & Workstation Intervention',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'Move the candidate only when necessary. The exam context is preserved and every transfer creates an audit record.',
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.66),
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 700;

              final destination = Obx(() {
                final current = controller.contextRecord.value;
                final seats = controller.availableDestinationSeats;
                final selected = controller.selectedDestinationSeat.value;

                return DropdownButtonFormField<String>(
                  initialValue: selected.isEmpty ? null : selected,
                  isExpanded: true,
                  items: seats
                      .map(
                        (seat) => DropdownMenuItem<String>(
                          value: seat.seatNumber,
                          child: Text(
                            '${seat.seatNumber} • ${seat.workstationId}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: controller.isProcessing.value ||
                          controller.isForceSubmitted ||
                          seats.isEmpty
                      ? null
                      : controller.selectDestinationSeat,
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: 'Destination seat',
                    helperText: seats.isEmpty
                        ? 'No verified available seat in ${current?.hallName ?? 'this hall'}.'
                        : '${seats.length} available seat(s)',
                    prefixIcon: const Icon(Icons.chair_alt_outlined),
                    border: const OutlineInputBorder(),
                  ),
                );
              });

              final reason = Obx(() {
                return DropdownButtonFormField<SeatReassignmentReason>(
                  initialValue: controller.selectedReassignmentReason.value,
                  isExpanded: true,
                  items: SeatReassignmentReason.values
                      .map(
                        (item) => DropdownMenuItem<SeatReassignmentReason>(
                          value: item,
                          child: Text(item.label),
                        ),
                      )
                      .toList(),
                  onChanged: controller.isProcessing.value ||
                          controller.isForceSubmitted
                      ? null
                      : controller.selectReassignmentReason,
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'Reason',
                    prefixIcon: Icon(Icons.assignment_outlined),
                    border: OutlineInputBorder(),
                  ),
                );
              });

              if (compact) {
                return Column(
                  children: [
                    destination,
                    const SizedBox(height: 12),
                    reason,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: destination),
                  const SizedBox(width: 12),
                  Expanded(child: reason),
                ],
              );
            },
          ),
          Obx(() {
            final selectedSeat = controller.selectedDestinationRecord;
            final selectedReason = controller.selectedReassignmentReason.value;
            if (selectedSeat == null && selectedReason == null) {
              return const SizedBox(height: 14);
            }

            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.045),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: cs.primary.withValues(alpha: 0.14),
                  ),
                ),
                child: Wrap(
                  spacing: 18,
                  runSpacing: 6,
                  children: [
                    if (selectedSeat != null)
                      Text(
                        'New workstation: ${selectedSeat.workstationId}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    if (selectedReason != null)
                      Text(
                        selectedReason.marksOldSeatAsTechnicalIssue
                            ? 'Old seat: Technical Issue'
                            : 'Old seat: Available',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    const Text(
                      'Exam: Preserved',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          Row(
            children: [
              Obx(
                () => FilledButton.icon(
                  onPressed: controller.canReassignSeat
                      ? () => _confirmReassignment(context, controller)
                      : null,
                  icon: controller.isProcessing.value
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.event_seat_outlined),
                  label: const Text('Review Seat Move'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Use the note below for unusual circumstances or the “Other” reason.',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.60),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          Obx(() {
            final event = controller.lastSeatReassignment.value;
            if (event == null) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.22),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.history_outlined,
                      size: 18,
                      color: Color(0xFF15803D),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${event.oldSeatNumber} → ${event.newSeatNumber} • ${event.reason.label}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      event.id,
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.58),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _InvigilatorNoteCard extends StatelessWidget {
  const _InvigilatorNoteCard({required this.controller});

  final CandidateActionPanelController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LightPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Intervention Note',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'Optional for routine controls; required when a seat move uses the “Other” reason.',
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.64),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller.noteController,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText:
                  'Example: Keyboard failed; candidate moved and continued exam.',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamControlsCard extends StatelessWidget {
  const _ExamControlsCard({
    required this.controller,
    required this.record,
  });

  final CandidateActionPanelController controller;
  final CandidateActionContext record;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final danger = const Color(0xFFB91C1C);

    return LightPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Exam Controls',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'Use controls only for the selected candidate.',
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.64),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Obx(() {
            final paused = controller.isExamPaused;
            return SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: paused
                    ? (controller.canResumeExam ? controller.resumeExam : null)
                    : (controller.canPauseExam ? controller.pauseExam : null),
                icon: Icon(
                  paused
                      ? Icons.play_circle_outline
                      : Icons.pause_circle_outline,
                ),
                label: Text(paused ? 'Resume Exam' : 'Pause Exam'),
              ),
            );
          }),
          const SizedBox(height: 8),
          Obx(
            () => SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: controller.canAllowLateEntry
                    ? controller.allowLateEntry
                    : null,
                icon: const Icon(Icons.schedule_outlined),
                label: const Text('Allow Late Entry'),
              ),
            ),
          ),
          const Divider(height: 28),
          Text(
            'Final action',
            style: TextStyle(
              color: danger,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            controller.isForceSubmitted
                ? 'This candidate exam has been submitted.'
                : 'Force Submit ends the candidate exam. Confirmation is required.',
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.66),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Obx(
            () => SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: controller.canForceSubmit
                    ? () => _confirmForceSubmit(
                          context,
                          controller,
                          record,
                        )
                    : null,
                icon: const Icon(Icons.done_all_outlined),
                label: const Text('Force Submit'),
                style: OutlinedButton.styleFrom(foregroundColor: danger),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportingCard extends StatelessWidget {
  const _ReportingCard({required this.record});

  final CandidateActionContext record;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LightPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reporting',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'Open a prefilled report for this candidate.',
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.64),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  Get.toNamed(Routes.incidentReport, arguments: record),
              icon: const Icon(Icons.report_problem_outlined),
              label: const Text('Incident Report'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  Get.toNamed(Routes.malpracticeReport, arguments: record),
              icon: const Icon(Icons.gpp_bad_outlined),
              label: const Text('Malpractice Report'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFB91C1C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _contextPill(IconData icon, String value) {
  final text = value.trim().isEmpty ? '-' : value;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: const Color(0xFFF4F6F8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _stateChip(CandidateExamControlState state) {
  switch (state) {
    case CandidateExamControlState.normal:
      return const KsStatusChip(
        label: 'Active',
        tone: KsStatusChipTone.success,
      );
    case CandidateExamControlState.paused:
      return const KsStatusChip(
        label: 'Paused',
        tone: KsStatusChipTone.warning,
      );
    case CandidateExamControlState.resumed:
      return const KsStatusChip(
        label: 'Resumed',
        tone: KsStatusChipTone.success,
      );
    case CandidateExamControlState.forceSubmitted:
      return const KsStatusChip(
        label: 'Submitted',
        tone: KsStatusChipTone.accent,
      );
    case CandidateExamControlState.lateEntryAllowed:
      return const KsStatusChip(
        label: 'Late Entry',
        tone: KsStatusChipTone.info,
      );
    case CandidateExamControlState.seatReassigned:
      return const KsStatusChip(
        label: 'Seat Moved',
        tone: KsStatusChipTone.warningSoft,
      );
  }
}

Future<void> _confirmReassignment(
  BuildContext context,
  CandidateActionPanelController controller,
) async {
  final current = controller.contextRecord.value;
  final destination = controller.selectedDestinationRecord;
  final reason = controller.selectedReassignmentReason.value;
  if (current == null || destination == null || reason == null) return;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => Theme(
      data: abuDemoTheme(),
      child: AlertDialog(
      title: const Text('Confirm Seat Reassignment'),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              current.candidateName,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 3),
            Text(current.registrationNumber),
            const SizedBox(height: 14),
            _dialogLine('Current seat', current.seatNumber),
            _dialogLine('New seat', destination.seatNumber),
            _dialogLine('New workstation', destination.workstationId),
            _dialogLine('Reason', reason.label),
            _dialogLine('Exam state', 'Preserve and continue'),
            const SizedBox(height: 8),
            Text(
              reason.marksOldSeatAsTechnicalIssue
                  ? 'The old workstation will remain flagged for technical follow-up.'
                  : 'The old workstation will return to the available-seat pool.',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Confirm Move'),
        ),
      ],
      ),
    ),
  );

  if (confirmed == true) {
    await controller.reassignSeat();
  }
}

Future<void> _confirmForceSubmit(
  BuildContext context,
  CandidateActionPanelController controller,
  CandidateActionContext record,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => Theme(
      data: abuDemoTheme(),
      child: AlertDialog(
      title: const Text('Force Submit Candidate Exam?'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              record.candidateName,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text('${record.registrationNumber} • Seat ${record.seatNumber}'),
            const SizedBox(height: 14),
            const Text(
              'This is a final candidate-level action. The exam will be marked submitted and cannot be resumed from this panel.',
              style: TextStyle(fontWeight: FontWeight.w600, height: 1.4),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFB91C1C),
          ),
          child: const Text('Force Submit'),
        ),
      ],
      ),
    ),
  );

  if (confirmed == true) {
    await controller.forceSubmit();
  }
}

Widget _dialogLine(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
