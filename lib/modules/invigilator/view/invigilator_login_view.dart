import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/ks_page_shell.dart';
import '../controller/invigilator_login_controller.dart';

class InvigilatorLoginView extends StatefulWidget {
  const InvigilatorLoginView({super.key});

  @override
  State<InvigilatorLoginView> createState() => _InvigilatorLoginViewState();
}

class _InvigilatorLoginViewState extends State<InvigilatorLoginView> {
  late final TextEditingController usernameController;
  late final TextEditingController passwordController;

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<InvigilatorLoginController>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: KsPageShell(
        maxContentWidth: 560,
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: GlassCard(
                    tone: GlassCardTone.primary,
                    showGlow: true,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 78,
                          height: 78,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cs.primary.withValues(alpha: 0.12),
                            border: Border.all(
                              color: cs.primary.withValues(alpha: 0.28),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: cs.primary.withValues(alpha: 0.18),
                                blurRadius: 24,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.admin_panel_settings_outlined,
                            size: 38,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Invigilator Login',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Secure access to workstation monitoring, session control, and hall supervision.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.74),
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Obx(
                          () => SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: controller.isLoading.value
                                  ? null
                                  : () => controller.login(
                                      username: usernameController.text,
                                      password: passwordController.text,
                                    ),
                              icon: const Icon(Icons.login),
                              label: Text(
                                controller.isLoading.value
                                    ? 'Signing in...'
                                    : 'Login',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => Get.offAllNamed(Routes.centerLogin),
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: const Text('Back to Candidate Sign In'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: Colors.white.withValues(alpha: 0.04),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.07),
                            ),
                          ),
                          child: Text(
                            'Test accounts: invigilator.a / invA123, invigilator.b / invB123, chief.invigilator / chief123',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.68),
                              fontWeight: FontWeight.w600,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
