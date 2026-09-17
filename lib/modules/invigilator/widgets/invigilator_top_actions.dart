import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../auth/demo_auth.dart';

List<Widget> buildInvigilatorTopActions({
  bool showDashboard = true,
  bool showSession = true,
  bool showReports = true,
  bool showAttendance = true,
  bool showIdentity = true,
  bool showLiveHall = true,
  bool showSeatMap = false,
  bool showAllocation = true,
  bool showTechnical = true,
  bool showLogout = true,
}) {
  final actions = <Widget>[];

  if (showDashboard) {
    actions.add(
      TextButton.icon(
        onPressed: () => _goPrimary(Routes.invigilatorDashboard),
        icon: const Icon(Icons.home_outlined),
        label: const Text('Overview'),
      ),
    );
  }

  if (showSession) {
    actions.add(
      TextButton.icon(
        onPressed: () => _goPrimary(Routes.examSessionDashboard),
        icon: const Icon(Icons.dashboard_outlined),
        label: const Text('Session'),
      ),
    );
  }

  if (showReports) {
    actions.add(
      TextButton.icon(
        onPressed: () => _goPrimary(Routes.generalExamReport),
        icon: const Icon(Icons.assessment_outlined),
        label: const Text('Reports'),
      ),
    );
  }

  if (showAttendance) {
    actions.add(
      TextButton.icon(
        onPressed: () => _goPrimary(Routes.attendanceRegister),
        icon: const Icon(Icons.fact_check_outlined),
        label: const Text('Attendance'),
      ),
    );
  }

  if (showIdentity) {
    actions.add(
      TextButton.icon(
        onPressed: () => _goPrimary(Routes.manualIdentityReview),
        icon: const Icon(Icons.verified_user_outlined),
        label: const Text('Identity'),
      ),
    );
  }

  if (showLiveHall) {
    actions.add(
      TextButton.icon(
        onPressed: () => _goPrimary(Routes.hallMonitoring),
        icon: const Icon(Icons.monitor_outlined),
        label: const Text('Live Hall'),
      ),
    );
  }

  if (showSeatMap) {
    actions.add(
      TextButton.icon(
        onPressed: () => _goPrimary(Routes.seatMap),
        icon: const Icon(Icons.grid_view_outlined),
        label: const Text('Seat Map'),
      ),
    );
  }

  if (showAllocation) {
    actions.add(
      TextButton.icon(
        onPressed: () => _goPrimary(Routes.workstationAllocation),
        icon: const Icon(Icons.assignment_ind_outlined),
        label: const Text('Allocation'),
      ),
    );
  }

  if (showTechnical) {
    actions.add(
      TextButton.icon(
        onPressed: () => _goPrimary(Routes.technicalReports),
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

void _goPrimary(String route) {
  if (Get.currentRoute == route) return;
  Get.offNamed(route);
}
