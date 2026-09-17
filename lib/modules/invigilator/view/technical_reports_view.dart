import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/ks_status_chip.dart';
import '../../../data/models/technical_report_models.dart';
import '../controller/technical_reports_controller.dart';
import '../widgets/invigilator_light_panel.dart';
import '../widgets/invigilator_light_scaffold.dart';
import '../widgets/invigilator_top_actions.dart';

class TechnicalReportsView extends GetView<TechnicalReportsController> {
  const TechnicalReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InvigilatorLightScaffold(
      title: 'Technical Support',
      actions: buildInvigilatorTopActions(showTechnical: false, showSeatMap: true),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              LightPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.support_agent_outlined, color: cs.primary),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CBT Technical Operations',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Monitor workstation health and track technical incidents during the examination.',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _Filters(controller: controller),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.monitor_heart_outlined), text: 'System Health'),
                  Tab(icon: Icon(Icons.build_circle_outlined), text: 'Technical Reports'),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  children: [
                    _SystemHealthTab(controller: controller),
                    _TechnicalReportsTab(controller: controller),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.controller});

  final TechnicalReportsController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        final hall = Obx(
          () => DropdownButtonFormField<String>(
            initialValue: controller.selectedHall.value,
            items: controller.hallOptions
                .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                .toList(),
            onChanged: (value) {
              if (value != null) controller.updateHall(value);
            },
            decoration: const InputDecoration(
              labelText: 'Hall',
              prefixIcon: Icon(Icons.meeting_room_outlined),
              border: OutlineInputBorder(),
            ),
          ),
        );

        final status = Obx(
          () => DropdownButtonFormField<String>(
            initialValue: controller.selectedStatus.value,
            items: controller.statusOptions
                .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                .toList(),
            onChanged: (value) {
              if (value != null) controller.updateStatus(value);
            },
            decoration: const InputDecoration(
              labelText: 'Report Status',
              prefixIcon: Icon(Icons.filter_alt_outlined),
              border: OutlineInputBorder(),
            ),
          ),
        );

        if (compact) {
          return Column(
            children: [hall, const SizedBox(height: 10), status],
          );
        }

        return Row(
          children: [
            Expanded(child: hall),
            const SizedBox(width: 12),
            Expanded(child: status),
          ],
        );
      },
    );
  }
}

class _SystemHealthTab extends StatelessWidget {
  const _SystemHealthTab({required this.controller});

  final TechnicalReportsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = controller.filteredHealth;

      return ListView(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              LightStatCard(
                title: 'Workstations',
                value: '${controller.totalWorkstations}',
                icon: Icons.computer_outlined,
                width: 210,
              ),
              LightStatCard(
                title: 'Healthy',
                value: '${controller.healthyCount}',
                icon: Icons.check_circle_outline,
                width: 210,
              ),
              LightStatCard(
                title: 'Degraded',
                value: '${controller.degradedCount}',
                icon: Icons.warning_amber_outlined,
                width: 210,
              ),
              LightStatCard(
                title: 'Offline',
                value: '${controller.offlineCount}',
                icon: Icons.power_off_outlined,
                width: 210,
              ),
              LightStatCard(
                title: 'Critical',
                value: '${controller.criticalCount}',
                icon: Icons.error_outline,
                width: 210,
              ),
            ],
          ),
          const SizedBox(height: 14),
          LightPanel(
            padding: EdgeInsets.zero,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 50,
                dataRowMinHeight: 54,
                dataRowMaxHeight: 68,
                columns: const [
                  DataColumn(label: Text('Seat')),
                  DataColumn(label: Text('Workstation')),
                  DataColumn(label: Text('Health')),
                  DataColumn(label: Text('Network')),
                  DataColumn(label: Text('CBT App')),
                  DataColumn(label: Text('Last Seen')),
                  DataColumn(label: Text('Issue')),
                ],
                rows: items.map((record) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          '${record.hallName} • ${record.seatNumber}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      DataCell(Text(record.workstationId)),
                      DataCell(_healthChip(record.state)),
                      DataCell(Text(record.networkLabel)),
                      DataCell(Text(record.appLabel)),
                      DataCell(Text(record.lastSeenLabel)),
                      DataCell(
                        SizedBox(
                          width: 190,
                          child: Text(
                            record.issueLabel,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _healthChip(WorkstationHealthState state) {
    switch (state) {
      case WorkstationHealthState.healthy:
        return const KsStatusChip(
          label: 'Healthy',
          tone: KsStatusChipTone.success,
        );
      case WorkstationHealthState.degraded:
        return const KsStatusChip(
          label: 'Degraded',
          tone: KsStatusChipTone.warning,
        );
      case WorkstationHealthState.offline:
        return const KsStatusChip(
          label: 'Offline',
          tone: KsStatusChipTone.danger,
        );
      case WorkstationHealthState.critical:
        return const KsStatusChip(
          label: 'Critical',
          tone: KsStatusChipTone.danger,
        );
    }
  }
}

class _TechnicalReportsTab extends StatelessWidget {
  const _TechnicalReportsTab({required this.controller});

  final TechnicalReportsController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Obx(() {
      final reports = controller.filteredReports;

      return ListView(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              LightStatCard(
                title: 'Open',
                value: '${controller.openReportCount}',
                icon: Icons.error_outline,
                width: 220,
              ),
              LightStatCard(
                title: 'In Progress',
                value: '${controller.inProgressReportCount}',
                icon: Icons.build_outlined,
                width: 220,
              ),
              LightStatCard(
                title: 'Resolved',
                value: '${controller.resolvedReportCount}',
                icon: Icons.task_alt_outlined,
                width: 220,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (reports.isEmpty)
            LightPanel(
              child: Text(
                'No technical reports match the selected filters.',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            ...reports.map(
              (report) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TechnicalReportCard(
                  report: report,
                  controller: controller,
                ),
              ),
            ),
        ],
      );
    });
  }
}

class _TechnicalReportCard extends StatelessWidget {
  const _TechnicalReportCard({required this.report, required this.controller});

  final TechnicalReportRecord report;
  final TechnicalReportsController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return LightPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${report.hallName} • Seat ${report.seatNumber}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.workstationId,
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _severityChip(report.severity),
                  _statusChip(report.status),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              _Info(label: 'Category', value: report.category.label),
              _Info(label: 'Reported', value: _timeLabel(report.createdAt)),
              if (report.candidateName.isNotEmpty)
                _Info(label: 'Candidate', value: report.candidateName),
              if (report.registrationNumber.isNotEmpty)
                _Info(label: 'Reg No', value: report.registrationNumber),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            report.description,
            style: const TextStyle(fontWeight: FontWeight.w700, height: 1.4),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Action: ${report.actionTaken}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          if (report.sourceSeatReassignmentId != null) ...[
            const SizedBox(height: 10),
            KsStatusChip(
              label: 'Linked Seat Move • ${report.sourceSeatReassignmentId}',
              tone: KsStatusChipTone.info,
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (report.status == TechnicalIssueStatus.open)
                FilledButton.tonalIcon(
                  onPressed: () => controller.markInProgress(report),
                  icon: const Icon(Icons.build_outlined),
                  label: const Text('Start Work'),
                ),
              if (report.status != TechnicalIssueStatus.resolved)
                FilledButton.icon(
                  onPressed: () => controller.resolve(report),
                  icon: const Icon(Icons.task_alt_outlined),
                  label: const Text('Mark Resolved'),
                ),
              if (report.status == TechnicalIssueStatus.resolved)
                OutlinedButton.icon(
                  onPressed: () => controller.reopen(report),
                  icon: const Icon(Icons.restart_alt_outlined),
                  label: const Text('Reopen'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _severityChip(TechnicalIssueSeverity severity) {
    final tone = switch (severity) {
      TechnicalIssueSeverity.low => KsStatusChipTone.info,
      TechnicalIssueSeverity.medium => KsStatusChipTone.warningSoft,
      TechnicalIssueSeverity.high => KsStatusChipTone.warning,
      TechnicalIssueSeverity.critical => KsStatusChipTone.danger,
    };
    return KsStatusChip(label: severity.label, tone: tone);
  }

  Widget _statusChip(TechnicalIssueStatus status) {
    final tone = switch (status) {
      TechnicalIssueStatus.open => KsStatusChipTone.danger,
      TechnicalIssueStatus.inProgress => KsStatusChipTone.warning,
      TechnicalIssueStatus.resolved => KsStatusChipTone.success,
    };
    return KsStatusChip(label: status.label, tone: tone);
  }

  String _timeLabel(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.60),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
