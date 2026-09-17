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
      title: 'Live Hall',
      actions: buildInvigilatorTopActions(showLiveHall: false, showSeatMap: true),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final wide = MediaQuery.sizeOf(context).width >= 1120;
        final items = controller.filteredRecords;

        return Column(
          children: [
            _LiveHallHeader(controller: controller),
            const SizedBox(height: 14),
            _Filters(controller: controller),
            const SizedBox(height: 14),
            Expanded(
              child: items.isEmpty
                  ? LightPanel(
                      child: Center(
                        child: Text(
                          'No live records match the current filters.',
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.68),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                  : wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _LiveHallTable(
                                records: items,
                                controller: controller,
                              ),
                            ),
                            const SizedBox(width: 14),
                            SizedBox(
                              width: 350,
                              child: Obx(
                                () => _CandidateDetailPanel(
                                  record: controller.selectedRecord.value,
                                  controller: controller,
                                ),
                              ),
                            ),
                          ],
                        )
                      : _CompactHallList(
                          records: items,
                          controller: controller,
                        ),
            ),
          ],
        );
      }),
    );
  }
}

class _LiveHallHeader extends StatelessWidget {
  const _LiveHallHeader({required this.controller});

  final HallMonitoringController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final attention =
        controller.issueCount + controller.malpracticeCount + controller.offlineCount;

    return LightPanel(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hall Operations',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                controller.selectedHall.value == 'All Halls'
                    ? 'Live candidate and workstation status across all examination halls.'
                    : 'Live candidate and workstation status for ${controller.selectedHall.value}.',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.68),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

          final stats = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniStat(label: 'In Exam', value: controller.inExamCount),
              _MiniStat(label: 'Ready', value: controller.readyCount),
              _MiniStat(label: 'Attention', value: attention, warning: attention > 0),
              _MiniStat(label: 'Submitted', value: controller.submittedCount),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, const SizedBox(height: 14), stats],
            );
          }

          return Row(
            children: [
              Expanded(child: title),
              const SizedBox(width: 18),
              stats,
            ],
          );
        },
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, this.warning = false});

  final String label;
  final int value;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = warning ? cs.error : cs.primary;

    return Container(
      width: 105,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withValues(alpha: 0.68),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.controller});

  final HallMonitoringController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return LightPanel(
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 820;

          final search = TextField(
            controller: controller.searchController,
            onChanged: controller.updateSearch,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search, size: 20),
              hintText: 'Search seat, candidate, reg no or workstation',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          );

          final hall = Obx(
            () => DropdownButtonFormField<String>(
              initialValue: controller.selectedHall.value,
              dropdownColor: cs.surfaceContainerHighest,
              isExpanded: true,
              items: controller.hallOptions
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                if (value != null) controller.updateHall(value);
              },
              decoration: const InputDecoration(
                labelText: 'Hall',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          );

          final state = Obx(
            () => DropdownButtonFormField<String>(
              initialValue: controller.selectedState.value,
              dropdownColor: cs.surfaceContainerHighest,
              isExpanded: true,
              items: controller.stateOptions
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                if (value != null) controller.updateState(value);
              },
              decoration: const InputDecoration(
                labelText: 'Status',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          );

          if (compact) {
            return Column(
              children: [
                search,
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: hall),
                    const SizedBox(width: 10),
                    Expanded(child: state),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 3, child: search),
              const SizedBox(width: 10),
              Expanded(child: hall),
              const SizedBox(width: 10),
              Expanded(child: state),
              const SizedBox(width: 10),
              Obx(
                () => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Text(
                    '${controller.filteredRecords.length} visible',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LiveHallTable extends StatelessWidget {
  const _LiveHallTable({required this.records, required this.controller});

  final List<HallMonitorRecord> records;
  final HallMonitoringController controller;

  @override
  Widget build(BuildContext context) {
    return LightPanel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          const _TableHeader(),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: records.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final record = records[index];
                return Obx(
                  () => _TableRow(
                    record: record,
                    selected: controller.selectedRecord.value?.workstationId ==
                        record.workstationId,
                    onTap: () => controller.selectRecord(record),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final style = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      color: cs.onSurface.withValues(alpha: 0.58),
      letterSpacing: 0.35,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          SizedBox(width: 74, child: Text('SEAT', style: style)),
          Expanded(flex: 3, child: Text('CANDIDATE', style: style)),
          SizedBox(width: 112, child: Text('STATUS', style: style)),
          SizedBox(width: 94, child: Text('NETWORK', style: style)),
          SizedBox(width: 92, child: Text('RISK', style: style)),
          SizedBox(width: 90, child: Text('LAST SEEN', style: style)),
          const SizedBox(width: 34),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.record,
    required this.selected,
    required this.onTap,
  });

  final HallMonitorRecord record;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: selected ? cs.primary.withValues(alpha: 0.055) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              SizedBox(
                width: 74,
                child: Text(
                  record.seatNumber,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.candidateName.isEmpty ? 'Available workstation' : record.candidateName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      record.registrationNumber.isEmpty
                          ? record.workstationId
                          : record.registrationNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.58),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 112, child: _stateChip(record.state)),
              SizedBox(width: 94, child: _NetworkLabel(record: record)),
              SizedBox(width: 92, child: _RiskLabel(record: record)),
              SizedBox(
                width: 90,
                child: Text(
                  record.lastSeenLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.64),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactHallList extends StatelessWidget {
  const _CompactHallList({required this.records, required this.controller});

  final List<HallMonitorRecord> records;
  final HallMonitoringController controller;

  @override
  Widget build(BuildContext context) {
    return LightPanel(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        itemCount: records.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final record = records[index];
          return ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            onTap: () => _showCandidateSheet(context, record, controller),
            leading: SizedBox(
              width: 48,
              child: Text(
                record.seatNumber,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            title: Text(
              record.candidateName.isEmpty ? 'Available workstation' : record.candidateName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              record.registrationNumber.isEmpty
                  ? record.workstationId
                  : '${record.registrationNumber} • ${record.lastSeenLabel}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: _stateChip(record.state),
          );
        },
      ),
    );
  }
}

class _CandidateDetailPanel extends StatelessWidget {
  const _CandidateDetailPanel({required this.record, required this.controller});

  final HallMonitorRecord? record;
  final HallMonitoringController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final item = record;

    if (item == null) {
      return LightPanel(
        child: Center(
          child: Text(
            'Select a workstation to inspect it.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.62),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return LightPanel(
      child: ListView(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.hallName} • ${item.seatNumber}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.workstationId,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.58),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _stateChip(item.state),
            ],
          ),
          const SizedBox(height: 18),
          _DetailLine(
            label: 'Candidate',
            value: item.candidateName.isEmpty ? 'No candidate assigned' : item.candidateName,
          ),
          _DetailLine(label: 'Registration', value: item.registrationNumber),
          _DetailLine(label: 'Exam', value: item.examTitle),
          _DetailLine(label: 'Last seen', value: item.lastSeenLabel),
          _DetailLine(label: 'Network', value: _networkText(item)),
          _DetailLine(label: 'Attention', value: _riskText(item)),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          if (item.candidateName.isNotEmpty) ...[
            FilledButton.icon(
              onPressed: () => Get.toNamed(Routes.candidateActionPanel, arguments: item),
              icon: const Icon(Icons.tune_outlined),
              label: const Text('Candidate Actions'),
            ),
            const SizedBox(height: 8),
          ],
          OutlinedButton.icon(
            onPressed: () => Get.toNamed(Routes.incidentReport, arguments: item),
            icon: const Icon(Icons.description_outlined),
            label: const Text('Create Incident Report'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Get.toNamed(Routes.malpracticeReport, arguments: item),
            icon: const Icon(Icons.gpp_bad_outlined),
            label: const Text('Malpractice Report'),
          ),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => controller.markIssue(item),
            icon: const Icon(Icons.report_problem_outlined),
            label: const Text('Flag Technical / Operational Issue'),
          ),
          TextButton.icon(
            onPressed: () => controller.markOffline(item),
            icon: const Icon(Icons.cloud_off_outlined),
            label: const Text('Mark Workstation Offline'),
          ),
          if (item.candidateName.isNotEmpty)
            TextButton.icon(
              onPressed: () => controller.markSubmitted(item),
              icon: const Icon(Icons.done_all_outlined),
              label: const Text('Mark Submitted'),
            ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 94,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.58),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '-' : value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkLabel extends StatelessWidget {
  const _NetworkLabel({required this.record});

  final HallMonitorRecord record;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = _networkText(record);
    final bad = record.state == HallCandidateLiveState.offline;
    final warning = record.state == HallCandidateLiveState.issueFlagged;
    final color = bad ? cs.error : warning ? Colors.orange.shade700 : Colors.green.shade700;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _RiskLabel extends StatelessWidget {
  const _RiskLabel({required this.record});

  final HallMonitorRecord record;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = _riskText(record);
    final warning = record.hasIncident || record.hasMalpractice;
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: warning ? cs.error : cs.onSurface.withValues(alpha: 0.62),
        fontWeight: warning ? FontWeight.w800 : FontWeight.w600,
      ),
    );
  }
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

String _networkText(HallMonitorRecord record) {
  if (record.state == HallCandidateLiveState.offline) return 'Offline';
  if (record.state == HallCandidateLiveState.issueFlagged) return 'Degraded';
  if (record.lastSeenLabel == '-') return 'Standby';
  return 'Online';
}

String _riskText(HallMonitorRecord record) {
  if (record.hasMalpractice ||
      record.state == HallCandidateLiveState.malpracticeFlagged) {
    return 'High';
  }
  if (record.hasIncident || record.state == HallCandidateLiveState.issueFlagged) {
    return 'Review';
  }
  if (record.state == HallCandidateLiveState.offline) return 'Check';
  return 'Normal';
}

void _showCandidateSheet(
  BuildContext context,
  HallMonitorRecord record,
  HallMonitoringController controller,
) {
  controller.selectRecord(record);
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.94,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.all(16),
        child: _CandidateDetailPanel(record: record, controller: controller),
      ),
    ),
  );
}
