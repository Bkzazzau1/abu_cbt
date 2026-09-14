import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/ks_page_shell.dart';
import '../../../core/widgets/ks_stat_card.dart';
import '../../../core/widgets/ks_status_chip.dart';
import '../../../data/models/invigilator_models.dart';
import '../../../data/models/workstation_models.dart';
import '../controller/invigilator_dashboard_controller.dart';
import '../widgets/invigilator_top_actions.dart';

class InvigilatorDashboardView extends GetView<InvigilatorDashboardController> {
  const InvigilatorDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invigilator Workstation Dashboard'),
        backgroundColor: Colors.transparent,
        actions: [
          Obx(
            () => KsStatusChip(
              label: controller.liveFeedConnected.value
                  ? 'Live Feed'
                  : 'Feed Offline',
              tone: controller.liveFeedConnected.value
                  ? KsStatusChipTone.success
                  : KsStatusChipTone.warning,
              margin: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
          const SizedBox(width: 8),
          ...buildInvigilatorTopActions(),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: KsPageShell(
        padding: const EdgeInsets.fromLTRB(20, 92, 20, 20),
        maxContentWidth: 1480,
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: [
              _HeroHeader(controller: controller),
              const SizedBox(height: 18),
              _SummaryRow(controller: controller),
              const SizedBox(height: 18),
              Obx(() {
                final queue = controller.priorityQueue;
                if (queue.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: KsPageSection(
                    title: 'Priority Queue',
                    subtitle:
                        'Highest-risk candidates, ranked — check these first.',
                    child: GlassCard(
                      tone: GlassCardTone.danger,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final record in queue)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 34,
                                    child: Text(
                                      '${record.riskScore}%',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFFEF4444),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '${record.hallName} • Seat ${record.seatNumber} — '
                                      '${record.candidateName.isEmpty ? record.workstationId : record.candidateName}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  riskLevelChip(
                                    record.riskLevel,
                                    record.riskScore,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              KsPageSection(
                title: 'Search & Filter',
                subtitle:
                    'Locate workstations by seat, candidate, hall, or whitelist state.',
                child: GlassCard(
                  tone: GlassCardTone.primary,
                  child: Column(
                    children: [
                      TextField(
                        controller: controller.searchController,
                        onChanged: controller.updateSearch,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          labelText:
                              'Search seat, workstation ID, candidate, reg no',
                        ),
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 760;

                          if (compact) {
                            return Column(
                              children: [
                                Obx(
                                  () => DropdownButtonFormField<String>(
                                    initialValue: controller.selectedHall.value,
                                    dropdownColor: cs.surfaceContainerHighest
                                        .withValues(alpha: 0.96),
                                    borderRadius: BorderRadius.circular(18),
                                    items: controller.hallOptions
                                        .map(
                                          (e) => DropdownMenuItem(
                                            value: e,
                                            child: Text(e),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) {
                                      if (v != null) controller.updateHall(v);
                                    },
                                    decoration: const InputDecoration(
                                      labelText: 'Hall',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Obx(
                                  () => DropdownButtonFormField<String>(
                                    initialValue:
                                        controller.selectedStatus.value,
                                    dropdownColor: cs.surfaceContainerHighest
                                        .withValues(alpha: 0.96),
                                    borderRadius: BorderRadius.circular(18),
                                    items: controller.statusOptions
                                        .map(
                                          (e) => DropdownMenuItem(
                                            value: e,
                                            child: Text(e),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) {
                                      if (v != null) controller.updateStatus(v);
                                    },
                                    decoration: const InputDecoration(
                                      labelText: 'Whitelist Status',
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(
                                child: Obx(
                                  () => DropdownButtonFormField<String>(
                                    initialValue: controller.selectedHall.value,
                                    dropdownColor: cs.surfaceContainerHighest
                                        .withValues(alpha: 0.96),
                                    borderRadius: BorderRadius.circular(18),
                                    items: controller.hallOptions
                                        .map(
                                          (e) => DropdownMenuItem(
                                            value: e,
                                            child: Text(e),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) {
                                      if (v != null) controller.updateHall(v);
                                    },
                                    decoration: const InputDecoration(
                                      labelText: 'Hall',
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Obx(
                                  () => DropdownButtonFormField<String>(
                                    initialValue:
                                        controller.selectedStatus.value,
                                    dropdownColor: cs.surfaceContainerHighest
                                        .withValues(alpha: 0.96),
                                    borderRadius: BorderRadius.circular(18),
                                    items: controller.statusOptions
                                        .map(
                                          (e) => DropdownMenuItem(
                                            value: e,
                                            child: Text(e),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) {
                                      if (v != null) controller.updateStatus(v);
                                    },
                                    decoration: const InputDecoration(
                                      labelText: 'Whitelist Status',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              KsPageSection(
                title: 'Workstation Records',
                subtitle:
                    'Operational status, candidate presence, and invigilator controls.',
                trailing: Obx(
                  () => KsStatusChip(
                    label: '${controller.filteredRecords.length} visible',
                    tone: KsStatusChipTone.info,
                  ),
                ),
                child: Obx(() {
                  final items = controller.filteredRecords;

                  if (items.isEmpty) {
                    return GlassCard(
                      child: Text(
                        'No workstation records match your filter.',
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: items
                        .map(
                          (record) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _WorkstationCard(
                              record: record,
                              controller: controller,
                            ),
                          ),
                        )
                        .toList(),
                  );
                }),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.controller});

  final InvigilatorDashboardController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GlassCard(
      tone: GlassCardTone.primary,
      showGlow: true,
      padding: const EdgeInsets.all(22),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 900;

          final left = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KsStatusChip(
                label: 'Invigilator Command Center',
                tone: KsStatusChipTone.accent,
              ),
              const SizedBox(height: 14),
              const Text(
                'Workstation Oversight & Hall Control',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Monitor whitelisting, candidate activity, exam readiness, and workstation states from a single operational dashboard.',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.76),
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ],
          );

          final right = Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => Get.toNamed(Routes.examSessionDashboard),
                icon: const Icon(Icons.dashboard_outlined),
                label: const Text('Session Dashboard'),
              ),
              OutlinedButton.icon(
                onPressed: () => Get.toNamed(Routes.attendanceRegister),
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Attendance'),
              ),
              FilledButton.icon(
                onPressed: () => Get.toNamed(Routes.hallMonitoring),
                icon: const Icon(Icons.monitor_outlined),
                label: const Text('Open Live Hall'),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [left, const SizedBox(height: 18), right],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: left),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: Align(alignment: Alignment.topRight, child: right),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.controller});

  final InvigilatorDashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        KsStatCard(
          title: 'Total Workstations',
          value: '${controller.totalCount}',
          icon: Icons.computer_outlined,
          width: 240,
        ),
        KsStatCard(
          title: 'Whitelisted',
          value: '${controller.whitelistedCount}',
          icon: Icons.verified_outlined,
          width: 240,
        ),
        KsStatCard(
          title: 'Pending',
          value: '${controller.pendingCount}',
          icon: Icons.pending_actions_outlined,
          width: 240,
        ),
        KsStatCard(
          title: 'In Exam',
          value: '${controller.activeExamCount}',
          icon: Icons.task_alt_outlined,
          width: 240,
        ),
        KsStatCard(
          title: 'Risk Flags',
          value: '${controller.riskFlaggedCount}',
          icon: Icons.gpp_bad_outlined,
          width: 240,
        ),
        KsStatCard(
          title: 'Critical Risk',
          value: '${controller.criticalRiskCount}',
          icon: Icons.warning_amber_outlined,
          width: 240,
        ),
        KsStatCard(
          title: 'Check-In Mismatch',
          value: '${controller.checkInMismatchCount}',
          icon: Icons.badge_outlined,
          width: 240,
        ),
        KsStatCard(
          title: 'Similar Answers (AI)',
          value: '${controller.similarityFlaggedCount}',
          icon: Icons.compare_arrows_outlined,
          width: 240,
        ),
      ],
    );
  }
}

class _WorkstationCard extends StatelessWidget {
  const _WorkstationCard({required this.record, required this.controller});

  final InvigilatorWorkstationRecord record;
  final InvigilatorDashboardController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 820;

              final header = Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${record.hallName} • Seat ${record.seatNumber}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Workstation ID: ${record.workstationId}',
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              );

              final chips = Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _statusChip(record.status),
                  _usageChip(record.usageState),
                  if (!record.workstationApproved)
                    const KsStatusChip(
                      label: 'Not Approved',
                      tone: KsStatusChipTone.warning,
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                    ),
                  if (record.riskFlagged)
                    const KsStatusChip(
                      label: 'Risk Flagged',
                      tone: KsStatusChipTone.danger,
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                    ),
                  if (record.riskFlagged)
                    riskLevelChip(record.riskLevel, record.riskScore),
                  if (record.checkInMismatch)
                    const KsStatusChip(
                      label: 'Check-In Mismatch',
                      tone: KsStatusChipTone.danger,
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                    ),
                  if (record.similarityFlagged)
                    const KsStatusChip(
                      label: 'Similar Answer (AI)',
                      tone: KsStatusChipTone.danger,
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                    ),
                ],
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [header, const SizedBox(height: 12), chips],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [header, const SizedBox(width: 16), chips],
              );
            },
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.07)),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 900;

              final infoBlock = Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoLine(label: 'Center', value: record.centerName),
                    _InfoLine(
                      label: 'App Installed',
                      value: record.appInstalled ? 'Yes' : 'No',
                    ),
                    _InfoLine(label: 'Last Seen', value: record.lastSeenLabel),
                  ],
                ),
              );

              final candidateBlock = Expanded(
                child: record.candidateName.isNotEmpty
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoLine(
                            label: 'Candidate',
                            value: record.candidateName,
                            strong: true,
                          ),
                          _InfoLine(
                            label: 'Reg No',
                            value: record.registrationNumber,
                          ),
                          if (record.examTitle.isNotEmpty)
                            _InfoLine(label: 'Exam', value: record.examTitle),
                          if (record.clientIpAddress.trim().isNotEmpty)
                            _InfoLine(
                              label: 'Client IP',
                              value: record.clientIpAddress,
                            ),
                        ],
                      )
                    : Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: Colors.white.withValues(alpha: 0.04),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Text(
                          'No candidate logged in.',
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.72),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              );

              if (compact) {
                return Column(
                  children: [
                    infoBlock,
                    const SizedBox(height: 14),
                    candidateBlock,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  infoBlock,
                  const SizedBox(width: 18),
                  candidateBlock,
                ],
              );
            },
          ),
          if (record.riskFlagged) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFEF4444),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Submission Risk Alert',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Severity: ${record.riskLevel.toUpperCase()} (${record.riskScore}%) • '
                    'Approved: ${record.workstationApproved ? "Yes" : "No"}',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.88),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (record.isNewWorkstation) ...[
                    const SizedBox(height: 8),
                    const KsStatusChip(
                      label: 'New Workstation (Never Submitted Before)',
                      tone: KsStatusChipTone.warning,
                    ),
                  ],
                  if (record.clientIpAddress.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'IP: ${record.clientIpAddress} • Expected: '
                      '${record.expectedHallIpRange.isEmpty ? "Unconfigured" : record.expectedHallIpRange} '
                      '• Match: ${record.ipInExpectedRange ? "Yes" : "No"}',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.86),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  if (record.riskReasons.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...record.riskReasons.map(
                      (reason) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• $reason',
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.86),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (record.checkInMismatch) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.badge_outlined, color: Color(0xFFEF4444)),
                      SizedBox(width: 8),
                      Text(
                        'Check-In Mismatch',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    record.checkInMismatchReason.isEmpty
                        ? 'This candidate is active from a different hall/seat than their check-in record.'
                        : record.checkInMismatchReason,
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.88),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (record.similarityFlagged) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.compare_arrows_outlined,
                        color: Color(0xFFEF4444),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Similar Answer Detected (AI)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    record.similarityReason.isEmpty
                        ? 'This candidate\'s answer closely matches another candidate\'s answer in the same hall.'
                        : record.similarityReason,
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.88),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          const Text(
            'Primary Actions',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () =>
                    Get.toNamed(Routes.candidateCheckIn, arguments: record),
                icon: const Icon(Icons.badge_outlined),
                label: const Text('Check-In'),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    Get.toNamed(Routes.incidentReport, arguments: record),
                icon: const Icon(Icons.report_problem_outlined),
                label: const Text('Incident'),
              ),
              if (record.status != WorkstationStatus.whitelisted)
                FilledButton.tonalIcon(
                  onPressed: () => controller.approve(record),
                  icon: const Icon(Icons.verified_outlined),
                  label: const Text('Approve'),
                ),
              if (record.status != WorkstationStatus.disabled)
                OutlinedButton.icon(
                  onPressed: () => controller.disable(record),
                  icon: const Icon(Icons.pause_circle_outline),
                  label: const Text('Disable'),
                ),
              if (record.status != WorkstationStatus.revoked)
                OutlinedButton.icon(
                  onPressed: () => controller.revoke(record),
                  icon: const Icon(Icons.block_outlined),
                  label: const Text('Revoke'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Usage State Controls',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => controller.markActive(record),
                child: const Text('Mark Active'),
              ),
              OutlinedButton(
                onPressed: () => controller.markLoggedIn(record),
                child: const Text('Mark Logged In'),
              ),
              OutlinedButton(
                onPressed: () => controller.markInExam(record),
                child: const Text('Mark In Exam'),
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

  Widget _statusChip(WorkstationStatus status) {
    late final String text;
    late final KsStatusChipTone tone;

    switch (status) {
      case WorkstationStatus.pending:
        text = 'Pending';
        tone = KsStatusChipTone.warning;
        break;
      case WorkstationStatus.whitelisted:
        text = 'Whitelisted';
        tone = KsStatusChipTone.success;
        break;
      case WorkstationStatus.disabled:
        text = 'Disabled';
        tone = KsStatusChipTone.warningSoft;
        break;
      case WorkstationStatus.revoked:
        text = 'Revoked';
        tone = KsStatusChipTone.danger;
        break;
    }

    return KsStatusChip(
      label: text,
      tone: tone,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    );
  }

  Widget _usageChip(WorkstationUsageState state) {
    late final String text;
    late final KsStatusChipTone tone;

    switch (state) {
      case WorkstationUsageState.inactive:
        text = 'Inactive';
        tone = KsStatusChipTone.neutral;
        break;
      case WorkstationUsageState.active:
        text = 'Active';
        tone = KsStatusChipTone.info;
        break;
      case WorkstationUsageState.candidateLoggedIn:
        text = 'Logged In';
        tone = KsStatusChipTone.warningSoft;
        break;
      case WorkstationUsageState.inExam:
        text = 'In Exam';
        tone = KsStatusChipTone.success;
        break;
      case WorkstationUsageState.submitted:
        text = 'Submitted';
        tone = KsStatusChipTone.accent;
        break;
    }

    return KsStatusChip(
      label: text,
      tone: tone,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    );
  }
}

Widget riskLevelChip(String level, int score) {
  final normalized = level.toLowerCase();
  switch (normalized) {
    case 'critical':
      return KsStatusChip(
        label: 'Critical Risk ($score%)',
        tone: KsStatusChipTone.danger,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      );
    case 'high':
      return KsStatusChip(
        label: 'High Risk ($score%)',
        tone: KsStatusChipTone.warning,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      );
    case 'medium':
      return KsStatusChip(
        label: 'Medium Risk ($score%)',
        tone: KsStatusChipTone.warningSoft,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      );
    default:
      return KsStatusChip(
        label: 'Low Risk ($score%)',
        tone: KsStatusChipTone.info,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      );
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
      padding: const EdgeInsets.only(bottom: 8),
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
