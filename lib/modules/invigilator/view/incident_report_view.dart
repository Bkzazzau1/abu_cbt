import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/ks_status_chip.dart';
import '../../../data/models/incident_models.dart';
import '../controller/incident_report_controller.dart';
import '../widgets/invigilator_light_panel.dart';
import '../widgets/invigilator_light_scaffold.dart';
import '../widgets/invigilator_top_actions.dart';

class IncidentReportView extends GetView<IncidentReportController> {
  const IncidentReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return InvigilatorLightScaffold(
      title: 'Incident Report',
      actions: buildInvigilatorTopActions(showSeatMap: true),
      maxContentWidth: 1240,
      body: ListView(
        children: [
          _ReportHeader(controller: controller),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 920;
              final form = _IncidentForm(controller: controller);
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
  final IncidentReportController controller;

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
              color: cs.primary.withValues(alpha: 0.10),
            ),
            child: Icon(Icons.report_problem_outlined, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Record an operational incident',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  'Use this for seat, attendance, identity, technical, power, network, or conduct events that need an audit record.',
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
                    label: 'Priority Incident',
                    tone: KsStatusChipTone.warning,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _IncidentForm extends StatelessWidget {
  const _IncidentForm({required this.controller});
  final IncidentReportController controller;

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
            'Select the closest category and severity, then record only what was observed and what was done.',
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.66),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          const Text('Category', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Obx(
            () => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: IncidentType.values.map((type) {
                return ChoiceChip(
                  label: Text(_incidentTypeLabel(type)),
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
              children: IncidentSeverity.values.map((severity) {
                return ChoiceChip(
                  label: Text(_severityLabel(severity)),
                  selected: controller.selectedSeverity.value == severity,
                  onSelected: (_) => controller.setSeverity(severity),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: controller.descriptionController,
            minLines: 4,
            maxLines: 7,
            decoration: const InputDecoration(
              labelText: 'What happened? *',
              hintText: 'State the event clearly and factually.',
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
              hintText: 'What did the invigilator or support team do?',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller.evidenceController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Evidence / reference (optional)',
              hintText: 'Example: CCTV timestamp, technical report ID, witness, photo reference.',
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
  final IncidentReportController controller;

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
                Icon(Icons.person_pin_outlined, color: cs.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Candidate context',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
                if (!controller.hasCandidateContext)
                  const KsStatusChip(
                    label: 'General',
                    tone: KsStatusChipTone.neutral,
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
              'Reporting rule',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'Record facts, not assumptions. Malpractice allegations should be filed using the dedicated Malpractice Report.',
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

  String _hallSeat(IncidentReportController controller) {
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
  final IncidentReportController controller;

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
                'Submitting creates an auditable incident record. Description and action taken are required.',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.68),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 14),
            FilledButton.icon(
              onPressed: controller.isSubmitting.value ? null : controller.submit,
              icon: const Icon(Icons.check_circle_outline),
              label: Text(
                controller.isSubmitting.value ? 'Saving...' : 'Record Incident',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _incidentTypeLabel(IncidentType type) {
  switch (type) {
    case IncidentType.wrongSeat:
      return 'Wrong Seat';
    case IncidentType.technicalIssue:
      return 'Technical';
    case IncidentType.lateArrival:
      return 'Late Arrival';
    case IncidentType.misconduct:
      return 'Conduct';
    case IncidentType.powerFailure:
      return 'Power';
    case IncidentType.networkProblem:
      return 'Network';
    case IncidentType.identityMismatch:
      return 'Identity';
    case IncidentType.deviceIssue:
      return 'Device';
    case IncidentType.other:
      return 'Other';
  }
}

String _severityLabel(IncidentSeverity severity) {
  switch (severity) {
    case IncidentSeverity.low:
      return 'Low';
    case IncidentSeverity.medium:
      return 'Medium';
    case IncidentSeverity.high:
      return 'High';
    case IncidentSeverity.critical:
      return 'Critical';
  }
}
