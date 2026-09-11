import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/ks_ui_tokens.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/ks_status_chip.dart';
import '../../../data/models/center_exam_models.dart';
import '../../../data/models/workstation_models.dart';

String initialsForName(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'KS';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}

String labelForStatus(CenterExamStatus status) {
  switch (status) {
    case CenterExamStatus.dueNow:
      return 'Due Now';
    case CenterExamStatus.upcoming:
      return 'Upcoming';
    case CenterExamStatus.completed:
      return 'Completed';
    case CenterExamStatus.closed:
      return 'Closed';
  }
}

String actionLabelForStatus(CenterExamStatus status) {
  switch (status) {
    case CenterExamStatus.dueNow:
      return 'Start Exam';
    case CenterExamStatus.upcoming:
      return 'Await Opening';
    case CenterExamStatus.completed:
      return 'Recorded';
    case CenterExamStatus.closed:
      return 'Window Closed';
  }
}

KsStatusChipTone chipToneForStatus(CenterExamStatus status) {
  switch (status) {
    case CenterExamStatus.dueNow:
      return KsStatusChipTone.success;
    case CenterExamStatus.upcoming:
      return KsStatusChipTone.info;
    case CenterExamStatus.completed:
      return KsStatusChipTone.accent;
    case CenterExamStatus.closed:
      return KsStatusChipTone.warningSoft;
  }
}

GlassCardTone glassToneForExamStatus(CenterExamStatus status) {
  switch (status) {
    case CenterExamStatus.dueNow:
      return GlassCardTone.success;
    case CenterExamStatus.upcoming:
      return GlassCardTone.primary;
    case CenterExamStatus.completed:
      return GlassCardTone.normal;
    case CenterExamStatus.closed:
      return GlassCardTone.warning;
  }
}

Color accentColorForExamStatus(CenterExamStatus status) {
  switch (status) {
    case CenterExamStatus.dueNow:
      return KsUiTokens.success;
    case CenterExamStatus.upcoming:
      return KsUiTokens.glow;
    case CenterExamStatus.completed:
      return KsUiTokens.glowSecondary;
    case CenterExamStatus.closed:
      return KsUiTokens.warning;
  }
}

Color accentColorForTone(GlassCardTone tone) {
  switch (tone) {
    case GlassCardTone.primary:
      return KsUiTokens.glow;
    case GlassCardTone.danger:
      return KsUiTokens.danger;
    case GlassCardTone.success:
      return KsUiTokens.success;
    case GlassCardTone.warning:
      return KsUiTokens.warning;
    case GlassCardTone.normal:
      return KsUiTokens.glowSecondary;
  }
}

String networkLabel(NetworkHealthStatus status) {
  switch (status) {
    case NetworkHealthStatus.online:
      return 'Network Stable';
    case NetworkHealthStatus.lowNetwork:
      return 'Low Network';
    case NetworkHealthStatus.offline:
      return 'Offline';
  }
}

String networkTelemetryLabel(NetworkHealthStatus status) {
  switch (status) {
    case NetworkHealthStatus.online:
      return 'LAN STABLE';
    case NetworkHealthStatus.lowNetwork:
      return 'LOW BANDWIDTH';
    case NetworkHealthStatus.offline:
      return 'OFFLINE';
  }
}

String networkDetail(NetworkHealthStatus status) {
  switch (status) {
    case NetworkHealthStatus.online:
      return 'Heartbeat path looks stable for secure exam delivery.';
    case NetworkHealthStatus.lowNetwork:
      return 'Network is reachable but degraded. Keep the portal in focus.';
    case NetworkHealthStatus.offline:
      return 'Network is unavailable. Inform the invigilator before launch.';
  }
}

KsStatusChipTone networkTone(NetworkHealthStatus status) {
  switch (status) {
    case NetworkHealthStatus.online:
      return KsStatusChipTone.success;
    case NetworkHealthStatus.lowNetwork:
      return KsStatusChipTone.warning;
    case NetworkHealthStatus.offline:
      return KsStatusChipTone.danger;
  }
}

String workstationLabel(WorkstationStatus status) {
  switch (status) {
    case WorkstationStatus.pending:
      return 'Pending Approval';
    case WorkstationStatus.whitelisted:
      return 'Whitelisted Terminal';
    case WorkstationStatus.disabled:
      return 'Disabled Terminal';
    case WorkstationStatus.revoked:
      return 'Revoked Terminal';
  }
}

String workstationDetail(WorkstationStatus status) {
  switch (status) {
    case WorkstationStatus.pending:
      return 'Awaiting invigilator approval.';
    case WorkstationStatus.whitelisted:
      return 'Approved for supervised exam delivery.';
    case WorkstationStatus.disabled:
      return 'Terminal access has been disabled.';
    case WorkstationStatus.revoked:
      return 'Terminal has been revoked from the center ledger.';
  }
}

KsStatusChipTone workstationTone(WorkstationStatus status) {
  switch (status) {
    case WorkstationStatus.pending:
      return KsStatusChipTone.warning;
    case WorkstationStatus.whitelisted:
      return KsStatusChipTone.success;
    case WorkstationStatus.disabled:
      return KsStatusChipTone.warningSoft;
    case WorkstationStatus.revoked:
      return KsStatusChipTone.danger;
  }
}

String toneLabel(KsStatusChipTone tone) {
  switch (tone) {
    case KsStatusChipTone.neutral:
      return 'Neutral';
    case KsStatusChipTone.info:
      return 'Info';
    case KsStatusChipTone.success:
      return 'Good';
    case KsStatusChipTone.warning:
      return 'Watch';
    case KsStatusChipTone.warningSoft:
      return 'Notice';
    case KsStatusChipTone.danger:
      return 'Risk';
    case KsStatusChipTone.accent:
      return 'Synced';
  }
}

double windowProgressForExam(CenterExam exam) {
  final start = parseExamDateTime(exam.dateLabel, exam.startTime);
  final end = parseExamDateTime(exam.dateLabel, exam.endTime);
  final now = DateTime.now();

  if (start != null && end != null && end.isAfter(start)) {
    final liveWindow = now.isAfter(start) && now.isBefore(end);
    if (exam.status == CenterExamStatus.dueNow && liveWindow) {
      final total = end.difference(start).inSeconds;
      final elapsed = now.difference(start).inSeconds;
      return total <= 0 ? 0.0 : elapsed / total;
    }
    if (exam.status == CenterExamStatus.upcoming && now.isBefore(start)) {
      return 0.14;
    }
    if (exam.status == CenterExamStatus.completed ||
        exam.status == CenterExamStatus.closed) {
      return 1.0;
    }
  }

  switch (exam.status) {
    case CenterExamStatus.dueNow:
      return 0.68;
    case CenterExamStatus.upcoming:
      return 0.18;
    case CenterExamStatus.completed:
      return 1.0;
    case CenterExamStatus.closed:
      return 1.0;
  }
}

String windowCaptionForExam(CenterExam exam) {
  final start = parseExamDateTime(exam.dateLabel, exam.startTime);
  final end = parseExamDateTime(exam.dateLabel, exam.endTime);
  final now = DateTime.now();

  if (start != null && end != null && end.isAfter(start)) {
    if (exam.status == CenterExamStatus.upcoming && now.isBefore(start)) {
      final diff = start.difference(now);
      if (diff.inHours >= 1) {
        return 'Opens in ${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
      }
      return 'Opens in ${diff.inMinutes} mins';
    }
    if (exam.status == CenterExamStatus.dueNow &&
        now.isAfter(start) &&
        now.isBefore(end)) {
      return '${end.difference(now).inMinutes} mins left';
    }
  }

  switch (exam.status) {
    case CenterExamStatus.dueNow:
      return 'Window live';
    case CenterExamStatus.upcoming:
      return 'Queued for opening';
    case CenterExamStatus.completed:
      return 'Submission recorded';
    case CenterExamStatus.closed:
      return 'Window expired';
  }
}

DateTime? parseExamDateTime(String dateLabel, String timeLabel) {
  final dateParts = dateLabel.split('/');
  if (dateParts.length != 3) return null;

  final day = int.tryParse(dateParts[0]);
  final month = int.tryParse(dateParts[1]);
  final year = int.tryParse(dateParts[2]);
  final timeMatch = RegExp(
    r'^(\d{1,2}):(\d{2})\s*([AP]M)$',
    caseSensitive: false,
  ).firstMatch(timeLabel.trim());

  if (day == null || month == null || year == null || timeMatch == null) {
    return null;
  }

  var hour = int.tryParse(timeMatch.group(1)!);
  final minute = int.tryParse(timeMatch.group(2)!);
  final meridiem = timeMatch.group(3)!.toUpperCase();
  if (hour == null || minute == null) return null;

  if (meridiem == 'PM' && hour != 12) {
    hour += 12;
  } else if (meridiem == 'AM' && hour == 12) {
    hour = 0;
  }

  return DateTime(year, month, day, hour, minute);
}

class HoverLift extends StatefulWidget {
  const HoverLift({
    super.key,
    required this.child,
    required this.radius,
    this.onTap,
  });

  final Widget child;
  final double radius;
  final VoidCallback? onTap;

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final interactive = widget.onTap != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(
          0,
          interactive && _hovered ? -4 : 0,
          0,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(widget.radius),
            splashColor: Get.theme.splashColor.withValues(alpha: 0.14),
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
