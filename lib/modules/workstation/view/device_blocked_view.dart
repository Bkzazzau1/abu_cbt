import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/glass_card.dart';
import '../controller/device_blocked_controller.dart';

class DeviceBlockedView extends GetView<DeviceBlockedController> {
  const DeviceBlockedView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Obx(() {
              final reg = controller.registration.value;

              return GlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.block_outlined, size: 56, color: cs.error),
                    const SizedBox(height: 16),
                    const Text(
                      'Workstation Blocked',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'This workstation is not authorized for exam use. Contact '
                      'the invigilator or exam officer.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (reg != null) ...[
                      const Text(
                        'Workstation ID',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        reg.workstationId,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
