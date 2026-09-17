import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/ks_status_chip.dart';
import '../../../data/models/checkin_models.dart';
import '../controller/candidate_checkin_controller.dart';
import '../widgets/invigilator_light_panel.dart';
import '../widgets/invigilator_light_scaffold.dart';
import '../widgets/invigilator_top_actions.dart';

class CandidateCheckInView extends GetView<CandidateCheckInController> {
  const CandidateCheckInView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InvigilatorLightScaffold(
      title: 'Candidate Check-In',
      actions: buildInvigilatorTopActions(showSeatMap: true),
      maxContentWidth: 1280,
      body: Obx(() {
          final record = controller.record.value;
          if (record == null) {
            return const Center(
              child: Text('No candidate/workstation record found.'),
            );
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
                              ? 'Candidate not yet identified'
                              : record.candidateName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          record.registrationNumber.isEmpty
                              ? 'Registration number not available'
                              : record.registrationNumber,
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.72),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _statusChip(record.status),
                ],
              ),
            ),
            const SizedBox(height: 16),
            LightPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Seat & Device Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  _infoRow('Hall', record.hallName),
                  _infoRow('Seat', record.seatNumber),
                  _infoRow('Workstation ID', record.workstationId),
                ],
              ),
            ),
            const SizedBox(height: 16),
            LightPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Assigned Exam',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    record.examTitle.isEmpty
                        ? 'No exam assigned yet.'
                        : record.examTitle,
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use this section to confirm that the candidate is seated '
                    'correctly and is taking the correct exam.',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w600,
                      height: 1.45,
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
                    'Invigilator Notes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller.notesController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText:
                          'Add note: identity mismatch, wrong seat, technical '
                          'issue, late arrival...',
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
                    'Check-In Actions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: controller.markCheckedIn,
                        icon: const Icon(Icons.how_to_reg_outlined),
                        label: const Text('Mark Checked In'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: controller.authorize,
                        icon: const Icon(Icons.verified_user_outlined),
                        label: const Text('Authorize'),
                      ),
                      OutlinedButton.icon(
                        onPressed: controller.flagIssue,
                        icon: const Icon(Icons.report_problem_outlined),
                        label: const Text('Flag Issue'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => Get.toNamed(
                          Routes.incidentReport,
                          arguments: controller.record.value,
                        ),
                        icon: const Icon(Icons.report_problem_outlined),
                        label: const Text('Report Incident'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => Get.toNamed(
                          Routes.candidateActionPanel,
                          arguments: controller.record.value,
                        ),
                        icon: const Icon(Icons.tune_outlined),
                        label: const Text('Action Panel'),
                      ),
                      OutlinedButton.icon(
                        onPressed: controller.markAbsent,
                        icon: const Icon(Icons.person_off_outlined),
                        label: const Text('Mark Absent'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            LightPanel(
              child: Text(
                'Tip: Candidate should only proceed when seat, identity, '
                'workstation and exam allocation are all correct.',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w700,
                  height: 1.5,
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
            width: 120,
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

  Widget _statusChip(CandidateCheckInStatus status) {
    late final String text;
    late final KsStatusChipTone tone;

    switch (status) {
      case CandidateCheckInStatus.pending:
        text = 'Pending';
        tone = KsStatusChipTone.warning;
        break;
      case CandidateCheckInStatus.checkedIn:
        text = 'Checked In';
        tone = KsStatusChipTone.info;
        break;
      case CandidateCheckInStatus.authorized:
        text = 'Authorized';
        tone = KsStatusChipTone.success;
        break;
      case CandidateCheckInStatus.absent:
        text = 'Absent';
        tone = KsStatusChipTone.danger;
        break;
      case CandidateCheckInStatus.issueFlagged:
        text = 'Issue Flagged';
        tone = KsStatusChipTone.warningSoft;
        break;
    }

    return KsStatusChip(label: text, tone: tone);
  }
}
