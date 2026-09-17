import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/glass_card.dart' show GlassCardTone;
import '../../../core/widgets/ks_page_shell.dart';
import '../../../core/widgets/ks_status_chip.dart';
import '../../../data/models/invigilator_models.dart';
import '../../../data/models/malpractice_models.dart';
import '../../../data/models/evidence_models.dart';
import '../../../data/models/workstation_models.dart';
import '../../demo/abu_demo_theme.dart';
import '../controller/invigilator_dashboard_controller.dart';
import '../widgets/invigilator_light_panel.dart';
import '../widgets/invigilator_top_actions.dart';

class InvigilatorDashboardView extends GetView<InvigilatorDashboardController> {
  const InvigilatorDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    // Self-themed, like the calculator dialog and scientific calculator
    // before it — this screen is reached straight from the ABU-branded
    // login flow and should carry the same light theme and university
    // branding, not the separate dark "security console" theme the rest
    // of the invigilator module still uses.
    return Theme(data: abuDemoTheme(), child: Builder(builder: _buildScaffold));
  }

  Widget _buildScaffold(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: abuCanvas,
      appBar: AppBar(
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
                  'INVIGILATOR WORKSTATION DASHBOARD',
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
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1480),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
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
                    child: LightPanel(
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
              _EvidenceSection(controller: controller),
              const SizedBox(height: 18),
              _MalpracticeReportsSection(controller: controller),
              const SizedBox(height: 18),
              KsPageSection(
                title: 'Search & Filter',
                subtitle:
                    'Locate workstations by seat, candidate, hall, or whitelist state.',
                child: LightPanel(
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
              Obx(() {
                final hall = controller.selectedHall.value;
                if (hall == 'All Halls') return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: KsPageSection(
                    title: 'Whole-Hall Controls',
                    subtitle: 'Pause, resume, or terminate every candidate currently in $hall.',
                    child: LightPanel(
                      tone: GlassCardTone.warning,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => controller.pauseHall(hall),
                            icon: const Icon(Icons.pause_circle_outline),
                            label: Text('Pause $hall'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => controller.resumeHall(hall),
                            icon: const Icon(Icons.play_circle_outline),
                            label: Text('Resume $hall'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () => _confirmTerminateHall(context, controller, hall),
                            icon: const Icon(Icons.gpp_bad_outlined),
                            label: Text('Terminate $hall'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
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
                    return LightPanel(
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
          ),
        ),
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

    return LightPanel(
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
        LightStatCard(
          title: 'Total Workstations',
          value: '${controller.totalCount}',
          icon: Icons.computer_outlined,
          width: 240,
        ),
        LightStatCard(
          title: 'Whitelisted',
          value: '${controller.whitelistedCount}',
          icon: Icons.verified_outlined,
          width: 240,
        ),
        LightStatCard(
          title: 'Pending',
          value: '${controller.pendingCount}',
          icon: Icons.pending_actions_outlined,
          width: 240,
        ),
        LightStatCard(
          title: 'In Exam',
          value: '${controller.activeExamCount}',
          icon: Icons.task_alt_outlined,
          width: 240,
        ),
        LightStatCard(
          title: 'Risk Flags',
          value: '${controller.riskFlaggedCount}',
          icon: Icons.gpp_bad_outlined,
          width: 240,
        ),
        LightStatCard(
          title: 'Critical Risk',
          value: '${controller.criticalRiskCount}',
          icon: Icons.warning_amber_outlined,
          width: 240,
        ),
        LightStatCard(
          title: 'Check-In Mismatch',
          value: '${controller.checkInMismatchCount}',
          icon: Icons.badge_outlined,
          width: 240,
        ),
        LightStatCard(
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

    return LightPanel(
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
                  if (record.isPaused)
                    const KsStatusChip(
                      label: 'Paused',
                      tone: KsStatusChipTone.warning,
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                    ),
                  if (controller
                      .malpracticeReportsFor(record.workstationId)
                      .isNotEmpty)
                    KsStatusChip(
                      label: controller
                              .malpracticeReportsFor(record.workstationId)
                              .any((r) => r.escalated)
                          ? 'Malpractice — Escalated'
                          : 'Malpractice Reported',
                      tone: KsStatusChipTone.danger,
                      padding: const EdgeInsets.symmetric(
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
          const Divider(color: abuLine),
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
                          color: abuCanvas,
                          border: Border.all(color: abuLine),
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
          for (final report in controller.malpracticeReportsFor(record.workstationId)) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.gpp_bad_outlined,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Malpractice: ${report.type.name} '
                          '(${report.severity.name.toUpperCase()})',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ),
                      if (report.escalated)
                        const KsStatusChip(
                          label: 'Escalated',
                          tone: KsStatusChipTone.warningSoft,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    report.description,
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.88),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Action taken: ${report.actionTaken}',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
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
              OutlinedButton.icon(
                onPressed: () =>
                    Get.toNamed(Routes.malpracticeReport, arguments: record),
                icon: const Icon(Icons.gpp_bad_outlined),
                label: const Text('Malpractice'),
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
              if (record.candidateName.isNotEmpty) ...[
                if (!record.isPaused)
                  OutlinedButton.icon(
                    onPressed: () => controller.pauseCandidate(record),
                    icon: const Icon(Icons.pause_circle_outline),
                    label: const Text('Pause Exam'),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () => controller.resumeCandidate(record),
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text('Resume Exam'),
                  ),
                FilledButton.tonalIcon(
                  onPressed: () => _confirmTerminateRecord(context, controller, record),
                  icon: const Icon(Icons.gpp_bad_outlined),
                  label: const Text('Terminate Exam'),
                ),
              ],
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

class _EvidenceSection extends StatelessWidget {
  const _EvidenceSection({required this.controller});

  final InvigilatorDashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final events = controller.evidenceEvents;
      if (events.isEmpty) return const SizedBox.shrink();

      return KsPageSection(
        title: 'Detection Evidence',
        subtitle:
            'Flagged by each workstation\'s local detector — phone, identity '
            'mismatch, elevated talking, unauthorized USB device. Timing and '
            '(where relevant) a confidence score only — never a saved photo '
            'or recorded audio. Review before acting.',
        child: LightPanel(
          tone: GlassCardTone.danger,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final event in events) ...[
                _EvidenceCard(controller: controller, event: event),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      );
    });
  }
}

class _EvidenceCard extends StatelessWidget {
  const _EvidenceCard({required this.controller, required this.event});

  final InvigilatorDashboardController controller;
  final EvidenceEvent event;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final confidence = event.confidence;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFEF4444).withValues(alpha: 0.10),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${event.hallName} • Seat ${event.seatNumber} — '
                  '${event.candidateName.isEmpty ? event.workstationId : event.candidateName}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
              const SizedBox(width: 8),
              KsStatusChip(
                label: _evidenceTypeLabel(event.evidenceType),
                tone: KsStatusChipTone.danger,
              ),
              if (confidence != null) ...[
                const SizedBox(width: 8),
                KsStatusChip(
                  label: '${(confidence * 100).round()}%',
                  tone: confidence >= 0.85
                      ? KsStatusChipTone.danger
                      : KsStatusChipTone.warning,
                ),
              ],
              if (event.escalated) ...[
                const SizedBox(width: 8),
                const KsStatusChip(
                  label: 'Escalated',
                  tone: KsStatusChipTone.accent,
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          if (event.details.isNotEmpty) ...[
            Text(
              event.details,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.86),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            '${event.examTitle.isEmpty ? 'Exam' : event.examTitle} • '
            'Detected ${event.detectedAtIso}',
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.72),
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: event.escalated
                    ? null
                    : () => controller.escalateEvidenceEvent(event),
                icon: const Icon(Icons.priority_high_outlined),
                label: Text(event.escalated ? 'Escalated' : 'Escalate to Exam Officer'),
              ),
              OutlinedButton.icon(
                onPressed: () => Get.toNamed(
                  Routes.malpracticeReport,
                  arguments: event,
                ),
                icon: const Icon(Icons.gpp_bad_outlined),
                label: const Text('File Malpractice Report'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _confirmTerminate(context, controller, event),
                icon: const Icon(Icons.block_outlined),
                label: const Text('Terminate Exam'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _evidenceTypeLabel(String evidenceType) {
    switch (evidenceType) {
      case EvidenceType.phone:
        return 'Possible Phone';
      case EvidenceType.identity:
        return 'Identity Mismatch';
      case EvidenceType.talking:
        return 'Elevated Talking';
      case EvidenceType.usb:
        return 'USB Device';
      default:
        return 'Detection';
    }
  }
}

Future<void> _confirmTerminate(
  BuildContext context,
  InvigilatorDashboardController controller,
  EvidenceEvent event,
) async {
  final reasonController = TextEditingController(
    text: 'Seat ${event.seatNumber}: ${event.details.isEmpty ? 'possible exam malpractice' : event.details}',
  );
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.gpp_bad_outlined, color: Color(0xFFEF4444), size: 32),
      title: const Text('Terminate this exam?'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This immediately ends the exam for '
              '${event.candidateName.isEmpty ? 'seat ${event.seatNumber}' : event.candidateName} '
              'if their workstation is currently connected. This cannot be undone.',
              style: const TextStyle(height: 1.5),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Reason'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Terminate Exam'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    controller.terminateExam(
      workstationId: event.workstationId,
      seatLabel: 'seat ${event.seatNumber}',
      reason: reasonController.text.trim(),
    );
  }
  reasonController.dispose();
}

/// Same confirmation flow as [_confirmTerminate], generalized for a
/// workstation card's own "Terminate Exam" action rather than one raised
/// from a detected evidence event.
Future<void> _confirmTerminateRecord(
  BuildContext context,
  InvigilatorDashboardController controller,
  InvigilatorWorkstationRecord record,
) async {
  final reasonController = TextEditingController();
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.gpp_bad_outlined, color: Color(0xFFEF4444), size: 32),
      title: const Text('Terminate this exam?'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This immediately ends the exam for '
              '${record.candidateName.isEmpty ? 'seat ${record.seatNumber}' : record.candidateName} '
              'if their workstation is currently connected. This cannot be undone.',
              style: const TextStyle(height: 1.5),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Reason'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Terminate Exam'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    controller.terminateExam(
      workstationId: record.workstationId,
      seatLabel: 'seat ${record.seatNumber}',
      reason: reasonController.text.trim(),
    );
  }
  reasonController.dispose();
}

Future<void> _confirmTerminateHall(
  BuildContext context,
  InvigilatorDashboardController controller,
  String hallName,
) async {
  final reasonController = TextEditingController();
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.gpp_bad_outlined, color: Color(0xFFEF4444), size: 32),
      title: Text('Terminate every exam in $hallName?'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This immediately ends the exam for every candidate currently '
              'active in this hall whose workstation is connected. This cannot be undone.',
              style: TextStyle(height: 1.5),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Reason'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Terminate Hall'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    controller.terminateHall(hallName, reason: reasonController.text.trim());
  }
  reasonController.dispose();
}

class _MalpracticeReportsSection extends StatelessWidget {
  const _MalpracticeReportsSection({required this.controller});

  final InvigilatorDashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final reports = controller.malpracticeReports;
      if (reports.isEmpty) return const SizedBox.shrink();

      return KsPageSection(
        title: 'Malpractice Reports',
        subtitle: 'Filed by invigilators for this center, newest first.',
        child: LightPanel(
          tone: GlassCardTone.warning,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final report in reports) ...[
                _MalpracticeReportCard(controller: controller, report: report),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      );
    });
  }
}

class _MalpracticeReportCard extends StatelessWidget {
  const _MalpracticeReportCard({required this.controller, required this.report});

  final InvigilatorDashboardController controller;
  final MalpracticeReportModel report;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: abuCanvas,
        border: Border.all(color: abuLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${report.hallName} • Seat ${report.seatNumber} — '
                  '${report.candidateName.isEmpty ? report.workstationId : report.candidateName}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
              const SizedBox(width: 8),
              KsStatusChip(
                label: _severityLabel(report.severity),
                tone: report.severity == MalpracticeSeverity.critical ||
                        report.severity == MalpracticeSeverity.severe
                    ? KsStatusChipTone.danger
                    : KsStatusChipTone.warning,
              ),
              if (report.escalated) ...[
                const SizedBox(width: 8),
                const KsStatusChip(
                  label: 'Escalated',
                  tone: KsStatusChipTone.accent,
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            report.description,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.86),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Reported by ${report.reportedBy.isEmpty ? 'invigilator' : report.reportedBy} '
            'at ${report.reportedAtIso}',
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.62),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: report.escalated
                    ? null
                    : () => controller.escalateMalpracticeReport(report),
                icon: const Icon(Icons.priority_high_outlined),
                label: Text(report.escalated ? 'Escalated' : 'Escalate to Exam Officer'),
              ),
            ],
          ),
        ],
      ),
    );
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
