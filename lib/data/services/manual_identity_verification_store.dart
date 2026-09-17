import 'package:get/get.dart';

import '../models/manual_identity_verification_models.dart';

class ManualIdentityVerificationStore extends GetxService {
  /// Frontend demo state. In production, requests and approvals must be held
  /// by the hall server so the student workstation and invigilator console
  /// share one authoritative, audited identity-verification record.
  final requests = <ManualIdentityVerificationRequest>[].obs;

  ManualIdentityVerificationRequest? latestForCandidate({
    required String registrationNumber,
    required String examTitle,
  }) {
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

  List<ManualIdentityVerificationRequest> get pendingRequests =>
      requests.where((request) => request.isPending).toList();

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
