import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../auth/demo_auth.dart';

List<Widget> buildInvigilatorTopActions({
  bool showSession = true,
  bool showAttendance = true,
  bool showLiveHall = true,
  bool showSeatMap = false,
  bool showTechnical = true,
  bool showLogout = true,
}) {
  final actions = <Widget>[];

  if (showSession) {
    actions.add(
      TextButton.icon(
        onPressed: () => Get.toNamed(Routes.examSessionDashboard),
        icon: const Icon(Icons.dashboard_outlined),
        label: const Text('Session'),
      ),
    );
  }

  if (showAttendance) {
    actions.add(
      TextButton.icon(
        onPressed: () => Get.toNamed(Routes.attendanceRegister),
        icon: const Icon(Icons.fact_check_outlined),
        label: const Text('Attendance'),
      ),
    );
  }

  if (showLiveHall) {
    actions.add(
      TextButton.icon(
        onPressed: () => Get.toNamed(Routes.hallMonitoring),
        icon: const Icon(Icons.monitor_outlined),
        label: const Text('Live Hall'),
      ),
    );
  }

  if (showSeatMap) {
    actions.add(
      TextButton.icon(
        onPressed: () => Get.toNamed(Routes.seatMap),
        icon: const Icon(Icons.grid_view_outlined),
        label: const Text('Seat Map'),
      ),
    );
  }

  if (showTechnical) {
    actions.add(
      TextButton.icon(
        onPressed: () => Get.toNamed(Routes.technicalReports),
        icon: const Icon(Icons.build_circle_outlined),
        label: const Text('Technical'),
      ),
    );
  }

  if (showLogout) {
    actions.add(
      TextButton.icon(
        onPressed: () => DemoAuth.instance.signOut(),
        icon: const Icon(Icons.logout_outlined),
        label: const Text('Logout'),
      ),
    );
  }

  actions.add(const SizedBox(width: 8));
  return actions;
}
