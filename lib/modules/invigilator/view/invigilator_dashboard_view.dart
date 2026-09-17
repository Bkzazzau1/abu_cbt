import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/ks_status_chip.dart';
import '../../../data/models/invigilator_models.dart';
import '../../../data/models/workstation_models.dart';
import '../../demo/abu_demo_theme.dart';
import '../controller/invigilator_dashboard_controller.dart';
import '../widgets/invigilator_light_panel.dart';
import '../widgets/invigilator_top_actions.dart';

class InvigilatorDashboardView extends GetView<InvigilatorDashboardController> {
  const InvigilatorDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(data: abuDemoTheme(), child: Builder(builder: _buildScaffold));
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: abuCanvas,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        foregroundColor: abuInk,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: abuLine),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/abulogo.png', height: 32),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Ahmadu Bello University, Zaria',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                Text(
                  'INVIGILATOR CONSOLE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: abuMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Obx(
            () => KsStatusChip(
              label: controller.liveFeedConnected.value ? 'Live' : 'Offline',
              tone: controller.liveFeedConnected.value
                  ? KsStatusChipTone.success
                  : KsStatusChipTone.warning,
              margin: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
          const SizedBox(width: 8),
          ...buildInvigilatorTopActions(showDashboard: false),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1380),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView(
                  children: [
                    _SessionHeader(controller: controller),
                    const SizedBox(height: 16),
                    _OperationalSummary(controller: controller),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 980) {
                          return Column(
                            children: [
                              _AttentionPanel(controller: controller),
                              const SizedBox(height: 16),
                              _HallSnapshot(controller: controller),
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 6,
                              child: _AttentionPanel(controller: controller),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 5,
                              child: _HallSnapshot(controller: controller),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _QuickAccessPanel(),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _SessionHeader extends StatelessWidget {
  const _SessionHeader({required this.controller});

  final InvigilatorDashboardController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final examTitle = controller.records
        .map((record) => record.examTitle.trim())
        .firstWhere((title) => title.isNotEmpty, orElse: () => 'CBT Examination');

    return LightPanel(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 820;

          final heading = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: controller.liveFeedConnected.value
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Live Examination Operations',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: abuMuted,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                examTitle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${controller.hallOptions.length - 1} halls • '
                '${controller.totalCount} registered workstations',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.68),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          );

          final action = FilledButton.icon(
            onPressed: () => _goPrimary(Routes.hallMonitoring),
            icon: const Icon(Icons.monitor_heart_outlined),
            label: const Text('Open Live Hall'),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                heading,
                const SizedBox(height: 14),
                action,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: heading),
              const SizedBox(width: 20),
              action,
            ],
          );
        },
      ),
    );
  }
}

class _OperationalSummary extends StatelessWidget {
  const _OperationalSummary({required this.controller});

  final InvigilatorDashboardController controller;

  @override
  Widget build(BuildContext context) {
    final attention = controller.records.where(_needsAttention).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1050 ? 4 : width >= 620 ? 2 : 1;
        final gap = 12.0;
        final cardWidth = (width - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            _MetricCard(
              width: cardWidth,
              title: 'In Exam',
              value: '${controller.activeExamCount}',
              subtitle: 'Candidates currently writing',
              icon: Icons.edit_note_outlined,
              tone: _MetricTone.success,
            ),
            _MetricCard(
              width: cardWidth,
              title: 'Ready',
              value: '${controller.whitelistedCount}',
              subtitle: 'Approved workstations',
              icon: Icons.verified_outlined,
              tone: _MetricTone.primary,
            ),
            _MetricCard(
              width: cardWidth,
              title: 'Needs Attention',
              value: '$attention',
              subtitle: 'Risk, mismatch or malpractice',
              icon: Icons.notification_important_outlined,
              tone: _MetricTone.warning,
            ),
            _MetricCard(
              width: cardWidth,
              title: 'Pending Setup',
              value: '${controller.pendingCount}',
              subtitle: 'Awaiting workstation approval',
              icon: Icons.pending_actions_outlined,
              tone: _MetricTone.neutral,
            ),
          ],
        );
      },
    );
  }
}

class _AttentionPanel extends StatelessWidget {
  const _AttentionPanel({required this.controller});

  final InvigilatorDashboardController controller;

  @override
  Widget build(BuildContext context) {
    final queue = controller.priorityQueue;

    return LightPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attention Queue',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Only candidates that need invigilator attention.',
                      style: TextStyle(
                        color: abuMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              KsStatusChip(
                label: '${queue.length} priority',
                tone: queue.isEmpty
                    ? KsStatusChipTone.success
                    : KsStatusChipTone.warning,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (queue.isEmpty)
            _EmptyState(
              icon: Icons.check_circle_outline,
              title: 'No priority alerts',
              message: 'No candidate currently requires immediate review.',
            )
          else
            ...queue.map(
              (record) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _AttentionRow(record: record),
              ),
            ),
          const SizedBox(height: 5),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _goPrimary(Routes.hallMonitoring),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('View all live workstations'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({required this.record});

  final InvigilatorWorkstationRecord record;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Get.toNamed(Routes.candidateActionPanel, arguments: record),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.22),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: abuLine),
              ),
              child: Text(
                record.seatNumber,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.candidateName.isEmpty
                        ? record.workstationId
                        : record.candidateName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${record.hallName} • ${_attentionReason(record)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.66),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (record.riskFlagged)
              KsStatusChip(
                label: '${record.riskScore}% risk',
                tone: record.riskLevel.toLowerCase() == 'critical'
                    ? KsStatusChipTone.danger
                    : KsStatusChipTone.warning,
              )
            else
              const Icon(Icons.chevron_right, color: abuMuted),
          ],
        ),
      ),
    );
  }
}

class _HallSnapshot extends StatelessWidget {
  const _HallSnapshot({required this.controller});

  final InvigilatorDashboardController controller;

  @override
  Widget build(BuildContext context) {
    final halls = controller.hallOptions.where((hall) => hall != 'All Halls').toList();

    return LightPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hall Snapshot',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          const Text(
            'Current exam activity by hall.',
            style: TextStyle(color: abuMuted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          if (halls.isEmpty)
            const _EmptyState(
              icon: Icons.meeting_room_outlined,
              title: 'No halls loaded',
              message: 'Hall activity will appear here when records are available.',
            )
          else
            ...halls.map((hall) {
              final records = controller.records.where((r) => r.hallName == hall).toList();
              final inExam = records
                  .where((r) => r.usageState == WorkstationUsageState.inExam)
                  .length;
              final attention = records.where(_needsAttention).length;
              final pending = records
                  .where((r) => r.status == WorkstationStatus.pending)
                  .length;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    controller.updateHall(hall);
                    _goPrimary(Routes.hallMonitoring);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: abuCanvas,
                      border: Border.all(color: abuLine),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hall,
                                style: const TextStyle(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${records.length} workstations',
                                style: const TextStyle(
                                  color: abuMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _TinyStat(label: 'Exam', value: '$inExam'),
                        const SizedBox(width: 15),
                        _TinyStat(label: 'Attention', value: '$attention'),
                        const SizedBox(width: 15),
                        _TinyStat(label: 'Pending', value: '$pending'),
                        const SizedBox(width: 5),
                        const Icon(Icons.chevron_right, color: abuMuted),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _QuickAccessPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LightPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Operations',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          const Text(
            'Go directly to the task you need. Detailed controls stay inside each section.',
            style: TextStyle(color: abuMuted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final columns = width >= 1050 ? 5 : width >= 720 ? 3 : width >= 460 ? 2 : 1;
              final gap = 10.0;
              final cardWidth = (width - gap * (columns - 1)) / columns;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  _OperationTile(
                    width: cardWidth,
                    icon: Icons.monitor_outlined,
                    title: 'Live Hall',
                    subtitle: 'Candidates & workstations',
                    onTap: () => _goPrimary(Routes.hallMonitoring),
                  ),
                  _OperationTile(
                    width: cardWidth,
                    icon: Icons.fact_check_outlined,
                    title: 'Attendance',
                    subtitle: 'Check-in & presence',
                    onTap: () => _goPrimary(Routes.attendanceRegister),
                  ),
                  _OperationTile(
                    width: cardWidth,
                    icon: Icons.grid_view_outlined,
                    title: 'Seat Map',
                    subtitle: 'Hall layout & transfers',
                    onTap: () => _goPrimary(Routes.seatMap),
                  ),
                  _OperationTile(
                    width: cardWidth,
                    icon: Icons.build_circle_outlined,
                    title: 'Technical',
                    subtitle: 'Health & fault reports',
                    onTap: () => _goPrimary(Routes.technicalReports),
                  ),
                  _OperationTile(
                    width: cardWidth,
                    icon: Icons.dashboard_outlined,
                    title: 'Session',
                    subtitle: 'Exam-level controls',
                    onTap: () => _goPrimary(Routes.examSessionDashboard),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.width,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.tone,
  });

  final double width;
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final _MetricTone tone;

  @override
  Widget build(BuildContext context) {
    final accent = switch (tone) {
      _MetricTone.primary => Theme.of(context).colorScheme.primary,
      _MetricTone.success => const Color(0xFF16A34A),
      _MetricTone.warning => const Color(0xFFF59E0B),
      _MetricTone.neutral => const Color(0xFF64748B),
    };

    return SizedBox(
      width: width,
      child: LightPanel(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: abuMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TinyStat extends StatelessWidget {
  const _TinyStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        Text(
          label,
          style: const TextStyle(
            color: abuMuted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _OperationTile extends StatelessWidget {
  const _OperationTile({
    required this.width,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final double width;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: width,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: abuCanvas,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: abuLine),
          ),
          child: Row(
            children: [
              Icon(icon, color: primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: abuMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 19, color: abuMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: abuCanvas,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: abuLine),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF16A34A)),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(
                    color: abuMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _MetricTone { primary, success, warning, neutral }

bool _needsAttention(InvigilatorWorkstationRecord record) {
  return record.riskFlagged ||
      record.checkInMismatch ||
      record.similarityFlagged;
}

String _attentionReason(InvigilatorWorkstationRecord record) {
  if (record.checkInMismatch) return 'Check-in mismatch';
  if (record.similarityFlagged) return 'Similar answer flag';
  if (record.riskFlagged) return '${record.riskLevel} risk';
  return 'Needs review';
}

void _goPrimary(String route) {
  if (Get.currentRoute == route) return;
  Get.offNamed(route);
}
