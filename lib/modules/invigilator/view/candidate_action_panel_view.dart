import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/ks_status_chip.dart';
import '../../../data/models/candidate_action_models.dart';
import '../controller/candidate_action_panel_controller.dart';
import '../widgets/invigilator_light_panel.dart';
import '../widgets/invigilator_light_scaffold.dart';
import '../widgets/invigilator_top_actions.dart';

class CandidateActionPanelView extends GetView<CandidateActionPanelController> {
  const CandidateActionPanelView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InvigilatorLightScaffold(
      title: 'Candidate Action Panel',
      actions: buildInvigilatorTopActions(showSeatMap: true),
      maxContentWidth: 1280,
      body: Obx(() {
        final record = controller.contextRecord.value;
        if (record == null) {
          return const Center(child: Text('No candidate action context found.'));
        }

        return ListView(
          children: [
            LightPanel(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: cs.primary.withValues(alpha: 0.12),
                    child: Icon(
                      Icons.person_outline,
                      color: cs.primary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.candidateName.isEmpty
                              ? 'Unknown Candidate'
                              : record.candidateName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          record.registrationNumber.isEmpty
                              ? '-'
                              : record.registrationNumber,
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.72),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _stateChip(record.currentState),
                ],
              ),
            ),
            const SizedBox(height: 16),
            LightPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Exam Context',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  _infoRow('Hall', record.hallName),
                  _infoRow('Seat', record.seatNumber),
                  _infoRow('Workstation', record.workstationId),
                  _infoRow('Exam', record.examTitle),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SeatReassignmentPanel(controller: controller),
            const SizedBox(height: 16),
            LightPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Invigilator Note',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Add context for any intervention. A note is required when the reassignment reason is Other.',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.66),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller.noteController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText:
                          'Example: Candidate reported keyboard failure. Moved to an available workstation and continued the exam.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            LightPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Candidate Controls',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      Obx(
                        () => FilledButton.icon(
                          onPressed: controller.isProcessing.value
                              ? null
                              : controller.pauseExam,
                          icon: const Icon(Icons.pause_circle_outline),
                          label: const Text('Pause Exam'),
                        ),
                      ),
                      Obx(
                        () => FilledButton.tonalIcon(
                          onPressed: controller.isProcessing.value
                              ? null
                              : controller.resumeExam,
                          icon: const Icon(Icons.play_circle_outline),
                          label: const Text('Resume Exam'),
                        ),
                      ),
                      Obx(
                        () => OutlinedButton.icon(
                          onPressed: controller.isProcessing.value
                              ? null
                              : controller.allowLateEntry,
                          icon: const Icon(Icons.schedule_outlined),
                          label: const Text('Allow Late Entry'),
                        ),
                      ),
                      Obx(
                        () => OutlinedButton.icon(
                          onPressed: controller.isProcessing.value
                              ? null
                              : controller.forceSubmit,
                          icon: const Icon(Icons.done_all_outlined),
                          label: const Text('Force Submit'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            LightPanel(
              child: Text(
                'Important: Candidate control actions should only be used by authorized invigilators. Seat reassignment preserves the candidate exam context and creates an audit record.',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w700,
                  height: 1.45,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
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

  Widget _stateChip(CandidateExamControlState state) {
    late final String text;
    late final KsStatusChipTone tone;

    switch (state) {
      case CandidateExamControlState.normal:
        text = 'Normal';
        tone = KsStatusChipTone.neutral;
        break;
      case CandidateExamControlState.paused:
        text = 'Paused';
        tone = KsStatusChipTone.warning;
        break;
      case CandidateExamControlState.resumed:
        text = 'Resumed';
        tone = KsStatusChipTone.success;
        break;
      case CandidateExamControlState.forceSubmitted:
        text = 'Force Submitted';
        tone = KsStatusChipTone.accent;
        break;
      case CandidateExamControlState.lateEntryAllowed:
        text = 'Late Entry Allowed';
        tone = KsStatusChipTone.info;
        break;
      case CandidateExamControlState.seatReassigned:
        text = 'Seat Reassigned';
        tone = KsStatusChipTone.warningSoft;
        break;
    }

    return KsStatusChip(label: text, tone: tone);
  }
}

class _SeatReassignmentPanel extends StatelessWidget {
  const _SeatReassignmentPanel({required this.controller});

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
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.event_seat_outlined, color: cs.primary),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seat Reassignment',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Move the candidate only to a verified available workstation in the same hall.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() {
            final current = controller.contextRecord.value;
            final seats = controller.availableDestinationSeats;
            final selected = controller.selectedDestinationSeat.value;

            return DropdownButtonFormField<String>(
              value: selected.isEmpty ? null : selected,
              isExpanded: true,
              items: seats
                  .map(
                    (seat) => DropdownMenuItem<String>(
                      value: seat.seatNumber,
                      child: Text(
                        '${seat.seatNumber}  •  Available  •  ${seat.workstationId}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: controller.isProcessing.value || seats.isEmpty
                  ? null
                  : controller.selectDestinationSeat,
              decoration: InputDecoration(
                labelText: 'Destination seat',
                helperText: seats.isEmpty
                    ? 'No available seats in ${current?.hallName ?? 'this hall'}.'
                    : '${seats.length} verified available seat(s)',
                prefixIcon: const Icon(Icons.chair_alt_outlined),
                border: const OutlineInputBorder(),
              ),
            );
          }),
          const SizedBox(height: 12),
          Obx(() {
            final selected = controller.selectedReassignmentReason.value;
            return DropdownButtonFormField<SeatReassignmentReason>(
              value: selected,
              isExpanded: true,
              items: SeatReassignmentReason.values
                  .map(
                    (reason) => DropdownMenuItem<SeatReassignmentReason>(
                      value: reason,
                      child: Text(reason.label),
                    ),
                  )
                  .toList(),
              onChanged: controller.isProcessing.value
                  ? null
                  : controller.selectReassignmentReason,
              decoration: const InputDecoration(
                labelText: 'Reason for reassignment',
                prefixIcon: Icon(Icons.assignment_outlined),
                border: OutlineInputBorder(),
              ),
            );
          }),
          const SizedBox(height: 12),
          Obx(() {
            final destination = controller.selectedDestinationRecord;
            final reason = controller.selectedReassignmentReason.value;
            if (destination == null && reason == null) {
              return const SizedBox.shrink();
            }

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.primary.withValues(alpha: 0.14)),
              ),
              child: Wrap(
                spacing: 20,
                runSpacing: 8,
                children: [
                  if (destination != null)
                    Text(
                      'New workstation: ${destination.workstationId}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  if (reason != null)
                    Text(
                      reason.marksOldSeatAsTechnicalIssue
                          ? 'Old seat will be marked Technical Issue'
                          : 'Old seat will become Available',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  const Text(
                    'Exam context: Preserved',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 14),
          Obx(
            () => FilledButton.icon(
              onPressed: controller.canReassignSeat
                  ? () => _confirmReassignment(context)
                  : null,
              icon: controller.isProcessing.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.swap_horiz_outlined),
              label: const Text('Review & Reassign Seat'),
            ),
          ),
          Obx(() {
            final event = controller.lastSeatReassignment.value;
            if (event == null) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFDFF7E8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF75D89A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Latest Seat Transfer',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${event.oldSeatNumber} → ${event.newSeatNumber}  •  ${event.reason.label}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Audit ID: ${event.id}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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

  Future<void> _confirmReassignment(BuildContext context) async {
    final current = controller.contextRecord.value;
    final destination = controller.selectedDestinationRecord;
    final reason = controller.selectedReassignmentReason.value;
    if (current == null || destination == null || reason == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Seat Reassignment'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                current.candidateName,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(current.registrationNumber),
              const SizedBox(height: 16),
              _confirmLine('Current seat', current.seatNumber),
              _confirmLine('New seat', destination.seatNumber),
              _confirmLine('New workstation', destination.workstationId),
              _confirmLine('Reason', reason.label),
              _confirmLine('Exam state', 'Preserve and continue'),
              const SizedBox(height: 12),
              Text(
                reason.marksOldSeatAsTechnicalIssue
                    ? 'The old workstation will remain flagged as a technical issue for follow-up.'
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
    );

    if (confirmed == true) {
      await controller.reassignSeat();
    }
  }

  Widget _confirmLine(String label, String value) {
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
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
