import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/ks_status_chip.dart';
import '../../../data/models/workstation_models.dart';
import '../controller/device_registration_controller.dart';

class DeviceRegistrationView extends GetView<DeviceRegistrationController> {
  const DeviceRegistrationView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Workstation Registration')),
      body: Obx(() {
        final reg = controller.registration.value;

        if (reg == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final approved = reg.status == WorkstationStatus.whitelisted;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Secure Workstation ID',
                    style: TextStyle(
                      color: cs.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SelectableText(
                    reg.workstationId,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    approved
                        ? 'This workstation is already approved for center exams.'
                        : 'Submit this workstation to the invigilator/exam officer '
                              'once. It remains approved until removed by the office.',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton.icon(
                        onPressed: controller.copyWorkstationId,
                        icon: const Icon(Icons.copy_outlined),
                        label: const Text('Copy ID'),
                      ),
                      _statusChip(reg.status),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                children: [
                  TextField(
                    controller: controller.centerController,
                    decoration: const InputDecoration(
                      labelText: 'Center Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller.hallController,
                    decoration: const InputDecoration(
                      labelText: 'Hall Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller.seatController,
                    decoration: const InputDecoration(
                      labelText: 'Seat Number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (!approved)
              const GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Approval Flow',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '1. Generate workstation ID\n'
                      '2. Submit center/hall/seat details\n'
                      '3. Invigilator or exam officer approves once\n'
                      '4. Workstation stays whitelisted until removed or revoked',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 18),
            if (approved)
              Column(
                children: [
                  FilledButton.icon(
                    onPressed: () => Get.offAllNamed(Routes.centerLogin),
                    icon: const Icon(Icons.login),
                    label: const Text('Continue to Candidate Login'),
                  ),
                  const SizedBox(height: 10),
                  Obx(
                    () => OutlinedButton.icon(
                      onPressed: controller.isLoading.value
                          ? null
                          : controller.saveAssignment,
                      icon: const Icon(Icons.edit_location_alt_outlined),
                      label: Text(
                        controller.isLoading.value
                            ? 'Saving...'
                            : 'Update Hall / Seat',
                      ),
                    ),
                  ),
                ],
              )
            else ...[
              Obx(
                () => FilledButton.icon(
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.submit,
                  icon: const Icon(Icons.send_outlined),
                  label: Text(
                    controller.isLoading.value
                        ? 'Submitting...'
                        : 'Submit for Approval',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: controller.mockApproveNow,
                icon: const Icon(Icons.verified_outlined),
                label: const Text('Mock Approve (Frontend Only)'),
              ),
            ],
          ],
        );
      }),
    );
  }

  Widget _statusChip(WorkstationStatus status) {
    late final String text;
    late final KsStatusChipTone tone;

    switch (status) {
      case WorkstationStatus.pending:
        text = 'Pending Approval';
        tone = KsStatusChipTone.warning;
        break;
      case WorkstationStatus.whitelisted:
        text = 'Whitelisted';
        tone = KsStatusChipTone.success;
        break;
      case WorkstationStatus.disabled:
        text = 'Disabled';
        tone = KsStatusChipTone.warningSoft;
        break;
      case WorkstationStatus.revoked:
        text = 'Revoked';
        tone = KsStatusChipTone.danger;
        break;
    }

    return KsStatusChip(label: text, tone: tone);
  }
}
