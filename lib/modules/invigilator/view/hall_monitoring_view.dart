import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/ks_status_chip.dart';
import '../../../data/models/hall_monitor_models.dart';
import '../controller/hall_monitoring_controller.dart';
import '../widgets/invigilator_light_panel.dart';
import '../widgets/invigilator_light_scaffold.dart';
import '../widgets/invigilator_top_actions.dart';

class HallMonitoringView extends GetView<HallMonitoringController> {
  const HallMonitoringView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InvigilatorLightScaffold(
      title: 'Hall Live Monitoring',
      actions: buildInvigilatorTopActions(showLiveHall: false, showSeatMap: true),
      body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: [
            _SummaryRow(controller: controller),
            const SizedBox(height: 16),
            LightPanel(
              child: Column(
                children: [
                  TextField(
                    controller: controller.searchController,
                    onChanged: controller.updateSearch,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Search seat, candidate, reg no, exam',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => DropdownButtonFormField<String>(
                      initialValue: controller.selectedHall.value,
                      dropdownColor: cs.surfaceContainerHighest.withValues(
                        alpha: 0.96,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      items: controller.hallOptions
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) controller.updateHall(v);
                      },
                      decoration: const InputDecoration(
                        labelText: 'Hall',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Obx(() {
              final items = controller.filteredRecords;

              if (items.isEmpty) {
                return LightPanel(
                  child: Text(
                    'No live records match your filter.',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }

              return Column(
                children: items
                    .map(
                      (record) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _LiveMonitorCard(
                          record: record,
                          controller: controller,
                        ),
                      ),
                    )
                    .toList(),
              );
            }),
            ],
          );
        }),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.controller});

  final HallMonitoringController controller;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        LightStatCard(
          title: 'Ready',
          value: '${controller.readyCount}',
          icon: Icons.check_circle_outline,
        ),
        LightStatCard(
          title: 'In Exam',
          value: '${controller.inExamCount}',
          icon: Icons.task_alt_outlined,
        ),
        LightStatCard(
          title: 'Submitted',
          value: '${controller.submittedCount}',
          icon: Icons.done_all_outlined,
        ),
        LightStatCard(
          title: 'Issues',
          value: '${controller.issueCount}',
          icon: Icons.report_problem_outlined,
        ),
        LightStatCard(
          title: 'Malpractice',
          value: '${controller.malpracticeCount}',
          icon: Icons.gpp_bad_outlined,
        ),
      ],
    );
  }
}

class _LiveMonitorCard extends StatelessWidget {
  const _LiveMonitorCard({required this.record, required this.controller});

  final HallMonitorRecord record;
  final HallMonitoringController controller;

  @override
  Widget build(BuildContext context) {
    return LightPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${record.hallName} • Seat ${record.seatNumber}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _stateChip(record.state),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            record.candidateName.isEmpty
                ? 'No candidate'
                : record.candidateName,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            record.registrationNumber.isEmpty ? '-' : record.registrationNumber,
          ),
          const SizedBox(height: 4),
          Text(
            record.examTitle.isEmpty ? 'No exam assigned' : record.examTitle,
          ),
          const SizedBox(height: 4),
          Text('Workstation: ${record.workstationId}'),
          Text('Last Seen: ${record.lastSeenLabel}'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => controller.markIssue(record),
                icon: const Icon(Icons.report_problem_outlined),
                label: const Text('Flag Issue'),
              ),
              FilledButton.tonalIcon(
                onPressed: () =>
                    Get.toNamed(Routes.incidentReport, arguments: record),
                icon: const Icon(Icons.description_outlined),
                label: const Text('Incident Report'),
              ),
              FilledButton.icon(
                onPressed: () => controller.markMalpractice(record),
                icon: const Icon(Icons.gpp_bad_outlined),
                label: const Text('Flag Malpractice'),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    Get.toNamed(Routes.malpracticeReport, arguments: record),
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Malpractice Report'),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    Get.toNamed(Routes.candidateActionPanel, arguments: record),
                icon: const Icon(Icons.tune_outlined),
                label: const Text('Action Panel'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => controller.markOffline(record),
                child: const Text('Mark Offline'),
              ),
              OutlinedButton(
                onPressed: () => controller.markSubmitted(record),
                child: const Text('Mark Submitted'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stateChip(HallCandidateLiveState state) {
    late final String text;
    late final KsStatusChipTone tone;

    switch (state) {
      case HallCandidateLiveState.ready:
        text = 'Ready';
        tone = KsStatusChipTone.info;
        break;
      case HallCandidateLiveState.checkedIn:
        text = 'Checked In';
        tone = KsStatusChipTone.warningSoft;
        break;
      case HallCandidateLiveState.authorized:
        text = 'Authorized';
        tone = KsStatusChipTone.success;
        break;
      case HallCandidateLiveState.inExam:
        text = 'In Exam';
        tone = KsStatusChipTone.success;
        break;
      case HallCandidateLiveState.submitted:
        text = 'Submitted';
        tone = KsStatusChipTone.accent;
        break;
      case HallCandidateLiveState.offline:
        text = 'Offline';
        tone = KsStatusChipTone.danger;
        break;
      case HallCandidateLiveState.issueFlagged:
        text = 'Issue';
        tone = KsStatusChipTone.warningSoft;
        break;
      case HallCandidateLiveState.malpracticeFlagged:
        text = 'Malpractice';
        tone = KsStatusChipTone.danger;
        break;
      case HallCandidateLiveState.absent:
        text = 'Absent';
        tone = KsStatusChipTone.neutral;
        break;
    }

    return KsStatusChip(label: text, tone: tone);
  }
}
