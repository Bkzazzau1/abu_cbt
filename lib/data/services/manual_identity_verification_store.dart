import 'package:get/get.dart';

import '../models/manual_identity_verification_models.dart';

class ManualIdentityVerificationStore extends GetxService {
  /// Frontend demo state. In production, requests and approvals must be held
  /// by the hall server so the student workstation and invigilator console
  /// share one authoritative, audited identity-verification record.
  final requests = <ManualIdentityVerificationRequest>[].obs;

  bool _seeded = false;

  @override
  void onInit() {
    super.onInit();
    ensureSeeded();
  }

  void ensureSeeded() {
    if (_seeded) return;
    _seeded = true;
    if (requests.isNotEmpty) return;

    final now = DateTime.now();
    requests.assignAll([
      ManualIdentityVerificationRequest(
        id: 'IDV-DEMO-PENDING-001',
        registrationNumber: 'ABU/CSC/034',
        candidateName: 'Fadila Umar',
        department: 'Computer Science',
        level: '300 Level',
        photoAsset: '',
        examTitle: 'CSC 305 - Data Structures',
        hallName: 'Hall A',
        seatNumber: '',
        workstationId: '',
        failureReason: ManualIdentityFailureReason.poorScan,
        fingerprintAttempts: 2,
        requestedAt: now.subtract(const Duration(minutes: 8)),
        status: ManualIdentityVerificationStatus.pending,
      ),
      ManualIdentityVerificationRequest(
        id: 'IDV-DEMO-APPROVED-001',
        registrationNumber: 'ABU/CSC/026',
        candidateName: 'Nasir Ahmad',
        department: 'Computer Science',
        level: '300 Level',
        photoAsset: '',
        examTitle: 'CSC 305 - Data Structures',
        hallName: 'Hall A',
        seatNumber: '',
        workstationId: '',
        failureReason: ManualIdentityFailureReason.readerUnavailable,
        fingerprintAttempts: 2,
        requestedAt: now.subtract(const Duration(minutes: 25)),
        status: ManualIdentityVerificationStatus.approved,
        reviewedAt: now.subtract(const Duration(minutes: 23)),
        reviewedBy: 'Amina Yusuf',
        reviewNote:
            'University record and physical ABU ID were checked against the candidate before approval.',
      ),
    ]);
  }

  ManualIdentityVerificationRequest? latestForCandidate({
    required String registrationNumber,
    required String examTitle,
  }) {
    ensureSeeded();
    final reg = registrationNumber.trim().toUpperCase();
    for (final request in requests) {
      if (request.registrationNumber.trim().toUpperCase() == reg &&
          request.examTitle == examTitle) {
        return request;
      }
    }
    return null;
  }

  ManualIdentityVerificationRequest? pendingForCandidate({
    required String registrationNumber,
    required String examTitle,
  }) {
    ensureSeeded();
    final reg = registrationNumber.trim().toUpperCase();
    for (final request in requests) {
      if (request.isPending &&
          request.registrationNumber.trim().toUpperCase() == reg &&
          request.examTitle == examTitle) {
        return request;
      }
    }
    return null;
  }

  List<ManualIdentityVerificationRequest> get pendingRequests {
    ensureSeeded();
    return requests.where((request) => request.isPending).toList();
  }

  Future<ManualIdentityVerificationRequest> requestReview({
    required String registrationNumber,
    required String candidateName,
    required String department,
    required String level,
    required String photoAsset,
    required String examTitle,
    required String hallName,
    required String seatNumber,
    required String workstationId,
    required ManualIdentityFailureReason failureReason,
    required int fingerprintAttempts,
  }) async {
    ensureSeeded();
    final existing = pendingForCandidate(
      registrationNumber: registrationNumber,
      examTitle: examTitle,
    );

    if (existing != null) {
      final updated = existing.copyWith(
        hallName: hallName,
        seatNumber: seatNumber,
        workstationId: workstationId,
        failureReason: failureReason,
        fingerprintAttempts: fingerprintAttempts,
      );
      _replace(existing, updated);
      return updated;
    }

    final now = DateTime.now();
    final request = ManualIdentityVerificationRequest(
      id: 'IDV-${now.microsecondsSinceEpoch}',
      registrationNumber: registrationNumber,
      candidateName: candidateName,
      department: department,
      level: level,
      photoAsset: photoAsset,
      examTitle: examTitle,
      hallName: hallName,
      seatNumber: seatNumber,
      workstationId: workstationId,
      failureReason: failureReason,
      fingerprintAttempts: fingerprintAttempts,
      requestedAt: now,
      status: ManualIdentityVerificationStatus.pending,
    );
    requests.insert(0, request);
    return request;
  }

  ManualIdentityVerificationRequest approve({
    required String requestId,
    required String reviewedBy,
    required String reviewNote,
  }) {
    ensureSeeded();
    final current = _find(requestId);
    if (current == null) {
      throw StateError('Identity verification request was not found.');
    }
    if (!current.isPending) return current;
    if (reviewNote.trim().isEmpty) {
      throw StateError('A manual verification note is required.');
    }

    final updated = current.copyWith(
      status: ManualIdentityVerificationStatus.approved,
      reviewedAt: DateTime.now(),
      reviewedBy: reviewedBy.trim().isEmpty ? 'Invigilator' : reviewedBy.trim(),
      reviewNote: reviewNote.trim(),
    );
    _replace(current, updated);
    return updated;
  }

  ManualIdentityVerificationRequest reject({
    required String requestId,
    required String reviewedBy,
    required String reviewNote,
  }) {
    ensureSeeded();
    final current = _find(requestId);
    if (current == null) {
      throw StateError('Identity verification request was not found.');
    }
    if (!current.isPending) return current;
    if (reviewNote.trim().isEmpty) {
      throw StateError('A rejection note is required.');
    }

    final updated = current.copyWith(
      status: ManualIdentityVerificationStatus.rejected,
      reviewedAt: DateTime.now(),
      reviewedBy: reviewedBy.trim().isEmpty ? 'Invigilator' : reviewedBy.trim(),
      reviewNote: reviewNote.trim(),
    );
    _replace(current, updated);
    return updated;
  }

  ManualIdentityVerificationRequest resolveByFingerprint({
    required String requestId,
  }) {
    ensureSeeded();
    final current = _find(requestId);
    if (current == null) {
      throw StateError('Identity verification request was not found.');
    }
    if (!current.isPending) return current;

    final updated = current.copyWith(
      status: ManualIdentityVerificationStatus.resolvedByFingerprint,
      reviewedAt: DateTime.now(),
      reviewedBy: 'Fingerprint authentication',
      reviewNote:
          'Candidate completed a successful fingerprint retry before manual review.',
    );
    _replace(current, updated);
    return updated;
  }

  ManualIdentityVerificationRequest? _find(String requestId) {
    for (final request in requests) {
      if (request.id == requestId) return request;
    }
    return null;
  }

  void _replace(
    ManualIdentityVerificationRequest current,
    ManualIdentityVerificationRequest updated,
  ) {
    final index = requests.indexWhere((request) => request.id == current.id);
    if (index < 0) return;
    requests[index] = updated;
    requests.refresh();
  }
}
