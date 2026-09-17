import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/ks_status_chip.dart';
import '../../../data/models/malpractice_models.dart';
import '../controller/malpractice_report_controller.dart';
import '../widgets/invigilator_light_panel.dart';
import '../widgets/invigilator_light_scaffold.dart';
import '../widgets/invigilator_top_actions.dart';

class MalpracticeReportView extends GetView<MalpracticeReportController> {
  const MalpracticeReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return InvigilatorLightScaffold(
      title: 'Malpractice Report',
      actions: buildInvigilatorTopActions(showSeatMap: true),
      maxContentWidth: 1240,
      body: ListView(
        children: [
          _ReportHeader(controller: controller),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 920;
              final form = _MalpracticeForm(controller: controller);
              final contextPanel = _ContextPanel(controller: controller);

              if (!wide) {
                return Column(
                  children: [
                    contextPanel,
                    const SizedBox(height: 14),
                    form,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 7, child: form),
                  const SizedBox(width: 14),
                  Expanded(flex: 3, child: contextPanel),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          _SubmitBar(controller: controller),
        ],
      ),
    );
  }
}

class _ReportHeader extends StatelessWidget {
  const _ReportHeader({required this.controller});
  final MalpracticeReportController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LightPanel(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFFB91C1C).withValues(alpha: 0.09),
            ),
            child: const Icon(
              Icons.gpp_bad_outlined,
              color: Color(0xFFB91C1C),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Record suspected examination malpractice',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  'Document the observation objectively. Detection evidence can support a report, but does not replace invigilator review.',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.66),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Obx(
            () => controller.isHighPriority
                ? const KsStatusChip(
                    label: 'High Priority',
                    tone: KsStatusChipTone.danger,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _MalpracticeForm extends StatelessWidget {
  const _MalpracticeForm({required this.controller});
  final MalpracticeReportController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LightPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Report details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose the closest classification, then record what was observed and the immediate action taken.',
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.66),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          const Text('Type', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Obx(
            () => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MalpracticeType.values.map((type) {
                return ChoiceChip(
                  label: Text(_typeLabel(type)),
                  selected: controller.selectedType.value == type,
                  onSelected: (_) => controller.setType(type),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 18),
          const Text('Severity', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Obx(
            () => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MalpracticeSeverity.values.map((severity) {
                return ChoiceChip(
                  label: Text(_severityLabel(severity)),
                  selected: controller.selectedSeverity.value == severity,
                  onSelected: (_) => controller.setSeverity(severity),
                );
              }).toList(),
            ),
          ),
          Obx(() {
            if (!controller.hasSupportingEvidence) {
              return const SizedBox.shrink();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.sensors_outlined, color: cs.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              controller.sourceEvidenceLabel.value,
                              style: const TextStyle(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Supporting detection available. Confirm the event independently before submission.',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 20),
          TextField(
            controller: controller.descriptionController,
            minLines: 4,
            maxLines: 7,
            decoration: const InputDecoration(
              labelText: 'What did you observe? *',
              hintText: 'Describe the observed conduct clearly and objectively.',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller.actionTakenController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Action taken *',
              hintText: 'Example: warned candidate, paused exam, secured device, informed chief invigilator.',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller.evidenceController,
            minLines: 2,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Evidence / reference (optional)',
              hintText: 'Detection event, CCTV time, witness, device reference, or other supporting record.',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextPanel extends StatelessWidget {
  const _ContextPanel({required this.controller});
  final MalpracticeReportController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Obx(
      () => LightPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.badge_outlined, color: cs.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Candidate context',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _detail('Candidate', controller.candidateName.value),
            _detail('Registration', controller.registrationNumber.value),
            _detail('Hall / Seat', _hallSeat(controller)),
            _detail('Workstation', controller.workstationId.value),
            _detail('Exam', controller.examTitle.value),
            const Divider(height: 26),
            const Text(
              'Important',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'Use factual, professional language. Avoid conclusions about intent that were not directly observed. The report may be reviewed during disciplinary proceedings.',
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.68),
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _hallSeat(MalpracticeReportController controller) {
    final hall = controller.hallName.value.trim();
    final seat = controller.seatNumber.value.trim();
    if (hall.isEmpty && seat.isEmpty) return '-';
    if (hall.isEmpty) return seat;
    if (seat.isEmpty) return hall;
    return '$hall • $seat';
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            value.trim().isEmpty ? '-' : value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({required this.controller});
  final MalpracticeReportController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Obx(
      () => LightPanel(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Observation and action taken are required. Submission creates an auditable malpractice record for review.',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.68),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 14),
            FilledButton.icon(
              onPressed: controller.isSubmitting.value ? null : controller.submit,
              icon: const Icon(Icons.gpp_good_outlined),
              label: Text(
                controller.isSubmitting.value ? 'Submitting...' : 'Submit Report',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _typeLabel(MalpracticeType type) {
  switch (type) {
    case MalpracticeType.impersonation:
      return 'Impersonation';
    case MalpracticeType.phoneUse:
      return 'Phone Use';
    case MalpracticeType.talking:
      return 'Talking';
    case MalpracticeType.unauthorizedMaterial:
      return 'Unauthorized Material';
    case MalpracticeType.switchingSeat:
      return 'Seat Switching';
    case MalpracticeType.multipleLoginAttempt:
      return 'Multiple Login';
    case MalpracticeType.externalAssistance:
      return 'External Assistance';
    case MalpracticeType.suspiciousBehavior:
      return 'Suspicious Behaviour';
    case MalpracticeType.refusalToComply:
      return 'Refusal to Comply';
    case MalpracticeType.other:
      return 'Other';
  }
}

String _severityLabel(MalpracticeSeverity severity) {
  switch (severity) {
    case MalpracticeSeverity.moderate:
      return 'Moderate';
    case MalpracticeSeverity.major:
      return 'Major';
    case MalpracticeSeverity.severe:
      return 'Severe';
    case MalpracticeSeverity.critical:
      return 'Critical';
  }
}
