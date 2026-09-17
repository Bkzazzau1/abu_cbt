import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/glass_card.dart' show GlassCardTone;
import '../../../core/widgets/ks_page_shell.dart';
import '../../../core/widgets/ks_status_chip.dart';
import '../../../data/models/exam_session_models.dart';
import '../controller/exam_session_dashboard_controller.dart';
import '../widgets/invigilator_light_panel.dart';
import '../widgets/invigilator_light_scaffold.dart';
import '../widgets/invigilator_top_actions.dart';

class ExamSessionDashboardView extends GetView<ExamSessionDashboardController> {
  const ExamSessionDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InvigilatorLightScaffold(
      title: 'Exam Session',
      actions: buildInvigilatorTopActions(
        showSession: false,
        showSeatMap: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final session = controller.session.value;
        if (session == null) {
          return const Center(child: Text('No exam session found.'));
        }

        return ListView(
          children: [
            _SessionCard(session: session),
            const SizedBox(height: 16),
            _MetricsGrid(session: session),
            const SizedBox(height: 16),
            KsPageSection(
              title: 'Session Controls',
              subtitle: 'Manage the examination lifecycle for the active hall.',
              child: LightPanel(
                tone: GlassCardTone.primary,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: session.state == ExamSessionState.notStarted
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
              ),
            ),
            const SizedBox(height: 16),
            LightPanel(
              tone: GlassCardTone.warning,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: cs.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Use the navigation above for Attendance, Live Hall, Seat Map, and Technical Support. Session controls remain here so the page stays focused on exam-level operations.',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.76),
                        fontWeight: FontWeight.w700,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});

  final ExamSessionSummary session;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return LightPanel(
      tone: GlassCardTone.primary,
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 820;

          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KsStatusChip(
                label: _stateLabel(session.state),
                tone: _stateTone(session.state),
              ),
              const SizedBox(height: 12),
              Text(
                session.examTitle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                '${session.courseCode} • ${session.hallName}',
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${session.dateLabel} • ${session.startTime} - ${session.endTime}',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.68),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          );

          final progress = Wrap(
            spacing: 10,
            runSpacing: 10,
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
              children: [details, const SizedBox(height: 16), progress],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 3, child: details),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: Align(alignment: Alignment.centerRight, child: progress),
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
      spacing: 12,
      runSpacing: 12,
      children: [
        LightStatCard(
          title: 'Total Candidates',
          value: '${session.totalCandidates}',
          icon: Icons.groups_outlined,
          width: 205,
        ),
        LightStatCard(
          title: 'Checked In',
          value: '${session.checkedInCount}',
          icon: Icons.badge_outlined,
          width: 205,
        ),
        LightStatCard(
          title: 'In Exam',
          value: '${session.inExamCount}',
          icon: Icons.task_alt_outlined,
          width: 205,
        ),
        LightStatCard(
          title: 'Submitted',
          value: '${session.submittedCount}',
          icon: Icons.done_all_outlined,
          width: 205,
        ),
        LightStatCard(
          title: 'Offline',
          value: '${session.offlineCount}',
          icon: Icons.cloud_off_outlined,
          width: 205,
        ),
        LightStatCard(
          title: 'Reported',
          value: '${session.incidentCount + session.malpracticeCount}',
          icon: Icons.report_problem_outlined,
          width: 205,
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

    return Container(
      width: 142,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              color: cs.primary.withValues(alpha: 0.10),
            ),
            child: Icon(icon, color: cs.primary, size: 20),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.66),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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
