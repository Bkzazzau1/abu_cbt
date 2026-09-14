import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../data/models/center_exam_models.dart';
import '../../auth/fingerprint_reader.dart';
import '../../demo/abu_demo_theme.dart';
import '../../portal/controller/center_exam_portal_controller.dart';

class ExamFingerprintView extends StatefulWidget {
  const ExamFingerprintView({super.key, this.reader});

  final FingerprintReader? reader;

  @override
  State<ExamFingerprintView> createState() => _ExamFingerprintViewState();
}

class _ExamFingerprintViewState extends State<ExamFingerprintView> {
  late final FingerprintReader reader = widget.reader ?? DemoFingerprintReader();
  bool scanning = false;
  FingerprintResult? result;

  CenterExam? get exam {
    final arg = Get.arguments;
    if (arg is CenterExam) return arg;
    if (arg is Map && arg['exam'] is CenterExam) {
      return arg['exam'] as CenterExam;
    }
    return null;
  }

  Future<void> scanAndOpenExam() async {
    if (scanning) return;
    final currentExam = exam;
    final portal = Get.isRegistered<CenterExamPortalController>()
        ? Get.find<CenterExamPortalController>()
        : null;
    final candidate = portal?.candidate.value;
    if (currentExam == null || candidate == null) return;

    setState(() {
      scanning = true;
      result = null;
    });

    FingerprintResult outcome;
    try {
      outcome = await reader.verify(candidate.registrationNumber);
    } catch (_) {
      outcome = FingerprintResult.unavailable;
    }

    if (!mounted) return;
    setState(() {
      scanning = false;
      result = outcome;
    });

    if (outcome == FingerprintResult.matched) {
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      Get.offNamed(Routes.centerExamRun, arguments: currentExam);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentExam = exam;
    final portal = Get.isRegistered<CenterExamPortalController>()
        ? Get.find<CenterExamPortalController>()
        : null;
    final candidate = portal?.candidate.value;

    return Theme(
      data: abuDemoTheme(),
      child: Scaffold(
        backgroundColor: abuCanvas,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/senate.png', fit: BoxFit.cover),
            Container(color: abuCanvas.withValues(alpha: 0.90)),
            SafeArea(
              child: Column(
                children: [
                  _Header(
                    courseCode: currentExam?.courseCode ?? 'Examination',
                    onBack: scanning ? null : () => Get.back(),
                  ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: currentExam == null || candidate == null
                              ? _MissingSession(
                                  onReturn: () =>
                                      Get.offAllNamed(Routes.centerPortal),
                                )
                              : _FingerprintCard(
                                  exam: currentExam,
                                  candidateName: candidate.fullName,
                                  registrationNumber:
                                      candidate.registrationNumber,
                                  department: candidate.department,
                                  level: candidate.level,
                                  scanning: scanning,
                                  result: result,
                                  onScan: scanAndOpenExam,
                                ),
                        ),
                      ),
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

class _Header extends StatelessWidget {
  const _Header({required this.courseCode, required this.onBack});

  final String courseCode;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: abuLine)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 6),
          Image.asset('assets/abulogo.png', width: 40, height: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ahmadu Bello University, Zaria',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  '$courseCode · FINGERPRINT AUTHENTICATION',
                  style: const TextStyle(
                    color: abuMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
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

class _FingerprintCard extends StatelessWidget {
  const _FingerprintCard({
    required this.exam,
    required this.candidateName,
    required this.registrationNumber,
    required this.department,
    required this.level,
    required this.scanning,
    required this.result,
    required this.onScan,
  });

  final CenterExam exam;
  final String candidateName;
  final String registrationNumber;
  final String department;
  final String level;
  final bool scanning;
  final FingerprintResult? result;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final matched = result == FingerprintResult.matched;
    final failed = result == FingerprintResult.notMatched;
    final unavailable = result == FingerprintResult.unavailable;

    final status = scanning
        ? 'Reading fingerprint…'
        : matched
        ? 'Fingerprint matched'
        : failed
        ? 'Fingerprint did not match'
        : unavailable
        ? 'Fingerprint reader unavailable'
        : 'Place your finger on the reader';

    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: abuLine),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'FINGERPRINT AUTHENTICATION',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: abuGreen,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.7,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: abuCanvas,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: abuLine),
            ),
            child: Column(
              children: [
                _Detail('Candidate', candidateName),
                _Detail('Registration number', registrationNumber),
                _Detail('Department / Level', '$department · $level'),
                _Detail('Examination', '${exam.courseCode} · ${exam.courseTitle}'),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: matched
                    ? const Color(0xFFE8F2EB)
                    : failed || unavailable
                    ? const Color(0xFFFFECE9)
                    : const Color(0xFFEDF4EC),
                shape: BoxShape.circle,
              ),
              child: Icon(
                matched
                    ? Icons.check_circle_outline_rounded
                    : failed
                    ? Icons.error_outline_rounded
                    : unavailable
                    ? Icons.sensors_off_rounded
                    : Icons.fingerprint_rounded,
                color: matched
                    ? abuGreen
                    : failed || unavailable
                    ? const Color(0xFFB33D35)
                    : abuGreen,
                size: 84,
              ),
            ),
          ),
          const SizedBox(height: 22),
          if (scanning) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 16),
          ],
          Semantics(
            liveRegion: true,
            child: Text(
              status,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: failed || unavailable
                    ? const Color(0xFFB33D35)
                    : abuInk,
                fontSize: 13,
                fontWeight: matched ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: scanning || matched ? null : onScan,
            icon: const Icon(Icons.fingerprint_rounded),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Text(
                scanning
                    ? 'AUTHENTICATING…'
                    : result == null
                    ? 'AUTHENTICATE'
                    : 'RETRY',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(color: abuMuted, fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: abuInk,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissingSession extends StatelessWidget {
  const _MissingSession({required this.onReturn});

  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: abuLine),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_outline_rounded, color: abuMuted, size: 42),
          const SizedBox(height: 14),
          const Text(
            'Examination session unavailable',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: onReturn,
            child: const Text('Return to dashboard'),
          ),
        ],
      ),
    );
  }
}
