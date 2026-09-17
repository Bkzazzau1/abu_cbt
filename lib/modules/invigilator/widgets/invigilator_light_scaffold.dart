import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../demo/abu_demo_theme.dart';

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

  static const _primaryWorkspaceRoutes = <String>{
    Routes.examSessionDashboard,
    Routes.generalExamReport,
    Routes.attendanceRegister,
    Routes.manualIdentityReview,
    Routes.hallMonitoring,
    Routes.seatMap,
    Routes.workstationAllocation,
    Routes.technicalReports,
  };

  @override
  Widget build(BuildContext context) {
    return Theme(data: abuDemoTheme(), child: Builder(builder: _buildScaffold));
  }

  Widget _buildScaffold(BuildContext context) {
    final isPrimaryWorkspace = _primaryWorkspaceRoutes.contains(Get.currentRoute);

    return Scaffold(
      backgroundColor: abuCanvas,
      appBar: AppBar(
        automaticallyImplyLeading: !isPrimaryWorkspace,
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
