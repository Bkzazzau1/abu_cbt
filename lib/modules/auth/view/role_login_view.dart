import 'package:flutter/material.dart';
import '../../demo/abu_demo_theme.dart';
import '../demo_auth.dart';
import '../../../data/services/center_exam_service.dart';
import 'fingerprint_login_view.dart';

class RoleLoginView extends StatefulWidget {
  const RoleLoginView({super.key});
  @override
  State<RoleLoginView> createState() => _RoleLoginViewState();
}

class _RoleLoginViewState extends State<RoleLoginView> {
  String role = 'Student';
  final username = TextEditingController(), password = TextEditingController();
  final form = GlobalKey<FormState>();
  bool hidden = true, busy = false;
  String? error;
  @override
  void dispose() {
    username.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    if (role == 'Student') {
      final session = CenterExamService.restoreCandidateSession(
        username.text.trim(),
      );
      if (session == null) {
        setState(
          () => error =
              'Registration number not found. Check your details and try again.',
        );
        return;
      }
      setState(() => error = null);
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => FingerprintLoginView(candidate: session.candidate),
        ),
      );
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final success = await DemoAuth.instance.signIn(
        role,
        username.text,
        password.text,
      );
      if (!mounted) return;
      if (success) {
        await DemoAuth.instance.openWorkspace();
      } else {
        setState(
          () => error =
              'These details do not match a $role account. Check your role, username and password.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: abuDemoTheme(),
    child: Scaffold(
      backgroundColor: abuCanvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 490),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.school_outlined, size: 42, color: abuGreen),
                  const SizedBox(height: 12),
                  const Text(
                    'ABU ZARIA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Examination portal',
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
                                  ? 'Enter your registration number'
                                  : 'Sign in to your workspace',
                              style: TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              role == 'Student'
                                  ? 'Step 1 of 2. Next, verify your fingerprint to access your exams.'
                                  : 'Choose your role and enter your own account details.',
                              style: TextStyle(color: abuMuted, height: 1.6),
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
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: role == 'Student'
                                    ? 'Registration number'
                                    : 'Staff username',
                                prefixIcon: const Icon(Icons.person_outline),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Enter your ${role == 'Student' ? 'registration number' : 'username'}'
                                  : null,
                            ),
                            const SizedBox(height: 18),
                            if (role != 'Student')
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
                                    ? 'Enter your password'
                                    : null,
                              ),
                            if (error != null) ...[
                              const SizedBox(height: 14),
                              Semantics(
                                liveRegion: true,
                                child: Text(
                                  error!,
                                  style: const TextStyle(
                                    color: Color(0xFFB33D35),
                                    fontSize: 12,
                                    height: 1.5,
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
                                          ? 'Next'
                                          : 'Sign in as $role',
                                    ),
                            ),
                            const SizedBox(height: 20),
                            ExpansionTile(
                              key: ValueKey(role),
                              tilePadding: EdgeInsets.zero,
                              title: const Text(
                                'Demo account details',
                                style: TextStyle(fontSize: 12, color: abuMuted),
                              ),
                              children: DemoAuth.samples[role]!
                                  .map(
                                    (a) => ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        a.$3,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: SelectableText(
                                        role == 'Student'
                                            ? a.$1
                                            : '${a.$1}\nPassword: ${a.$2}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          height: 1.7,
                                        ),
                                      ),
                                      trailing: TextButton(
                                        onPressed: busy
                                            ? null
                                            : () {
                                                username.text = a.$1;
                                                password.text = a.$2;
                                                setState(() => error = null);
                                              },
                                        child: const Text('Use'),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Demo accounts only · Sign out before using another account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: abuMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
