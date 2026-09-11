import 'package:flutter/material.dart';

import '../../../core/theme/ks_ui_tokens.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/ks_status_chip.dart';
import '../../../data/models/workstation_models.dart';
import 'portal_dashboard_shared.dart';

class PortalHeaderBar extends StatelessWidget {
  const PortalHeaderBar({
    super.key,
    required this.networkStatus,
    required this.workstationStatus,
    required this.onWorkstation,
    required this.onLogout,
  });

  final NetworkHealthStatus networkStatus;
  final WorkstationStatus workstationStatus;
  final VoidCallback onWorkstation;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 920;

          final titleBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kaduna State University',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.70),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Examination Command Center',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'CBT Candidate Dashboard',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.74),
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
            ],
          );

          final actions = Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              KsStatusChip(
                label: networkLabel(networkStatus),
                tone: networkTone(networkStatus),
              ),
              KsStatusChip(
                label: workstationLabel(workstationStatus),
                tone: workstationTone(workstationStatus),
              ),
              OutlinedButton.icon(
                onPressed: onWorkstation,
                icon: const Icon(Icons.memory_rounded),
                label: const Text('Workstation'),
              ),
              FilledButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Logout'),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [titleBlock, const SizedBox(height: 16), actions],
            );
          }

          return Row(
            children: [
              Expanded(child: titleBlock),
              const SizedBox(width: 18),
              Flexible(child: actions),
            ],
          );
        },
      ),
    );
  }
}

class PortalSidebar extends StatelessWidget {
  const PortalSidebar({
    super.key,
    required this.candidateName,
    required this.regNo,
    required this.level,
    required this.photoAsset,
    required this.department,
    required this.programme,
    required this.hallDisplay,
    required this.seatDisplay,
    required this.workstationStatus,
    required this.dueNowCount,
    required this.upcomingCount,
    required this.completedCount,
    required this.closedCount,
    required this.onStartNow,
    required this.onWorkstation,
    required this.onLogout,
    this.fillHeight = false,
  });

  final String candidateName;
  final String regNo;
  final String level;
  final String photoAsset;
  final String department;
  final String programme;
  final String hallDisplay;
  final String seatDisplay;
  final WorkstationStatus workstationStatus;
  final int dueNowCount;
  final int upcomingCount;
  final int completedCount;
  final int closedCount;
  final VoidCallback? onStartNow;
  final VoidCallback onWorkstation;
  final VoidCallback onLogout;
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kaduna State University',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'CBT Candidate Portal',
          style: TextStyle(
            color: cs.onSurface.withValues(alpha: 0.66),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StudentPortrait(
                    imageAsset: photoAsset,
                    candidateName: candidateName,
                    size: 72,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Candidate Profile',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'CBT Candidate Profile',
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.70),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const _ProfileFieldLabel(label: 'Student Name'),
              const SizedBox(height: 4),
              Text(
                candidateName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              _ProfileFieldRow(label: 'Level', value: level),
              const SizedBox(height: 8),
              _ProfileFieldRow(label: 'Reg No', value: regNo),
              const SizedBox(height: 8),
              _ProfileFieldRow(label: 'Mode', value: programme),
              const SizedBox(height: 8),
              _ProfileFieldRow(label: 'Dept', value: department),
              const SizedBox(height: 12),
              KsStatusChip(
                label: workstationLabel(workstationStatus),
                tone: workstationTone(workstationStatus),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Lifecycle Navigation',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        _SidebarMetricTile(
          icon: Icons.play_circle_outline_rounded,
          label: 'Due Now',
          value: '$dueNowCount',
          detail: dueNowCount == 0 ? 'No live exams' : 'Ready',
          active: dueNowCount > 0,
        ),
        const SizedBox(height: 10),
        _SidebarMetricTile(
          icon: Icons.schedule_outlined,
          label: 'Upcoming',
          value: '$upcomingCount',
          detail: 'Scheduled',
          active: false,
        ),
        const SizedBox(height: 10),
        _SidebarMetricTile(
          icon: Icons.task_alt_outlined,
          label: 'Completed',
          value: '$completedCount',
          detail: 'Submitted',
          active: completedCount > 0,
        ),
        const SizedBox(height: 10),
        _SidebarMetricTile(
          icon: Icons.lock_clock_outlined,
          label: 'Closed',
          value: '$closedCount',
          detail: 'Closed',
          active: false,
        ),
        const SizedBox(height: 20),
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onStartNow,
            icon: const Icon(Icons.rocket_launch_outlined),
            label: const Text('Launch Active Exam'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onWorkstation,
            icon: const Icon(Icons.edit_location_alt_outlined),
            label: const Text('Edit Hall / Seat'),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Secure Logout'),
          ),
        ),
      ],
    );

    return GlassCard(
      padding: const EdgeInsets.all(18),
      showGlow: true,
      child: fillHeight
          ? LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: content,
                ),
              ),
            )
          : content,
    );
  }
}

class PortalHeroCard extends StatelessWidget {
  const PortalHeroCard({
    super.key,
    required this.candidateName,
    required this.regNo,
    required this.level,
    required this.photoAsset,
    required this.department,
    required this.programme,
    required this.hallDisplay,
    required this.seatDisplay,
    required this.workstationId,
    required this.workstationStatus,
    required this.networkStatus,
    required this.dueNowCount,
    required this.upcomingCount,
    required this.completedCount,
    required this.totalExams,
  });

  final String candidateName;
  final String regNo;
  final String level;
  final String photoAsset;
  final String department;
  final String programme;
  final String hallDisplay;
  final String seatDisplay;
  final String workstationId;
  final WorkstationStatus workstationStatus;
  final NetworkHealthStatus networkStatus;
  final int dueNowCount;
  final int upcomingCount;
  final int completedCount;
  final int totalExams;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final approved = workstationStatus == WorkstationStatus.whitelisted;

    return GlassCard(
      tone: approved ? GlassCardTone.primary : GlassCardTone.warning,
      showGlow: true,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 980;

              final left = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      const KsStatusChip(
                        label: 'Candidate Operations Console',
                        tone: KsStatusChipTone.accent,
                      ),
                      KsStatusChip(
                        label: approved
                            ? 'Secure Lockdown Active'
                            : 'Terminal Review Required',
                        tone: approved
                            ? KsStatusChipTone.success
                            : KsStatusChipTone.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StudentPortrait(
                        imageAsset: photoAsset,
                        candidateName: candidateName,
                        size: 94,
                        radius: 24,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              candidateName,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$regNo • $level • $programme',
                              style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.76),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              department,
                              style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.62),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    dueNowCount > 0
                        ? 'Live exam available.'
                        : 'No live exam at the moment.',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.78),
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                ],
              );

              final right = Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _HeroMetricCard(
                    label: 'Live Queue',
                    value: '$dueNowCount',
                    icon: Icons.play_circle_fill_rounded,
                    accent: KsUiTokens.success,
                  ),
                  _HeroMetricCard(
                    label: 'Scheduled',
                    value: '$upcomingCount',
                    icon: Icons.event_available_outlined,
                    accent: KsUiTokens.glow,
                  ),
                  _HeroMetricCard(
                    label: 'Recorded',
                    value: '$completedCount',
                    icon: Icons.inventory_2_outlined,
                    accent: KsUiTokens.glowSecondary,
                  ),
                  _HeroMetricCard(
                    label: 'Total Ledger',
                    value: '$totalExams',
                    icon: Icons.grid_view_rounded,
                    accent: KsUiTokens.warning,
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
                  Expanded(flex: 7, child: left),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 5,
                    child: Align(alignment: Alignment.topRight, child: right),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _TelemetryCell(
                icon: Icons.memory_rounded,
                label: 'WORKSTATION ID',
                value: workstationId,
                detail: workstationDetail(workstationStatus),
                monospace: true,
              ),
              _TelemetryCell(
                icon: Icons.gpp_good_rounded,
                label: 'SECURE LOCKDOWN',
                value: approved ? 'ACTIVE' : 'PENDING REVIEW',
                detail: approved
                    ? 'Whitelisted terminal verified for supervised use.'
                    : 'Invigilator review is required before launch.',
              ),
              _TelemetryCell(
                icon: Icons.place_outlined,
                label: 'HALL / SEAT COORDINATE',
                value: 'Hall $hallDisplay | Seat $seatDisplay',
                detail: 'Remain at this coordinate until clearance.',
              ),
              _TelemetryCell(
                icon: Icons.lan_rounded,
                label: 'NETWORK PATH',
                value: networkTelemetryLabel(networkStatus),
                detail: networkDetail(networkStatus),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ExamLifecyclePanel extends StatelessWidget {
  const ExamLifecyclePanel({
    super.key,
    required this.dueNowCount,
    required this.upcomingCount,
    required this.completedCount,
    required this.closedCount,
    required this.totalExams,
  });

  final int dueNowCount;
  final int upcomingCount;
  final int completedCount;
  final int closedCount;
  final int totalExams;

  @override
  Widget build(BuildContext context) {
    final stages = [
      _LifecycleStageData(
        label: 'Due Now',
        count: dueNowCount,
        icon: Icons.play_arrow_rounded,
        detail: dueNowCount == 0 ? 'No live sessions' : 'Launch window open',
        tone: GlassCardTone.success,
        active: dueNowCount > 0,
        ratio: totalExams == 0 ? 0 : dueNowCount / totalExams,
      ),
      _LifecycleStageData(
        label: 'Upcoming',
        count: upcomingCount,
        icon: Icons.schedule_rounded,
        detail: 'Scheduled',
        tone: GlassCardTone.primary,
        active: upcomingCount > 0,
        ratio: totalExams == 0 ? 0 : upcomingCount / totalExams,
      ),
      _LifecycleStageData(
        label: 'Completed',
        count: completedCount,
        icon: Icons.task_alt_rounded,
        detail: 'Recorded submissions',
        tone: GlassCardTone.normal,
        active: completedCount > 0,
        ratio: totalExams == 0 ? 0 : completedCount / totalExams,
      ),
      _LifecycleStageData(
        label: 'Closed',
        count: closedCount,
        icon: Icons.lock_clock_outlined,
        detail: 'Unavailable windows',
        tone: GlassCardTone.warning,
        active: closedCount > 0,
        ratio: totalExams == 0 ? 0 : closedCount / totalExams,
      ),
    ];

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Exam Lifecycle',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 960;
              if (compact) {
                return Column(
                  children: stages
                      .map(
                        (stage) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _LifecycleStageCard(stage: stage),
                        ),
                      )
                      .toList(),
                );
              }

              return Row(
                children: stages
                    .map(
                      (stage) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: stage == stages.last ? 0 : 12,
                          ),
                          child: _LifecycleStageCard(stage: stage),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SidebarMetricTile extends StatelessWidget {
  const _SidebarMetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.active,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final accent = active ? KsUiTokens.glow : Colors.white;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: active
            ? KsUiTokens.glow.withValues(alpha: 0.10)
            : Colors.white.withValues(alpha: 0.04),
        border: Border.all(
          color: active
              ? KsUiTokens.glow.withValues(alpha: 0.26)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: accent.withValues(alpha: active ? 0.18 : 0.10),
            ),
            child: Icon(icon, color: accent.withValues(alpha: 0.95)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.70),
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

class _HeroMetricCard extends StatelessWidget {
  const _HeroMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 152,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: accent.withValues(alpha: 0.14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.70),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TelemetryCell extends StatelessWidget {
  const _TelemetryCell({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    this.monospace = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: KsUiTokens.glow),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.68),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                height: 1.3,
                letterSpacing: monospace ? 0.6 : 0,
                fontFamily: monospace ? 'Courier New' : null,
                fontFamilyFallback: monospace
                    ? const ['Consolas', 'monospace']
                    : null,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              detail,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.68),
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LifecycleStageCard extends StatelessWidget {
  const _LifecycleStageCard({required this.stage});

  final _LifecycleStageData stage;

  @override
  Widget build(BuildContext context) {
    final accent = accentColorForTone(stage.tone);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: stage.active
            ? accent.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.04),
        border: Border.all(
          color: stage.active
              ? accent.withValues(alpha: 0.28)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: accent.withValues(alpha: 0.16),
                ),
                child: Icon(stage.icon, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stage.label,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      stage.detail,
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.68),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${stage.count}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: stage.ratio.clamp(0.0, 1.0),
              minHeight: 8,
              color: accent,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileFieldLabel extends StatelessWidget {
  const _ProfileFieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.62),
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _ProfileFieldRow extends StatelessWidget {
  const _ProfileFieldRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 58,
          child: Text(
            label,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.62),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, height: 1.35),
          ),
        ),
      ],
    );
  }
}

class StudentPortrait extends StatelessWidget {
  const StudentPortrait({
    super.key,
    required this.imageAsset,
    required this.candidateName,
    this.size = 72,
    this.radius = 22,
  });

  final String imageAsset;
  final String candidateName;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          imageAsset,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [KsUiTokens.glow, KsUiTokens.glowSecondary],
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              initialsForName(candidateName),
              style: TextStyle(
                fontSize: size * 0.34,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF03111C),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LifecycleStageData {
  const _LifecycleStageData({
    required this.label,
    required this.count,
    required this.icon,
    required this.detail,
    required this.tone,
    required this.active,
    required this.ratio,
  });

  final String label;
  final int count;
  final IconData icon;
  final String detail;
  final GlassCardTone tone;
  final bool active;
  final double ratio;
}
