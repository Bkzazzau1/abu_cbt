import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/center_exam_models.dart';
import '../../auth/demo_auth.dart';
import '../../demo/abu_demo_theme.dart';

class OfficialExamSubmitView extends StatelessWidget {
  const OfficialExamSubmitView({super.key});

  Map<String, dynamic> _payload() {
    final arg = Get.arguments;
    return arg is Map<String, dynamic> ? arg : <String, dynamic>{};
  }

  String _submissionId(DateTime submittedAt) {
    final stamp = submittedAt.millisecondsSinceEpoch.toString();
    final suffix = stamp.length > 7 ? stamp.substring(stamp.length - 7) : stamp;
    return 'ABU-CBT-$suffix';
  }

  String _formatDateTime(DateTime value) {
    final dd = value.day.toString().padLeft(2, '0');
    final mm = value.month.toString().padLeft(2, '0');
    final hh = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${value.year}  $hh:$min';
  }

  @override
  Widget build(BuildContext context) {
    final payload = _payload();
    final exam = payload['exam'] is CenterExam ? payload['exam'] as CenterExam : null;
    final submittedAt = payload['submittedAt'] is DateTime
        ? payload['submittedAt'] as DateTime
        : DateTime.now();
    final queuedForSync = payload['queuedForSync'] == true;
    final autoSubmitted = payload['autoSubmitted'] == true;
    final workstationId = (payload['workstationId'] ?? '').toString();
    final hallName = (payload['hallName'] ?? '').toString();
    final seatNumber = (payload['seatNumber'] ?? '').toString();

    return Theme(
      data: abuDemoTheme(),
      child: Scaffold(
        backgroundColor: abuCanvas,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/senate.png', fit: BoxFit.cover),
            Container(color: abuCanvas.withValues(alpha: 0.88)),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(child: Image.asset('assets/abulogo.png', height: 62)),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: abuLine),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x10000000),
                                blurRadius: 26,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEAF3EC),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: abuGreen,
                                  size: 48,
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'EXAMINATION SUBMITTED',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: abuGreen,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.8,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Your submission has been recorded',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: abuInk,
                                  fontSize: 25,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                autoSubmitted
                                    ? 'The examination was submitted automatically when the authorised time expired.'
                                    : 'Your examination responses have been received by the CBT system.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: abuMuted,
                                  fontSize: 12,
                                  height: 1.6,
                                ),
                              ),
                              const SizedBox(height: 26),
                              const Divider(color: abuLine),
                              const SizedBox(height: 10),
                              _ReceiptRow(
                                'Course',
                                exam == null ? '--' : '${exam.courseCode} · ${exam.courseTitle}',
                              ),
                              _ReceiptRow('Submission ID', _submissionId(submittedAt)),
                              _ReceiptRow('Submitted at', _formatDateTime(submittedAt)),
                              _ReceiptRow(
                                'Sync status',
                                queuedForSync ? 'Pending secure sync' : 'Recorded',
                                warning: queuedForSync,
                              ),
                              if (hallName.isNotEmpty) _ReceiptRow('Hall', hallName),
                              if (seatNumber.isNotEmpty) _ReceiptRow('Seat', seatNumber),
                              if (workstationId.isNotEmpty)
                                _ReceiptRow('Workstation', workstationId),
                              const SizedBox(height: 20),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: queuedForSync
                                      ? const Color(0xFFFFF4E6)
                                      : const Color(0xFFEEF4EF),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: queuedForSync
                                        ? const Color(0xFFF1D3A7)
                                        : const Color(0xFFD7E4D8),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      queuedForSync
                                          ? Icons.cloud_off_outlined
                                          : Icons.pan_tool_alt_outlined,
                                      color: queuedForSync
                                          ? const Color(0xFF9A650F)
                                          : abuGreen,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        queuedForSync
                                            ? 'Do not close this workstation. Your submission is waiting for secure synchronisation. Signal the invigilator.'
                                            : 'Remain at your workstation and signal the invigilator for final clearance before leaving the examination hall.',
                                        style: TextStyle(
                                          color: queuedForSync
                                              ? const Color(0xFF7A5319)
                                              : abuInk,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          height: 1.55,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Examination results are released through the authorised university result process. Scores are not displayed on this workstation after submission.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: abuMuted, fontSize: 11, height: 1.6),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: DemoAuth.instance.signOut,
                            icon: const Icon(Icons.logout_rounded),
                            label: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text('END CANDIDATE SESSION'),
                            ),
                          ),
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

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow(this.label, this.value, {this.warning = false});

  final String label;
  final String value;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: abuMuted, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: warning ? const Color(0xFF9A650F) : abuInk,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
