import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/glass_card.dart';
import '../controller/workstation_gate_controller.dart';

class WorkstationGateView extends GetView<WorkstationGateController> {
  const WorkstationGateView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GlassCard(
              child: Obx(
                () => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.desktop_windows_rounded,
                      size: 48,
                      color: cs.primary,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Preparing Workstation',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Checking workstation authorization and exam-center '
                      'readiness.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (controller.isLoading.value)
                      const CircularProgressIndicator(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
