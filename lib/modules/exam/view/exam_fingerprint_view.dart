import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../data/models/center_exam_models.dart';
import '../../../data/models/manual_identity_verification_models.dart';
import '../../../data/services/manual_identity_verification_store.dart';
import '../../../data/services/workstation_service.dart';
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
  late final ManualIdentityVerificationStore reviewStore;
  Worker? reviewWorker;

  bool scanning = false;
  bool requestingReview = false;
  bool openingExam = false;
  int fingerprintAttempts = 0;
  FingerprintResult? result;
  ManualIdentityVerificationRequest? reviewRequest;

  CenterExam? get exam {
    final arg = Get.arguments;
    if (arg is CenterExam) return arg;
    if (arg is Map && arg['exam'] is CenterExam) {
      return arg['exam'] as CenterExam;
    }
    return null;
  }

  CenterExamPortalController? get portal =>
      Get.isRegistered<CenterExamPortalController>()
          ? Get.find<CenterExamPortalController>()
          : null;

  String get examTitle {
    final currentExam = exam;
    if (currentExam == null) return '';
    return '${currentExam.courseCode} - ${currentExam.courseTitle}';
  }

  @override
  void initState() {
    super.initState();
    reviewStore = Get.isRegistered<ManualIdentityVerificationStore>()
        ? Get.find<ManualIdentityVerificationStore>()
        : Get.put(ManualIdentityVerificationStore(), permanent: true);

    reviewWorker = ever(
      reviewStore.requests,
      (_) => _syncReviewStatus(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncReviewStatus();
    });
  }

  @override
  void dispose() {
    reviewWorker?.dispose();
    super.dispose();
  }

  Future<void> scanAndOpenExam() async {
    if (scanning || openingExam) return;
    final currentExam = exam;
    final candidate = portal?.candidate.value;
    if (currentExam == null || candidate == null) return;

    setState(() {
      scanning = true;
      result = null;
      fingerprintAttempts += 1;
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
      final pending = reviewStore.pendingForCandidate(
        registrationNumber: candidate.registrationNumber,
        examTitle: examTitle,
      );
      if (pending != null) {
        reviewStore.resolveByFingerprint(requestId: pending.id);
      }
      await _openExam(currentExam);
    }
  }

  Future<void> requestInvigilatorReview() async {
    if (requestingReview || scanning || openingExam) return;
    final currentExam = exam;
    final candidate = portal?.candidate.value;
    final currentResult = result;
    if (currentExam == null || candidate == null || currentResult == null) return;
    if (currentResult == FingerprintResult.matched) return;

    setState(() => requestingReview = true);
    try {
      final workstation = await WorkstationService.touchLastSeen();
      final failureReason = switch (currentResult) {
        FingerprintResult.notMatched =>
          ManualIdentityFailureReason.fingerprintNotMatched,
        FingerprintResult.unavailable =>
          ManualIdentityFailureReason.readerUnavailable,
        FingerprintResult.matched => ManualIdentityFailureReason.other,
      };

      final request = await reviewStore.requestReview(
        registrationNumber: candidate.registrationNumber,
        candidateName: candidate.fullName,
        department: candidate.department,
        level: candidate.level,
        photoAsset: candidate.photoAsset,
        examTitle: examTitle,
        hallName: workstation.hallName,
        seatNumber: workstation.seatNumber,
        workstationId: workstation.workstationId,
        failureReason: failureReason,
        fingerprintAttempts: fingerprintAttempts,
      );

      if (!mounted) return;
      setState(() => reviewRequest = request);
      Get.snackbar(
        'Invigilator review requested',
        'Remain at this workstation. An invigilator must verify your identity before the exam can open.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 6),
      );
    } finally {
      if (mounted) setState(() => requestingReview = false);
    }
  }

  void _syncReviewStatus() {
    if (!mounted) return;
    final candidate = portal?.candidate.value;
    final currentExam = exam;
    if (candidate == null || currentExam == null) return;

    final latest = reviewStore.latestForCandidate(
      registrationNumber: candidate.registrationNumber,
      examTitle: examTitle,
    );

    if (latest?.isApproved == true && !openingExam) {
      setState(() => reviewRequest = latest);
      _openExam(currentExam);
      return;
    }

    if (reviewRequest?.id != latest?.id ||
        reviewRequest?.status != latest?.status ||
        reviewRequest?.fingerprintAttempts != latest?.fingerprintAttempts) {
      setState(() => reviewRequest = latest);
    }
  }

  Future<void> _openExam(CenterExam currentExam) async {
    if (openingExam || !mounted) return;
    setState(() => openingExam = true);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    Get.offNamed(Routes.centerExamRun, arguments: currentExam);
  }

  @override
  Widget build(BuildContext context) {
    final currentExam = exam;
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
                    onBack: scanning || openingExam ? null : () => Get.back(),
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
                                  openingExam: openingExam,
                                  requestingReview: requestingReview,
                                  fingerprintAttempts: fingerprintAttempts,
                                  result: result,
                                  reviewRequest: reviewRequest,
                                  onScan: scanAndOpenExam,
                                  onRequestReview: requestInvigilatorReview,
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
                  '$courseCode · IDENTITY AUTHENTICATION',
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
    required this.openingExam,
    required this.requestingReview,
    required this.fingerprintAttempts,
    required this.result,
    required this.reviewRequest,
    required this.onScan,
    required this.onRequestReview,
  });

  final CenterExam exam;
  final String candidateName;
  final String registrationNumber;
  final String department;
  final String level;
  final bool scanning;
  final bool openingExam;
  final bool requestingReview;
  final int fingerprintAttempts;
  final FingerprintResult? result;
  final ManualIdentityVerificationRequest? reviewRequest;
  final VoidCallback onScan;
  final VoidCallback onRequestReview;

  @override
  Widget build(BuildContext context) {
    final matched = result == FingerprintResult.matched;
    final failed = result == FingerprintResult.notMatched;
    final unavailable = result == FingerprintResult.unavailable;
    final pendingReview = reviewRequest?.isPending == true;
    final approved = reviewRequest?.isApproved == true;
    final rejected = reviewRequest?.isRejected == true;

    final status = openingExam || approved
        ? 'Identity verified. Opening examination…'
        : scanning
        ? 'Reading fingerprint…'
        : pendingReview
        ? 'Invigilator identity review pending'
        : rejected
        ? 'Manual identity review was not approved'
        : matched
        ? 'Fingerprint matched'
        : failed
        ? 'Fingerprint did not match'
        : unavailable
        ? 'Fingerprint reader unavailable'
        : 'Place your finger on the reader';

    final attention = failed || unavailable || pendingReview || rejected;

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
            'IDENTITY AUTHENTICATION',
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
                _Detail('Fingerprint attempts', '$fingerprintAttempts'),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: matched || approved
                    ? const Color(0xFFE8F2EB)
                    : attention
                    ? const Color(0xFFFFECE9)
                    : const Color(0xFFEDF4EC),
                shape: BoxShape.circle,
              ),
              child: Icon(
                approved || matched
                    ? Icons.verified_user_outlined
                    : pendingReview
                    ? Icons.person_search_outlined
                    : failed
                    ? Icons.error_outline_rounded
                    : unavailable
                    ? Icons.sensors_off_rounded
                    : Icons.fingerprint_rounded,
                color: matched || approved
                    ? abuGreen
                    : attention
                    ? const Color(0xFFB33D35)
                    : abuGreen,
                size: 84,
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (scanning || openingExam) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 16),
          ],
          Semantics(
            liveRegion: true,
            child: Text(
              status,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: attention ? const Color(0xFFB33D35) : abuInk,
                fontSize: 13,
                fontWeight: matched || approved || pendingReview
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ),
          if (pendingReview) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFAEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF7B955)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Review ID: ${reviewRequest!.id}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Remain at this workstation. The invigilator will compare your university record/photo and ID. There is no student-side bypass.',
                    style: TextStyle(height: 1.4, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
          if (rejected) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFFFECE9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDA29B)),
              ),
              child: Text(
                'Invigilator note: ${reviewRequest!.reviewNote.isEmpty ? 'Identity could not be confirmed.' : reviewRequest!.reviewNote}',
                style: const TextStyle(fontWeight: FontWeight.w700, height: 1.4),
              ),
            ),
          ],
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: scanning || openingExam || matched || approved ? null : onScan,
            icon: const Icon(Icons.fingerprint_rounded),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Text(
                scanning
                    ? 'AUTHENTICATING…'
                    : result == null
                    ? 'AUTHENTICATE'
                    : 'RETRY FINGERPRINT',
              ),
            ),
          ),
          if ((failed || unavailable) && !pendingReview) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: requestingReview || scanning || openingExam
                  ? null
                  : onRequestReview,
              icon: requestingReview
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.support_agent_outlined),
              label: Text(
                requestingReview
                    ? 'REQUESTING REVIEW…'
                    : 'REQUEST INVIGILATOR VERIFICATION',
              ),
            ),
          ],
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
