import 'package:flutter/material.dart';

import '../../demo/abu_demo_theme.dart';

/// Shared light-theme page shell for invigilator sub-screens (Hall
/// Monitoring, Attendance, Seat Map, Session Dashboard, etc.) — a simple
/// back-navigable page (Flutter's `AppBar` supplies the back arrow
/// automatically once there's a route to pop) with the same white/abuCanvas
/// look as the main invigilator dashboard, but without repeating its full
/// logo header on every sub-page. Self-themed like the dashboard, so it
/// looks right regardless of the app's separate dark global theme.
class InvigilatorLightScaffold extends StatelessWidget {
  const InvigilatorLightScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.maxContentWidth = 1480,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    return Theme(data: abuDemoTheme(), child: Builder(builder: _buildScaffold));
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: abuCanvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: abuInk,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: abuLine),
        ),
        actions: actions,
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Padding(padding: const EdgeInsets.all(20), child: body),
          ),
        ),
      ),
    );
  }
}
