import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/incident_models.dart';
import '../controller/incident_report_controller.dart';
import '../widgets/invigilator_light_panel.dart';
import '../widgets/invigilator_light_scaffold.dart';
import '../widgets/invigilator_top_actions.dart';

class IncidentReportView extends GetView<IncidentReportController> {
  const IncidentReportView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InvigilatorLightScaffold(
      title: 'Incident Reporting',
      actions: buildInvigilatorTopActions(showSeatMap: true),
      maxContentWidth: 1180,
      body: Obx(
          () => ListView(
            children: [
            LightPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Candidate / Workstation Context',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  _infoRow(
                    'Candidate',
                    controller.candidateName.value.isEmpty
                        ? '-'
                        : controller.candidateName.value,
                  ),
                  _infoRow(
                    'Reg No',
                    controller.registrationNumber.value.isEmpty
                        ? '-'
                        : controller.registrationNumber.value,
                  ),
                  _infoRow(
                    'Hall',
                    controller.hallName.value.isEmpty
                        ? '-'
                        : controller.hallName.value,
                  ),
                  _infoRow(
                    'Seat',
                    controller.seatNumber.value.isEmpty
                        ? '-'
                        : controller.seatNumber.value,
                  ),
                  _infoRow(
                    'Workstation',
                    controller.workstationId.value.isEmpty
                        ? '-'
                        : controller.workstationId.value,
                  ),
                  _infoRow(
                    'Exam',
                    controller.examTitle.value.isEmpty
                        ? '-'
                        : controller.examTitle.value,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            LightPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Incident Type',
                    style: TextStyle(
                      color: cs.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: IncidentType.values.map((type) {
                      final selected = controller.selectedType.value == type;
                      return ChoiceChip(
                        label: Text(_incidentTypeLabel(type)),
                        selected: selected,
                        onSelected: (_) => controller.setType(type),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            LightPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Severity',
                    style: TextStyle(
                      color: cs.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: IncidentSeverity.values.map((severity) {
                      final selected =
                          controller.selectedSeverity.value == severity;
                      return ChoiceChip(
                        label: Text(_severityLabel(severity)),
                        selected: selected,
                        onSelected: (_) => controller.setSeverity(severity),
                      );
                    }).toList(),
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
                    'Incident Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller.descriptionController,
                    minLines: 5,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      hintText:
                          'Describe what happened. Example: Candidate seated '
                          'at wrong workstation. Invigilator redirected candidate '
                          'to Hall A Seat A-04. Exam not yet started.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            LightPanel(
              child: Text(
                'Tip: Include enough detail for later review by exam officers, '
                'support team, or management.',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w700,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: controller.isSubmitting.value
                  ? null
                  : controller.submit,
              icon: const Icon(Icons.report_gmailerrorred_outlined),
              label: Text(
                controller.isSubmitting.value
                    ? 'Submitting...'
                    : 'Submit Incident Report',
              ),
            ),
            ],
          ),
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
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _incidentTypeLabel(IncidentType type) {
    switch (type) {
      case IncidentType.wrongSeat:
        return 'Wrong Seat';
      case IncidentType.technicalIssue:
        return 'Technical Issue';
      case IncidentType.lateArrival:
        return 'Late Arrival';
      case IncidentType.misconduct:
        return 'Misconduct';
      case IncidentType.powerFailure:
        return 'Power Failure';
      case IncidentType.networkProblem:
        return 'Network Problem';
      case IncidentType.identityMismatch:
        return 'Identity Mismatch';
      case IncidentType.deviceIssue:
        return 'Device Issue';
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
}
