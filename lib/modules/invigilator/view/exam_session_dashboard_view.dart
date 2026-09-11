import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/ks_page_shell.dart';
import '../../../core/widgets/ks_stat_card.dart';
import '../../../core/widgets/ks_status_chip.dart';
import '../../../data/models/exam_session_models.dart';
import '../controller/exam_session_dashboard_controller.dart';
import '../widgets/invigilator_top_actions.dart';

class ExamSessionDashboardView extends GetView<ExamSessionDashboardController> {
  const ExamSessionDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Session Dashboard'),
        backgroundColor: Colors.transparent,
        actions: buildInvigilatorTopActions(
          showSession: false,
          showSeatMap: true,
        ),
      ),
      extendBodyBehindAppBar: true,
      body: KsPageShell(
        padding: const EdgeInsets.fromLTRB(20, 92, 20, 20),
        maxContentWidth: 1480,
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final session = controller.session.value;
          if (session == null) {
            return const Center(child: Text('No exam session found.'));
          }

          return ListView(
            children: [
              _HeroCard(session: session),
              const SizedBox(height: 18),
              _MetricsGrid(session: session),
              const SizedBox(height: 18),
              KsPageSection(
                title: 'Session Controls',
                subtitle:
                    'Manage the examination lifecycle for the active hall.',
                child: GlassCard(
                  tone: GlassCardTone.primary,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.icon(
                            onPressed:
                                session.state == ExamSessionState.notStarted
                                ? controller.startSession
                                : null,
                            icon: const Icon(Icons.play_circle_outline),
                            label: const Text('Start Session'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: session.state == ExamSessionState.running
                                ? controller.pauseSession
                                : null,
                            icon: const Icon(Icons.pause_circle_outline),
                            label: const Text('Pause Session'),
                          ),
                          OutlinedButton.icon(
                            onPressed: session.state == ExamSessionState.paused
                                ? controller.resumeSession
                                : null,
                            icon: const Icon(Icons.restart_alt_outlined),
                            label: const Text('Resume Session'),
                          ),
                          OutlinedButton.icon(
                            onPressed: session.state == ExamSessionState.closed
                                ? null
                                : controller.closeSession,
                            icon: const Icon(Icons.stop_circle_outlined),
                            label: const Text('Close Session'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              KsPageSection(
                title: 'Quick Navigation',
                subtitle: 'Move quickly between the major invigilation tools.',
                child: GlassCard(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => Get.toNamed(Routes.attendanceRegister),
                        icon: const Icon(Icons.fact_check_outlined),
                        label: const Text('Attendance Register'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => Get.toNamed(Routes.hallMonitoring),
                        icon: const Icon(Icons.monitor_outlined),
                        label: const Text('Live Monitoring'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => Get.toNamed(Routes.seatMap),
                        icon: const Icon(Icons.grid_view_outlined),
                        label: const Text('Seat Map'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () =>
                            Get.toNamed(Routes.invigilatorDashboard),
                        icon: const Icon(Icons.computer_outlined),
                        label: const Text('Workstations'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              GlassCard(
                tone: GlassCardTone.warning,
                child: Text(
                  'This dashboard provides a live operational overview of attendance, exam progress, offline conditions, incident handling, and malpractice visibility within the active hall.',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.session});

  final ExamSessionSummary session;

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
                label: _stateLabel(session.state),
                tone: _stateTone(session.state),
              ),
              const SizedBox(height: 14),
              Text(
                session.examTitle,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${session.courseCode} • ${session.hallName}',
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${session.dateLabel} • ${session.startTime} - ${session.endTime}',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Monitor hall readiness, candidate progress, submission rate, incident activity, and operational status from a single control surface.',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.76),
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
              _MiniMetric(
                label: 'Candidates',
                value: '${session.totalCandidates}',
                icon: Icons.groups_outlined,
              ),
              _MiniMetric(
                label: 'In Exam',
                value: '${session.inExamCount}',
                icon: Icons.task_alt_outlined,
              ),
              _MiniMetric(
                label: 'Submitted',
                value: '${session.submittedCount}',
                icon: Icons.done_all_outlined,
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
              const SizedBox(width: 18),
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

  String _stateLabel(ExamSessionState state) {
    switch (state) {
      case ExamSessionState.notStarted:
        return 'Not Started';
      case ExamSessionState.running:
        return 'Running';
      case ExamSessionState.paused:
        return 'Paused';
      case ExamSessionState.closed:
        return 'Closed';
    }
  }

  KsStatusChipTone _stateTone(ExamSessionState state) {
    switch (state) {
      case ExamSessionState.notStarted:
        return KsStatusChipTone.neutral;
      case ExamSessionState.running:
        return KsStatusChipTone.success;
      case ExamSessionState.paused:
        return KsStatusChipTone.warning;
      case ExamSessionState.closed:
        return KsStatusChipTone.danger;
    }
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.session});

  final ExamSessionSummary session;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        KsStatCard(
          title: 'Total Candidates',
          value: '${session.totalCandidates}',
          icon: Icons.groups_outlined,
          width: 220,
        ),
        KsStatCard(
          title: 'Checked In',
          value: '${session.checkedInCount}',
          icon: Icons.badge_outlined,
          width: 220,
        ),
        KsStatCard(
          title: 'Authorized',
          value: '${session.authorizedCount}',
          icon: Icons.verified_user_outlined,
          width: 220,
        ),
        KsStatCard(
          title: 'In Exam',
          value: '${session.inExamCount}',
          icon: Icons.task_alt_outlined,
          width: 220,
        ),
        KsStatCard(
          title: 'Submitted',
          value: '${session.submittedCount}',
          icon: Icons.done_all_outlined,
          width: 220,
        ),
        KsStatCard(
          title: 'Offline',
          value: '${session.offlineCount}',
          icon: Icons.cloud_off_outlined,
          width: 220,
        ),
        KsStatCard(
          title: 'Incidents',
          value: '${session.incidentCount}',
          icon: Icons.report_problem_outlined,
          width: 220,
        ),
        KsStatCard(
          title: 'Malpractice',
          value: '${session.malpracticeCount}',
          icon: Icons.gpp_bad_outlined,
          width: 220,
        ),
      ],
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: SizedBox(
        width: 155,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: cs.primary.withValues(alpha: 0.12),
              ),
              child: Icon(icon, color: cs.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    label,
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
      ),
    );
  }
}
