import 'package:flutter/material.dart';

import '../../demo/abu_demo_theme.dart';
import '../demo_auth.dart';

class RoleLoginView extends StatefulWidget {
  const RoleLoginView({super.key});

  @override
  State<RoleLoginView> createState() => _RoleLoginViewState();
}

class _RoleLoginViewState extends State<RoleLoginView> {
  String role = 'Student';
  final username = TextEditingController();
  final password = TextEditingController();
  final form = GlobalKey<FormState>();
  bool hidden = true;
  bool busy = false;
  String? error;

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;

    setState(() {
      busy = true;
      error = null;
    });

    try {
      if (role == 'Student') {
        final found = DemoAuth.instance.beginStudentSession(username.text.trim());
        if (!mounted) return;
        if (!found) {
          setState(() => error = 'Registration number not found.');
          return;
        }
        await DemoAuth.instance.openWorkspace();
        return;
      }

      final success = await DemoAuth.instance.signIn(
        role,
        username.text,
        password.text,
      );
      if (!mounted) return;
      if (success) {
        await DemoAuth.instance.openWorkspace();
      } else {
        setState(() => error = 'Invalid username or password.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _openDemo(String demoRole) async {
    final accounts = DemoAuth.samples[demoRole];
    if (accounts == null || accounts.isEmpty) return;

    final account = demoRole == 'Invigilator' && accounts.length > 2
        ? accounts[2]
        : accounts.first;

    setState(() {
      role = demoRole;
      username.text = account.$1;
      password.text = account.$2;
      hidden = true;
      error = null;
    });

    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    await submit();
  }

  Future<void> _showDemoAccess() async {
    if (busy) return;

    final selectedRole = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 480),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Demo Access',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                _DemoAccessButton(
                  icon: Icons.school_outlined,
                  label: 'Student Demo',
                  onTap: () => Navigator.pop(sheetContext, 'Student'),
                ),
                const SizedBox(height: 10),
                _DemoAccessButton(
                  icon: Icons.security_outlined,
                  label: 'Invigilator Demo',
                  onTap: () => Navigator.pop(sheetContext, 'Invigilator'),
                ),
                const SizedBox(height: 10),
                _DemoAccessButton(
                  icon: Icons.admin_panel_settings_outlined,
                  label: 'Administrator Demo',
                  onTap: () => Navigator.pop(sheetContext, 'Administrator'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selectedRole == null) return;
    await _openDemo(selectedRole);
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: abuDemoTheme(),
    child: Scaffold(
      backgroundColor: abuCanvas,
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
                  constraints: const BoxConstraints(maxWidth: 490),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onLongPress: _showDemoAccess,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Image.asset('assets/abulogo.png', height: 64),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Ahmadu Bello University, Zaria',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Examination Portal',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: abuMuted),
                      ),
                      const SizedBox(height: 28),
                      Material(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: abuLine),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(26),
                          child: Form(
                            key: form,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  role == 'Student'
                                      ? 'Student Login'
                                      : '$role Login',
                                  style: const TextStyle(
                                    fontSize: 23,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 22),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: DemoAuth.samples.keys
                                      .toList()
                                      .reversed
                                      .map(
                                        (r) => ChoiceChip(
                                          label: Text(r),
                                          selected: role == r,
                                          showCheckmark: false,
                                          onSelected: busy
                                              ? null
                                              : (_) {
                                                  setState(() {
                                                    role = r;
                                                    error = null;
                                                    hidden = true;
                                                    username.clear();
                                                    password.clear();
                                                    form.currentState?.reset();
                                                  });
                                                },
                                        ),
                                      )
                                      .toList(),
                                ),
                                const SizedBox(height: 24),
                                TextFormField(
                                  controller: username,
                                  enabled: !busy,
                                  autofillHints: const [AutofillHints.username],
                                  textInputAction: role == 'Student'
                                      ? TextInputAction.done
                                      : TextInputAction.next,
                                  onFieldSubmitted: role == 'Student'
                                      ? (_) => submit()
                                      : null,
                                  decoration: InputDecoration(
                                    labelText: role == 'Student'
                                        ? 'Registration number'
                                        : 'Staff username',
                                    prefixIcon: const Icon(Icons.person_outline),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty
                                      ? role == 'Student'
                                            ? 'Enter registration number'
                                            : 'Enter username'
                                      : null,
                                ),
                                if (role != 'Student') ...[
                                  const SizedBox(height: 18),
                                  TextFormField(
                                    controller: password,
                                    enabled: !busy,
                                    obscureText: hidden,
                                    autofillHints: const [AutofillHints.password],
                                    onFieldSubmitted: (_) => submit(),
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      prefixIcon: const Icon(Icons.lock_outline),
                                      suffixIcon: IconButton(
                                        tooltip: hidden
                                            ? 'Show password'
                                            : 'Hide password',
                                        onPressed: () =>
                                            setState(() => hidden = !hidden),
                                        icon: Icon(
                                          hidden
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                        ),
                                      ),
                                    ),
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Enter password'
                                        : null,
                                  ),
                                ],
                                if (error != null) ...[
                                  const SizedBox(height: 14),
                                  Semantics(
                                    liveRegion: true,
                                    child: Text(
                                      error!,
                                      style: const TextStyle(
                                        color: Color(0xFFB33D35),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 24),
                                FilledButton(
                                  onPressed: busy ? null : submit,
                                  child: busy
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          role == 'Student'
                                              ? 'Continue'
                                              : 'Sign in',
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
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

class _DemoAccessButton extends StatelessWidget {
  const _DemoAccessButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Text(label),
      ),
    );
  }
}
