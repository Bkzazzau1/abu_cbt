import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/ks_page_shell.dart';
import '../../../core/widgets/ks_status_chip.dart';
import '../../../data/models/malpractice_models.dart';
import '../controller/malpractice_report_controller.dart';
import '../widgets/invigilator_top_actions.dart';

class MalpracticeReportView extends GetView<MalpracticeReportController> {
  const MalpracticeReportView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Malpractice Report'),
        backgroundColor: Colors.transparent,
        actions: buildInvigilatorTopActions(showSeatMap: true),
      ),
      extendBodyBehindAppBar: true,
      body: KsPageShell(
        padding: const EdgeInsets.fromLTRB(20, 92, 20, 20),
        maxContentWidth: 1180,
        child: Obx(
          () => ListView(
            children: [
              GlassCard(
                tone: GlassCardTone.danger,
                showGlow: true,
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const KsStatusChip(
                      label: 'Incident Reporting',
                      tone: KsStatusChipTone.danger,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Record an examination malpractice event',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        height: 1.12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Capture factual details, severity, and action taken for review by exam officers and management.',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.76),
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
                  final compact = constraints.maxWidth < 860;

                  final contextCard = GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Candidate / Exam Context',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _InfoLine(
                          label: 'Candidate',
                          value: controller.candidateName.value.isEmpty
                              ? '-'
                              : controller.candidateName.value,
                          strong: true,
                        ),
                        _InfoLine(
                          label: 'Reg No',
                          value: controller.registrationNumber.value.isEmpty
                              ? '-'
                              : controller.registrationNumber.value,
                        ),
                        _InfoLine(
                          label: 'Hall',
                          value: controller.hallName.value.isEmpty
                              ? '-'
                              : controller.hallName.value,
                        ),
                        _InfoLine(
                          label: 'Seat',
                          value: controller.seatNumber.value.isEmpty
                              ? '-'
                              : controller.seatNumber.value,
                        ),
                        _InfoLine(
                          label: 'Workstation',
                          value: controller.workstationId.value.isEmpty
                              ? '-'
                              : controller.workstationId.value,
                        ),
                        _InfoLine(
                          label: 'Exam',
                          value: controller.examTitle.value.isEmpty
                              ? '-'
                              : controller.examTitle.value,
                        ),
                      ],
                    ),
                  );

                  final severityCard = GlassCard(
                    tone: GlassCardTone.warning,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Type & Severity',
                          style: TextStyle(
                            color: cs.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Malpractice Type',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: MalpracticeType.values.map((type) {
                            final selected =
                                controller.selectedType.value == type;
                            return ChoiceChip(
                              label: Text(_typeLabel(type)),
                              selected: selected,
                              onSelected: (_) => controller.setType(type),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Severity',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: MalpracticeSeverity.values.map((severity) {
                            final selected =
                                controller.selectedSeverity.value == severity;
                            return ChoiceChip(
                              label: Text(_severityLabel(severity)),
                              selected: selected,
                              onSelected: (_) =>
                                  controller.setSeverity(severity),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );

                  if (compact) {
                    return Column(
                      children: [
                        contextCard,
                        const SizedBox(height: 16),
                        severityCard,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: contextCard),
                      const SizedBox(width: 16),
                      Expanded(child: severityCard),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'What Happened?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Describe the event clearly and objectively.',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.70),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller.descriptionController,
                      minLines: 6,
                      maxLines: 9,
                      decoration: const InputDecoration(
                        hintText:
                            'Example: Candidate was seen using a mobile phone during the examination after repeated warning from the invigilator.',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Action Taken',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'State the response or disciplinary step taken immediately.',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.70),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller.actionTakenController,
                      minLines: 4,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        hintText:
                            'Example: Candidate was warned, script flagged, examination paused, device seized, and the case reported to the chief invigilator.',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                tone: GlassCardTone.warning,
                padding: const EdgeInsets.all(18),
                child: Text(
                  'Important: Malpractice reports must be factual, clear, professional, and free from emotional language because they may be reviewed for disciplinary decisions.',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: controller.isSubmitting.value
                    ? null
                    : controller.submit,
                icon: const Icon(Icons.gpp_bad_outlined),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                label: Text(
                  controller.isSubmitting.value
                      ? 'Submitting...'
                      : 'Submit Malpractice Report',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        return 'Switching Seat';
      case MalpracticeType.multipleLoginAttempt:
        return 'Multiple Login';
      case MalpracticeType.externalAssistance:
        return 'External Assistance';
      case MalpracticeType.suspiciousBehavior:
        return 'Suspicious Behavior';
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
