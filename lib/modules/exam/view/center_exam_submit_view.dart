import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../data/models/center_exam_models.dart';
import '../../demo/abu_demo_theme.dart';

class CenterExamSubmitView extends StatelessWidget {
  const CenterExamSubmitView({super.key});

  Map<String, dynamic> _payload() {
    final arg = Get.arguments;
    return (arg is Map<String, dynamic>) ? arg : <String, dynamic>{};
  }

  int? _readInt(Map<String, dynamic> payload, String key) {
    final value = payload[key];
    return value is int ? value : null;
  }

  String _formatDateTime(DateTime dt) {
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final hour12 = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final hour = hour12.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$dd/$mm/${dt.year} • $hour:$min $ampm';
  }

  String _submissionId(DateTime submittedAt) {
    final stamp = submittedAt.millisecondsSinceEpoch.toString();
    final suffix = stamp.length > 7 ? stamp.substring(stamp.length - 7) : stamp;
    return 'TXN-$suffix';
  }

  @override
  Widget build(BuildContext context) {
    final payload = _payload();

    final exam = payload['exam'] is CenterExam
        ? payload['exam'] as CenterExam
        : null;
    final score = _readInt(payload, 'score');
    final totalQuestions = _readInt(payload, 'totalQuestions');
    final totalPossibleAutoScore = _readInt(payload, 'totalPossibleAutoScore');
    final totalPossibleScore = _readInt(payload, 'totalPossibleScore');
    final needsReview = payload['needsReview'] == true;
    final manualReviewCount = _readInt(payload, 'manualReviewCount') ?? 0;
    final autoSubmitted = payload['autoSubmitted'] == true;
    final queuedForSync = payload['queuedForSync'] == true;
    final workstationId = (payload['workstationId'] ?? '').toString();
    final workstationStatus = (payload['workstationStatus'] ?? '').toString();
    final centerName = (payload['centerName'] ?? '').toString();
    final hallName = (payload['hallName'] ?? '').toString();
    final seatNumber = (payload['seatNumber'] ?? '').toString();
    final riskFlagged = payload['riskFlagged'] == true;
    final riskReasons =
        (payload['riskReasons'] as List<dynamic>? ?? const <dynamic>[])
            .map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toList();
    final isNewWorkstation = payload['isNewWorkstation'] == true;
    final clientIpAddress = (payload['clientIpAddress'] ?? '').toString();
    final expectedHallIpRange = (payload['expectedHallIpRange'] ?? '')
        .toString();
    final ipInExpectedRange = payload['ipInExpectedRange'] != false;
    final riskScore = _readInt(payload, 'riskScore') ?? 0;
    final riskLevel = (payload['riskLevel'] ?? 'low').toString();
    final workstationApproved = payload['workstationApproved'] == true;
    final submittedAt = payload['submittedAt'] is DateTime
        ? payload['submittedAt'] as DateTime
        : DateTime.now();

    final autoScoreText = switch ((
      score,
      totalPossibleAutoScore,
      totalQuestions,
    )) {
      (int s, int possible, _) => '$s / $possible',
      (int s, null, int total) => '$s / $total',
      _ => '--',
    };

    return Theme(
      data: abuDemoTheme(),
      child: Scaffold(
        backgroundColor: abuCanvas,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/senate.png', fit: BoxFit.cover),
            Container(color: abuCanvas.withValues(alpha: 0.55)),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Image.asset('assets/abulogo.png', height: 56),
                        ),
                        const SizedBox(height: 16),
                        _Card(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEDF4EC),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_circle_outline,
                                  color: abuGreen,
                                  size: 44,
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'Submission Recorded',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                autoSubmitted
                                    ? 'System auto-submitted due to time expiration.'
                                    : 'Your responses have been successfully logged.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: abuMuted,
                                  fontWeight: FontWeight.w600,
                                  height: 1.5,
                                ),
                              ),
                              if (queuedForSync) ...[
                                const SizedBox(height: 14),
                                _NoticeBox(
                                  icon: Icons.cloud_off_rounded,
                                  text:
                                      'Submission is pending sync. Do not close this window until invigilator clearance.',
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: _StatusBox(
                                label: 'Auto Score',
                                value: autoScoreText,
                                icon: Icons.analytics_outlined,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _StatusBox(
                                label: 'Sync Status',
                                value: queuedForSync ? 'Pending' : 'Completed',
                                icon: queuedForSync
                                    ? Icons.cloud_off_rounded
                                    : Icons.cloud_done_rounded,
                                color: queuedForSync
                                    ? const Color(0xFFB07500)
                                    : abuGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _Card(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'OFFICIAL TRANSCRIPT DATA',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  letterSpacing: 1,
                                  color: abuGreen,
                                ),
                              ),
                              const Divider(height: 28, color: abuLine),
                              _InfoRow(
                                'Course',
                                exam == null
                                    ? '--'
                                    : '${exam.courseCode} • ${exam.courseTitle}',
                              ),
                              _InfoRow(
                                'Submission ID',
                                _submissionId(submittedAt),
                              ),
                              _InfoRow(
                                'Timestamp',
                                _formatDateTime(submittedAt),
                              ),
                              _InfoRow(
                                'Workstation ID',
                                workstationId.isEmpty ? '--' : workstationId,
                              ),
                              _InfoRow(
                                'Workstation Status',
                                workstationStatus.isEmpty
                                    ? '--'
                                    : workstationStatus,
                              ),
                              _InfoRow(
                                'Center',
                                centerName.isEmpty ? '--' : centerName,
                              ),
                              _InfoRow(
                                'Hall',
                                hallName.isEmpty ? '--' : hallName,
                              ),
                              _InfoRow(
                                'Seat',
                                seatNumber.isEmpty ? '--' : seatNumber,
                              ),
                              _InfoRow(
                                'Client IP',
                                clientIpAddress.isEmpty
                                    ? '--'
                                    : clientIpAddress,
                              ),
                              _InfoRow(
                                'Workstation Approved',
                                workstationApproved ? 'Yes' : 'No',
                                isWarning: !workstationApproved,
                              ),
                              _InfoRow(
                                'Risk Severity',
                                '${riskLevel.toUpperCase()} ($riskScore%)',
                                isWarning: riskFlagged,
                              ),
                              if (totalPossibleScore != null)
                                _InfoRow(
                                  'Total Possible Score',
                                  '$totalPossibleScore',
                                ),
                              if (needsReview)
                                _InfoRow(
                                  'Manual Review',
                                  '$manualReviewCount items pending',
                                  isWarning: true,
                                ),
                            ],
                          ),
                        ),
                        if (riskFlagged) ...[
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFF59E0B,
                              ).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(
                                  0xFFF59E0B,
                                ).withValues(alpha: 0.35),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.gpp_bad_outlined,
                                      color: Color(0xFFB07500),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Risk Flagged Submission',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Submission was accepted, but flagged for invigilator review.',
                                  style: TextStyle(
                                    color: abuInk,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (isNewWorkstation)
                                      const _RiskChip(label: 'New Workstation'),
                                    _RiskChip(
                                      label:
                                          'IP ${ipInExpectedRange ? "In Range" : "Out of Range"}',
                                    ),
                                  ],
                                ),
                                if (clientIpAddress.isNotEmpty ||
                                    expectedHallIpRange.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'IP: ${clientIpAddress.isEmpty ? "-" : clientIpAddress} • '
                                    'Expected: ${expectedHallIpRange.isEmpty ? "Unconfigured" : expectedHallIpRange}',
                                    style: const TextStyle(
                                      color: abuInk,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                                if (riskReasons.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  ...riskReasons.map(
                                    (reason) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        '• $reason',
                                        style: const TextStyle(
                                          color: abuInk,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        _NoticeBox(
                          icon: Icons.pan_tool_rounded,
                          text:
                              'Do not close this window. Signal an invigilator for final clearance before leaving.',
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () => Get.offAllNamed(Routes.demo),
                          icon: const Icon(Icons.dashboard_outlined),
                          label: const Text('RETURN TO PORTAL'),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () => Get.offAllNamed(Routes.demo),
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Return to demo workspace'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, required this.padding});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: abuLine),
    ),
    child: Padding(padding: padding, child: child),
  );
}

class _NoticeBox extends StatelessWidget {
  const _NoticeBox({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF59E0B).withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.32),
      ),
    ),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFFB07500)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFFB07500),
            ),
          ),
        ),
      ],
    ),
  );
}

class _StatusBox extends StatelessWidget {
  const _StatusBox({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: color ?? abuGreen, size: 26),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: abuMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value, {this.isWarning = false});

  final String label;
  final String value;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: abuMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isWarning ? const Color(0xFFB07500) : abuInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskChip extends StatelessWidget {
  const _RiskChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFFFFE8BF),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF8A5A00),
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}
