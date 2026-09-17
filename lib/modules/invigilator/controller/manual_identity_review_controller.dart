import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/attendance_models.dart';
import '../../../data/models/manual_identity_verification_models.dart';
import '../../../data/services/attendance_demo_store.dart';
import '../../../data/services/invigilator_session.dart';
import '../../../data/services/manual_identity_verification_store.dart';

class ManualIdentityReviewController extends GetxController {
  final selectedStatus = 'Pending'.obs;
  final selectedRequestId = ''.obs;
  final isProcessing = false.obs;
  final searchController = TextEditingController();
  final reviewNoteController = TextEditingController();

  late final ManualIdentityVerificationStore _reviewStore;
  late final AttendanceDemoStore _attendanceStore;

  RxList<ManualIdentityVerificationRequest> get requests =>
      _reviewStore.requests;

  @override
  void onInit() {
    super.onInit();
    _reviewStore = Get.isRegistered<ManualIdentityVerificationStore>()
        ? Get.find<ManualIdentityVerificationStore>()
        : Get.put(ManualIdentityVerificationStore(), permanent: true);
    _attendanceStore = Get.isRegistered<AttendanceDemoStore>()
        ? Get.find<AttendanceDemoStore>()
        : Get.put(AttendanceDemoStore(), permanent: true);
    _attendanceStore.ensureLoaded();
  }

  List<String> get statusOptions => const [
        'Pending',
        'All',
        'Approved',
        'Rejected',
        'Resolved by Fingerprint',
      ];

  List<ManualIdentityVerificationRequest> get filteredRequests {
    final query = searchController.text.trim().toLowerCase();
    final items = requests.where((request) {
      final statusOk = switch (selectedStatus.value) {
        'Pending' => request.isPending,
        'Approved' => request.isApproved,
        'Rejected' => request.isRejected,
        'Resolved by Fingerprint' => request.isResolvedByFingerprint,
        _ => true,
      };
      final queryOk = query.isEmpty ||
          request.candidateName.toLowerCase().contains(query) ||
          request.registrationNumber.toLowerCase().contains(query) ||
          request.workstationId.toLowerCase().contains(query) ||
          request.seatNumber.toLowerCase().contains(query) ||
          request.id.toLowerCase().contains(query);
      return statusOk && queryOk;
    }).toList();
    items.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    return items;
  }

  ManualIdentityVerificationRequest? get selectedRequest {
    final id = selectedRequestId.value;
    if (id.isEmpty) return null;
    for (final request in requests) {
      if (request.id == id) return request;
    }
    return null;
  }

  int get pendingCount => requests.where((r) => r.isPending).length;
  int get approvedCount => requests.where((r) => r.isApproved).length;
  int get rejectedCount => requests.where((r) => r.isRejected).length;
  int get fingerprintResolvedCount =>
      requests.where((r) => r.isResolvedByFingerprint).length;

  void updateStatus(String value) {
    selectedStatus.value = value;
    _ensureVisibleSelection();
  }

  void updateSearch(String _) {
    requests.refresh();
    _ensureVisibleSelection();
  }

  void selectRequest(ManualIdentityVerificationRequest request) {
    selectedRequestId.value = request.id;
    reviewNoteController.text = request.isPending ? '' : request.reviewNote;
  }

  Future<void> approveSelected() async {
    if (isProcessing.value) return;
    final current = selectedRequest;
    if (current == null || !current.isPending) return;
    final note = reviewNoteController.text.trim();
    if (note.isEmpty) {
      _message('Review note required',
          'Record how the candidate identity was manually confirmed.');
      return;
    }

    isProcessing.value = true;
    try {
      final reviewer = InvigilatorSession.currentName.trim().isEmpty
          ? 'Invigilator'
          : InvigilatorSession.currentName.trim();
      final approved = _reviewStore.approve(
        requestId: current.id,
        reviewedBy: reviewer,
        reviewNote: note,
      );

      final attendance =
          _attendanceStore.findByRegistration(approved.registrationNumber);
      if (attendance != null) {
        _attendanceStore.setVerification(
          registrationNumber: attendance.registrationNumber,
          identityState: IdentityVerificationState.manualVerified,
          biometricConfidence: 0,
          note:
              'Manual identity verification approved by $reviewer. ${approved.reviewNote}',
        );
      }

      _message('Manual verification approved',
          '${approved.candidateName} may continue. Audit ID: ${approved.id}');
    } on StateError catch (error) {
      _message('Identity review', error.message.toString());
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> rejectSelected() async {
    if (isProcessing.value) return;
    final current = selectedRequest;
    if (current == null || !current.isPending) return;
    final note = reviewNoteController.text.trim();
    if (note.isEmpty) {
      _message('Rejection note required',
          'Record why the candidate identity could not be confirmed.');
      return;
    }

    isProcessing.value = true;
    try {
      final reviewer = InvigilatorSession.currentName.trim().isEmpty
          ? 'Invigilator'
          : InvigilatorSession.currentName.trim();
      final rejected = _reviewStore.reject(
        requestId: current.id,
        reviewedBy: reviewer,
        reviewNote: note,
      );

      final attendance =
          _attendanceStore.findByRegistration(rejected.registrationNumber);
      if (attendance != null) {
        _attendanceStore.setVerification(
          registrationNumber: attendance.registrationNumber,
          identityState: IdentityVerificationState.mismatch,
          biometricConfidence: attendance.biometricConfidence,
          note:
              'Manual identity verification rejected by $reviewer. ${rejected.reviewNote}',
          state: AttendanceState.issueFlagged,
        );
      }

      _message('Identity review rejected',
          '${rejected.candidateName} remains blocked from the examination.');
    } on StateError catch (error) {
      _message('Identity review', error.message.toString());
    } finally {
      isProcessing.value = false;
    }
  }

  void _ensureVisibleSelection() {
    final current = selectedRequest;
    if (current == null) return;
    if (!filteredRequests.any((item) => item.id == current.id)) {
      selectedRequestId.value = '';
      reviewNoteController.clear();
    }
  }

  void _message(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 5),
    );
  }

  @override
  void onClose() {
    searchController.dispose();
    reviewNoteController.dispose();
    super.onClose();
  }
}
