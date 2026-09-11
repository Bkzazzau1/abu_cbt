import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../data/models/workstation_models.dart';
import '../../../data/services/workstation_service.dart';

class DeviceRegistrationController extends GetxController {
  final isLoading = false.obs;
  final registration = Rxn<WorkstationRegistration>();

  final centerController = TextEditingController(text: 'KASU');
  final hallController = TextEditingController();
  final seatController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    final reg = await WorkstationService.loadOrCreate();
    registration.value = reg;

    if (reg.centerName.isNotEmpty) centerController.text = reg.centerName;
    if (reg.hallName.isNotEmpty) hallController.text = reg.hallName;
    if (reg.seatNumber.isNotEmpty) seatController.text = reg.seatNumber;
  }

  Future<void> copyWorkstationId() async {
    final id = registration.value?.workstationId ?? '';
    if (id.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: id));
    Get.snackbar(
      'Copied',
      'Workstation ID copied successfully.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> submit() async {
    if (isLoading.value) return;

    if (!_hasAssignmentInput()) {
      return;
    }

    isLoading.value = true;
    try {
      final updated = await WorkstationService.submitForApproval(
        centerName: centerController.text,
        hallName: hallController.text,
        seatNumber: seatController.text,
      );
      registration.value = updated;

      Get.snackbar(
        'Submitted',
        'Workstation submitted for invigilator approval.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveAssignment() async {
    if (isLoading.value) return;
    if (!_hasAssignmentInput()) {
      return;
    }

    isLoading.value = true;
    try {
      final updated = await WorkstationService.updateAssignment(
        centerName: centerController.text,
        hallName: hallController.text,
        seatNumber: seatController.text,
      );
      registration.value = updated;

      Get.snackbar(
        'Updated',
        'Workstation hall and seat assignment saved.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // FRONTEND MOCK BUTTON
  Future<void> mockApproveNow() async {
    if (!_hasAssignmentInput()) {
      return;
    }

    isLoading.value = true;
    try {
      await WorkstationService.updateAssignment(
        centerName: centerController.text,
        hallName: hallController.text,
        seatNumber: seatController.text,
      );
      final updated = await WorkstationService.mockWhitelistCurrentDevice();
      registration.value = updated;
      Get.snackbar(
        'Approved',
        'This workstation is now whitelisted (frontend mock).',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  bool _hasAssignmentInput() {
    if (hallController.text.trim().isEmpty ||
        seatController.text.trim().isEmpty) {
      Get.snackbar(
        'Missing information',
        'Enter hall name and seat number.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
    return true;
  }

  @override
  void onClose() {
    centerController.dispose();
    hallController.dispose();
    seatController.dispose();
    super.onClose();
  }
}
