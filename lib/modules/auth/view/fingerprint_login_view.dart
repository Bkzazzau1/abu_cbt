import 'package:flutter/material.dart';
import '../../../data/models/center_exam_models.dart';
import '../../demo/abu_demo_theme.dart';
import '../demo_auth.dart';
import '../fingerprint_reader.dart';

class FingerprintLoginView extends StatefulWidget {
  const FingerprintLoginView({
    super.key,
    required this.candidate,
    this.exams = const [],
    this.reader,
  });
  final CenterCandidate candidate;
  final List<CenterExam> exams;
  final FingerprintReader? reader;
  @override
  State<FingerprintLoginView> createState() => _FingerprintLoginViewState();
}

class _FingerprintLoginViewState extends State<FingerprintLoginView> {
  late final FingerprintReader reader =
      widget.reader ?? DemoFingerprintReader();
  bool scanning = false, entering = false;
  FingerprintResult? result;
  Future<void> scan() async {
    if (scanning || entering) return;
    setState(() {
      scanning = true;
      result = null;
    });
    FingerprintResult outcome;
    try {
      outcome = await reader.verify(widget.candidate.registrationNumber);
    } catch (_) {
      outcome = FingerprintResult.unavailable;
    }
    if (!mounted) return;
    setState(() {
      result = outcome;
      scanning = false;
    });
  }

  Future<void> enter() async {
    if (entering || result != FingerprintResult.matched) return;
    setState(() => entering = true);
    if (DemoAuth.instance.completeStudentFingerprint(
      widget.candidate.registrationNumber,
      result!,
    )) {
      await DemoAuth.instance.openWorkspace();
    }
    if (mounted) setState(() => entering = false);
  }

  CenterExam? get _dueExam {
    if (widget.exams.isEmpty) return null;
    for (final exam in widget.exams) {
      if (exam.status == CenterExamStatus.dueNow) return exam;
    }
    return widget.exams.first;
  }

  @override
  Widget build(BuildContext context) {
    final matched = result == FingerprintResult.matched;
    final exam = _dueExam;
    final message = scanning
        ? 'Reading fingerprint…'
        : switch (result) {
            FingerprintResult.matched =>
              'Fingerprint verified for this demo session.',
            FingerprintResult.notMatched =>
              'Fingerprint did not match. Lift your finger and try again.',
            FingerprintResult.unavailable =>
              'Fingerprint reader unavailable. Ask the invigilator for assistance, then retry.',
            null => 'Place your enrolled finger on the fingerprint reader.',
          };
    return Theme(
      data: abuDemoTheme(),
      child: Scaffold(
        backgroundColor: abuCanvas,
        appBar: AppBar(
          title: const Text('Student verification'),
          backgroundColor: Colors.white,
        ),
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
                    constraints: const BoxConstraints(maxWidth: 510),
                    child: Material(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: abuLine),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'STEP 2 OF 2 · FINGERPRINT',
                              style: TextStyle(
                                color: abuGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Verify your fingerprint',
                              style: TextStyle(
                                fontSize: 27,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.candidate.fullName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${widget.candidate.department} · ${widget.candidate.level}',
                              style: const TextStyle(color: abuMuted),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: abuCanvas,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: abuLine),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _CandidateDetailRow(
                                    label: 'Registration number',
                                    value: widget.candidate.registrationNumber,
                                  ),
                                  const SizedBox(height: 10),
                                  _CandidateDetailRow(
                                    label: 'Department',
                                    value: widget.candidate.department,
                                  ),
                                  const SizedBox(height: 10),
                                  _CandidateDetailRow(
                                    label: 'Course to write',
                                    value: exam == null
                                        ? 'No exam scheduled'
                                        : '${exam.courseCode} - ${exam.courseTitle}',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 30),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(26),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEDF4EC),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  matched
                                      ? Icons.check_circle_outline
                                      : Icons.fingerprint,
                                  size: 76,
                                  color: abuGreen,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (scanning) ...[
                              const LinearProgressIndicator(),
                              const SizedBox(height: 18),
                            ],
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                message,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color:
                                      result == FingerprintResult.notMatched ||
                                          result ==
                                              FingerprintResult.unavailable
                                      ? const Color(0xFFAD4936)
                                      : abuInk,
                                  fontSize: 14,
                                  height: 1.7,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (!matched)
                              FilledButton.icon(
                                onPressed: scanning ? null : scan,
                                icon: const Icon(Icons.fingerprint),
                                label: Text(
                                  scanning
                                      ? 'Scanning…'
                                      : result == null
                                      ? 'Simulate fingerprint scan'
                                      : 'Retry fingerprint scan',
                                ),
                              ),
                            if (matched)
                              FilledButton.icon(
                                onPressed: entering ? null : enter,
                                icon: const Icon(Icons.arrow_forward),
                                label: Text(
                                  entering
                                      ? 'Opening portal…'
                                      : 'Continue to exams',
                                ),
                              ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: entering
                                  ? null
                                  : () => Navigator.pop(context),
                              child: const Text(
                                'Use a different registration number',
                              ),
                            ),
                            if (reader is DemoFingerprintReader) ...[
                              const Divider(),
                              const SizedBox(height: 10),
                              const Text(
                                'Demo reader · No fingerprint device is connected. This screen simulates verification and does not capture biometric data.',
                                style: TextStyle(
                                  color: abuMuted,
                                  fontSize: 11,
                                  height: 1.7,
                                ),
                              ),
                              ExpansionTile(
                                title: const Text(
                                  'Demo scan outcome',
                                  style: TextStyle(fontSize: 11),
                                ),
                                tilePadding: EdgeInsets.zero,
                                children: FingerprintResult.values
                                    .map(
                                      (value) => ListTile(
                                        title: Text(switch (value) {
                                          FingerprintResult.matched => 'Match',
                                          FingerprintResult.notMatched =>
                                            'No match',
                                          FingerprintResult.unavailable =>
                                            'Reader unavailable',
                                        }),
                                        leading: Icon(
                                          (reader as DemoFingerprintReader)
                                                      .outcome ==
                                                  value
                                              ? Icons.radio_button_checked
                                              : Icons.radio_button_unchecked,
                                        ),
                                        onTap: scanning || entering
                                            ? null
                                            : () => setState(() {
                                                (reader as DemoFingerprintReader)
                                                        .outcome =
                                                    value;
                                                result = null;
                                              }),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
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

class _CandidateDetailRow extends StatelessWidget {
  const _CandidateDetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: abuMuted,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ],
  );
}
