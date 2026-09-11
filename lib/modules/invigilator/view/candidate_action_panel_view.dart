import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/ks_page_shell.dart';
import '../../../core/widgets/ks_status_chip.dart';
import '../../../data/models/candidate_action_models.dart';
import '../controller/candidate_action_panel_controller.dart';
import '../widgets/invigilator_top_actions.dart';

class CandidateActionPanelView extends GetView<CandidateActionPanelController> {
  const CandidateActionPanelView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Candidate Action Panel'),
        backgroundColor: Colors.transparent,
        actions: buildInvigilatorTopActions(showSeatMap: true),
      ),
      extendBodyBehindAppBar: true,
      body: KsPageShell(
        padding: const EdgeInsets.fromLTRB(20, 92, 20, 20),
        maxContentWidth: 1280,
        child: Obx(() {
          final record = controller.contextRecord.value;
          if (record == null) {
            return const Center(
              child: Text('No candidate action context found.'),
            );
          }

          return ListView(
            children: [
            GlassCard(
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
            GlassCard(
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
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Invigilator Note',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller.noteController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText:
                          'Write a note for this candidate action. Example: '
                          'Candidate reported system freeze; exam paused and '
                          'resumed after confirmation.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Seat Reassignment',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller.reassignedSeatController,
                    decoration: const InputDecoration(
                      hintText: 'Enter new seat number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => OutlinedButton.icon(
                      onPressed: controller.isProcessing.value
                          ? null
                          : controller.reassignSeat,
                      icon: const Icon(Icons.swap_horiz_outlined),
                      label: const Text('Reassign Seat'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
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
            GlassCard(
              child: Text(
                'Important: Candidate control actions should only be used by '
                'authorized invigilators and should always be accompanied by a '
                'clear note.',
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
      ),
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
