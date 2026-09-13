import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../data/models/workstation_models.dart';
import '../../../data/services/workstation_service.dart';
import '../controller/center_login_controller.dart';

class CenterLoginView extends StatefulWidget {
  const CenterLoginView({super.key});

  @override
  State<CenterLoginView> createState() => _CenterLoginViewState();
}

class _CenterLoginViewState extends State<CenterLoginView> {
  WorkstationRegistration? reg;
  late final TextEditingController regNoController;
  late final TextEditingController passwordController;

  @override
  void initState() {
    super.initState();
    regNoController = TextEditingController();
    passwordController = TextEditingController();
    _loadReg();
  }

  Future<void> _loadReg() async {
    final r = await WorkstationService.loadOrCreate();
    if (!mounted) return;
    setState(() => reg = r);
  }

  @override
  void dispose() {
    regNoController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CenterLoginController>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.primary.withValues(alpha: 0.10),
              cs.secondary.withValues(alpha: 0.06),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 48,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 540),
                      child: GlassCard(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.desktop_windows_rounded,
                              size: 52,
                              color: cs.primary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'ABU Zaria CBT Center',
                              style: TextStyle(
                                color: cs.onSurface,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Center-based supervised examination login',
                              style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.68),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 18),
                            if (reg != null)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: cs.primary.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: cs.primary.withValues(alpha: 0.10),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Workstation: ${reg!.workstationId}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Center: '
                                      '${reg!.centerName.isEmpty ? "-" : reg!.centerName} '
                                      '• Hall: ${reg!.hallName.isEmpty ? "-" : reg!.hallName} '
                                      '• Seat: '
                                      '${reg!.seatNumber.isEmpty ? "-" : reg!.seatNumber}',
                                      style: TextStyle(
                                        color: cs.onSurface.withValues(
                                          alpha: 0.72,
                                        ),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: OutlinedButton.icon(
                                        onPressed: () => Get.toNamed(
                                          Routes.deviceRegistration,
                                        ),
                                        icon: const Icon(
                                          Icons.edit_location_alt_outlined,
                                        ),
                                        label: const Text(
                                          'Edit Workstation Assignment',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: regNoController,
                              decoration: const InputDecoration(
                                labelText: 'Registration Number',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Obx(
                              () => SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: controller.isLoading.value
                                      ? null
                                      : () => controller.login(
                                          registrationNumber:
                                              regNoController.text,
                                          password: passwordController.text,
                                        ),
                                  child: controller.isLoading.value
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Login'),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    Get.toNamed(Routes.invigilatorLogin),
                                icon: const Icon(
                                  Icons.admin_panel_settings_outlined,
                                ),
                                label: const Text(
                                  'Switch to Invigilator Dashboard',
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Test accounts: ABU/CSC/001 (cbt001), '
                              'ABU/MTH/004 (cbt004), ABU/GST/011 (cbt011), '
                              'ABU/CSC/008 (cbt008), ABU/BIO/002 (cbt002), '
                              'ABU/CHM/007 (cbt007), ABU/PHY/003 (cbt003)',
                              style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.68),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
