import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../demo/abu_demo_theme.dart';

class PracticeScaffold extends StatelessWidget {
  const PracticeScaffold({
    super.key,
    required this.child,
    this.section = 'Practice centre',
    this.trailing,
    this.scroll = true,
    this.onBack,
  });
  final Widget child;
  final String section;
  final Widget? trailing;
  final bool scroll;
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) => Theme(
    data: abuDemoTheme(),
    child: Builder(
      builder: (context) => Scaffold(
        backgroundColor: const Color(0xFFF4F6F5),
        body: SafeArea(
          child: Column(
            children: [
              Material(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      if (onBack != null) ...[
                        IconButton(
                          onPressed: onBack,
                          tooltip: 'Back',
                          icon: const Icon(Icons.arrow_back, size: 20),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Image.asset(
                        'assets/abulogo.png',
                        width: 39,
                        height: 42,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ahmadu Bello University, Zaria',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              section,
                              style: const TextStyle(
                                fontSize: 11,
                                color: abuMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (trailing != null)
                        trailing!
                      else
                        const PracticeTag('STUDENT PRACTICE'),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) {
                    final padding = EdgeInsets.symmetric(
                      horizontal: c.maxWidth < 650 ? 16 : 36,
                      vertical: c.maxWidth < 650 ? 20 : 30,
                    );
                    return Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1440),
                        child: scroll
                            ? SingleChildScrollView(
                                padding: padding,
                                child: child,
                              )
                            : Padding(padding: padding, child: child),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class PracticeCard extends StatelessWidget {
  const PracticeCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(26),
    this.color = Colors.white,
  });
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  @override
  Widget build(BuildContext context) => Material(
    color: color,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: abuLine),
    ),
    child: Padding(padding: padding, child: child),
  );
}

class PracticeTag extends StatelessWidget {
  const PracticeTag(this.label, {super.key, this.amber = false});
  final String label;
  final bool amber;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: amber ? const Color(0xFFFFF3DE) : const Color(0xFFEAF3EE),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: amber ? const Color(0xFF93600F) : abuGreen,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    ),
  );
}

class PracticeTitle extends StatelessWidget {
  const PracticeTitle(this.title, this.subtitle, {super.key});
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
          height: 1.25,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        subtitle,
        style: const TextStyle(color: abuMuted, fontSize: 14, height: 1.6),
      ),
    ],
  );
}

Widget practiceColumns(Widget main, Widget aside, {double sideWidth = 310}) =>
    LayoutBuilder(
      builder: (context, c) => c.maxWidth >= 940
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: main),
                const SizedBox(width: 26),
                SizedBox(width: sideWidth, child: aside),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [main, const SizedBox(height: 22), aside],
            ),
    );

Widget practiceDetail(IconData icon, String label, String value) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 12),
  child: Row(
    children: [
      Icon(icon, color: abuMuted, size: 19),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          label,
          style: const TextStyle(color: abuMuted, fontSize: 12),
        ),
      ),
      const SizedBox(width: 12),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
      ),
    ],
  ),
);

Widget practiceSteps(int active) => Padding(
  padding: const EdgeInsets.only(bottom: 26),
  child: Wrap(
    spacing: 20,
    runSpacing: 12,
    children: ['Instructions', 'Confirmation', 'Examination', 'Summary']
        .asMap()
        .entries
        .map(
          (e) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: e.key <= active
                    ? abuGreen
                    : const Color(0xFFE2E8E3),
                child: e.key < active
                    ? const Icon(Icons.check, size: 13, color: Colors.white)
                    : Text(
                        '${e.key + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          color: e.key == active ? Colors.white : abuMuted,
                        ),
                      ),
              ),
              const SizedBox(width: 7),
              Text(
                e.value,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: e.key == active
                      ? FontWeight.w700
                      : FontWeight.w400,
                  color: e.key == active ? abuInk : abuMuted,
                ),
              ),
            ],
          ),
        )
        .toList(),
  ),
);

void returnToPractice() => Get.offAllNamed(Routes.centerPortal);
