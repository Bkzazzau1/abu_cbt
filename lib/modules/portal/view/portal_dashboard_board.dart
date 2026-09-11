import 'package:flutter/material.dart';

import '../../../core/theme/ks_ui_tokens.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/ks_status_chip.dart';
import '../../../data/models/center_exam_models.dart';
import '../../../data/models/workstation_models.dart';
import 'portal_dashboard_shared.dart';

class ExamOperationsBoard extends StatelessWidget {
  const ExamOperationsBoard({
    super.key,
    required this.featuredExam,
    required this.secondaryExams,
    required this.upcomingExams,
    required this.completedCount,
    required this.closedCount,
    required this.dueNowCount,
    required this.totalExams,
    required this.networkStatus,
    required this.workstationStatus,
    required this.onStart,
  });

  final CenterExam? featuredExam;
  final List<CenterExam> secondaryExams;
  final List<CenterExam> upcomingExams;
  final int completedCount;
  final int closedCount;
  final int dueNowCount;
  final int totalExams;
  final NetworkHealthStatus networkStatus;
  final WorkstationStatus workstationStatus;
  final void Function(CenterExam exam) onStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Operations Board',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1120;

            final featured = featuredExam == null
                ? const _ExamEmptyStateCard(label: 'No exam available.')
                : _FeaturedExamCard(exam: featuredExam!, onStart: onStart);

            final rail = Column(
              children: [
                _OperationsSnapshotCard(
                  upcomingExams: upcomingExams,
                  dueNowCount: dueNowCount,
                  completedCount: completedCount,
                  closedCount: closedCount,
                  totalExams: totalExams,
                ),
                const SizedBox(height: 16),
                _SecurityPostureCard(
                  networkStatus: networkStatus,
                  workstationStatus: workstationStatus,
                ),
              ],
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 7, child: featured),
                      const SizedBox(width: 16),
                      Expanded(flex: 4, child: rail),
                    ],
                  )
                else ...[
                  featured,
                  const SizedBox(height: 16),
                  rail,
                ],
                if (secondaryExams.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  if (wide)
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: secondaryExams
                          .map(
                            (exam) => SizedBox(
                              width: exam.status == CenterExamStatus.dueNow
                                  ? 430
                                  : 318,
                              child: _ExamBentoCard(
                                exam: exam,
                                onStart: onStart,
                              ),
                            ),
                          )
                          .toList(),
                    )
                  else
                    Column(
                      children: secondaryExams
                          .map(
                            (exam) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _ExamBentoCard(
                                exam: exam,
                                onStart: onStart,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _FeaturedExamCard extends StatelessWidget {
  const _FeaturedExamCard({required this.exam, required this.onStart});

  final CenterExam exam;
  final void Function(CenterExam exam) onStart;

  @override
  Widget build(BuildContext context) {
    final canStart = exam.status == CenterExamStatus.dueNow;
    final progress = windowProgressForExam(exam);
    final tone = glassToneForExamStatus(exam.status);
    final accent = accentColorForExamStatus(exam.status);

    return GlassCard(
      tone: tone,
      showGlow: true,
      padding: EdgeInsets.zero,
      child: HoverLift(
        onTap: canStart ? () => onStart(exam) : null,
        radius: 24,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: 0.18),
                Colors.transparent,
                accent.withValues(alpha: 0.08),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  KsStatusChip(
                    label: labelForStatus(exam.status),
                    tone: chipToneForStatus(exam.status),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Colors.white.withValues(alpha: 0.06),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Text(
                      '${exam.questions.length} questions • ${exam.durationMinutes} mins',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                exam.courseCode,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                  color: accent.withValues(alpha: 0.94),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                exam.courseTitle,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Venue: ${exam.venue} • ${exam.dateLabel} • ${exam.startTime} - ${exam.endTime}',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.78),
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.white.withValues(alpha: 0.05),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Access Window',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.7,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          windowCaptionForExam(exam),
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        color: accent,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 760;

                  final meta = Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: const [
                      _ExamMetaPill(
                        icon: Icons.shield_outlined,
                        label: 'Secure delivery lane',
                      ),
                      _ExamMetaPill(
                        icon: Icons.touch_app_outlined,
                        label: 'Touch-optimized control flow',
                      ),
                    ],
                  );

                  final button = FilledButton.icon(
                    onPressed: canStart ? () => onStart(exam) : null,
                    icon: Icon(
                      canStart
                          ? Icons.play_arrow_rounded
                          : Icons.lock_clock_outlined,
                    ),
                    label: Text(
                      canStart ? 'Start Exam' : labelForStatus(exam.status),
                    ),
                  );

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        meta,
                        const SizedBox(height: 14),
                        SizedBox(width: double.infinity, child: button),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: meta),
                      const SizedBox(width: 16),
                      button,
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExamBentoCard extends StatelessWidget {
  const _ExamBentoCard({required this.exam, required this.onStart});

  final CenterExam exam;
  final void Function(CenterExam exam) onStart;

  @override
  Widget build(BuildContext context) {
    final canStart = exam.status == CenterExamStatus.dueNow;
    final accent = accentColorForExamStatus(exam.status);

    return GlassCard(
      tone: glassToneForExamStatus(exam.status),
      padding: EdgeInsets.zero,
      child: HoverLift(
        onTap: canStart ? () => onStart(exam) : null,
        radius: 24,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      exam.courseCode,
                      style: TextStyle(
                        color: accent.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  KsStatusChip(
                    label: labelForStatus(exam.status),
                    tone: chipToneForStatus(exam.status),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                exam.courseTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${exam.dateLabel} • ${exam.startTime} - ${exam.endTime}',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.76),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                exam.venue,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.66),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Access window',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.70),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: windowProgressForExam(exam),
                  minHeight: 8,
                  color: accent,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                windowCaptionForExam(exam),
                style: TextStyle(color: accent, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: canStart ? () => onStart(exam) : null,
                  child: Text(
                    canStart ? 'Start Exam' : actionLabelForStatus(exam.status),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OperationsSnapshotCard extends StatelessWidget {
  const _OperationsSnapshotCard({
    required this.upcomingExams,
    required this.dueNowCount,
    required this.completedCount,
    required this.closedCount,
    required this.totalExams,
  });

  final List<CenterExam> upcomingExams;
  final int dueNowCount;
  final int completedCount;
  final int closedCount;
  final int totalExams;

  @override
  Widget build(BuildContext context) {
    final nextExam = upcomingExams.isEmpty ? null : upcomingExams.first;

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Queue Radar',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            nextExam == null
                ? 'No upcoming exam.'
                : 'Next: ${nextExam.courseCode} • ${nextExam.venue}',
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.72),
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniSnapshotTile(
                  label: 'Live',
                  value: '$dueNowCount',
                  accent: KsUiTokens.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniSnapshotTile(
                  label: 'Recorded',
                  value: '$completedCount',
                  accent: KsUiTokens.glowSecondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniSnapshotTile(
                  label: 'Closed',
                  value: '$closedCount',
                  accent: KsUiTokens.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withValues(alpha: 0.04),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Text(
              'Total exams: $totalExams',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityPostureCard extends StatelessWidget {
  const _SecurityPostureCard({
    required this.networkStatus,
    required this.workstationStatus,
  });

  final NetworkHealthStatus networkStatus;
  final WorkstationStatus workstationStatus;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Security Posture',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          _SecuritySignalLine(
            label: 'Network',
            value: networkTelemetryLabel(networkStatus),
            tone: networkTone(networkStatus),
          ),
          const SizedBox(height: 10),
          _SecuritySignalLine(
            label: 'Workstation',
            value: workstationDetail(workstationStatus),
            tone: workstationTone(workstationStatus),
          ),
          const SizedBox(height: 10),
          _SecuritySignalLine(
            label: 'Protocol',
            value: workstationStatus == WorkstationStatus.whitelisted
                ? 'Secure delivery channel armed'
                : 'Manual verification required',
            tone: workstationStatus == WorkstationStatus.whitelisted
                ? KsStatusChipTone.success
                : KsStatusChipTone.warning,
          ),
        ],
      ),
    );
  }
}

class _ExamEmptyStateCard extends StatelessWidget {
  const _ExamEmptyStateCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.grid_view_outlined, size: 36),
          const SizedBox(height: 14),
          Text(
            label,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _MiniSnapshotTile extends StatelessWidget {
  const _MiniSnapshotTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: accent.withValues(alpha: 0.12),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

class _SecuritySignalLine extends StatelessWidget {
  const _SecuritySignalLine({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final String value;
  final KsStatusChipTone tone;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.70),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 10),
        KsStatusChip(label: toneLabel(tone), tone: tone),
      ],
    );
  }
}

class _ExamMetaPill extends StatelessWidget {
  const _ExamMetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
