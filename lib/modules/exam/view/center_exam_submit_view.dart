import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/ks_page_shell.dart';
import '../../../data/models/center_exam_models.dart';

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
    final cs = Theme.of(context).colorScheme;

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

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: KsPageShell(
        padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
        maxContentWidth: 860,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              GlassCard(
                tone: GlassCardTone.success,
                showGlow: true,
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF22C55E),
                      size: 80,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Submission Recorded',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      autoSubmitted
                          ? 'System auto-submitted due to time expiration.'
                          : 'Your responses have been successfully logged.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (queuedForSync) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFF59E0B,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(
                              0xFFF59E0B,
                            ).withValues(alpha: 0.32),
                          ),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.cloud_off_rounded,
                              color: Color(0xFFF59E0B),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Submission is pending sync. Do not close this window until invigilator clearance.',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFF59E0B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _StatusBox(
                      label: 'Auto Score',
                      value: autoScoreText,
                      icon: Icons.analytics_outlined,
                      cs: cs,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatusBox(
                      label: 'Sync Status',
                      value: queuedForSync ? 'Pending' : 'Completed',
                      icon: queuedForSync
                          ? Icons.cloud_off_rounded
                          : Icons.cloud_done_rounded,
                      color: queuedForSync
                          ? const Color(0xFFF59E0B)
                          : cs.primary,
                      cs: cs,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GlassCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'OFFICIAL TRANSCRIPT DATA',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const Divider(height: 32),
                    _InfoRow(
                      'Course',
                      exam == null
                          ? '--'
                          : '${exam.courseCode} • ${exam.courseTitle}',
                    ),
                    _InfoRow('Submission ID', _submissionId(submittedAt)),
                    _InfoRow('Timestamp', _formatDateTime(submittedAt)),
                    _InfoRow(
                      'Workstation ID',
                      workstationId.isEmpty ? '--' : workstationId,
                    ),
                    _InfoRow(
                      'Workstation Status',
                      workstationStatus.isEmpty ? '--' : workstationStatus,
                    ),
                    _InfoRow('Center', centerName.isEmpty ? '--' : centerName),
                    _InfoRow('Hall', hallName.isEmpty ? '--' : hallName),
                    _InfoRow('Seat', seatNumber.isEmpty ? '--' : seatNumber),
                    _InfoRow(
                      'Client IP',
                      clientIpAddress.isEmpty ? '--' : clientIpAddress,
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
                      _InfoRow('Total Possible Score', '$totalPossibleScore'),
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
                const SizedBox(height: 20),
                GlassCard(
                  tone: GlassCardTone.warning,
                  showGlow: true,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.gpp_bad_outlined,
                            color: Color(0xFFF59E0B),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Risk Flagged Submission',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Submission was accepted, but flagged for invigilator review.',
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.76),
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
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.82),
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
                              style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.84),
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
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.30),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.pan_tool_rounded, color: Color(0xFFF59E0B)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Do not close this window. Signal an invigilator for final clearance before leaving.',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Get.offAllNamed(Routes.demo),
                  icon: const Icon(Icons.dashboard_outlined),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(20),
                  ),
                  label: const Text(
                    'RETURN TO PORTAL',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Get.offAllNamed(Routes.demo),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Return to demo workspace'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBox extends StatelessWidget {
  const _StatusBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.cs,
    this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final ColorScheme cs;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: color ?? cs.primary, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
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
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.65),
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isWarning ? const Color(0xFFF59E0B) : null,
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
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
