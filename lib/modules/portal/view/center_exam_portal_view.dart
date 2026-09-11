import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/ks_page_shell.dart';
import '../../../data/models/attendance_models.dart';
import '../../../data/models/workstation_models.dart';
import '../../../data/services/attendance_mock_service.dart';
import '../../../data/services/network_health_service.dart';
import '../../../data/services/workstation_service.dart';
import '../controller/center_exam_portal_controller.dart';
import 'portal_dashboard_board.dart';
import 'portal_dashboard_chrome.dart';

class CenterExamPortalView extends StatefulWidget {
  const CenterExamPortalView({super.key});

  @override
  State<CenterExamPortalView> createState() => _CenterExamPortalViewState();
}

class _CenterExamPortalViewState extends State<CenterExamPortalView> {
  WorkstationRegistration? reg;
  final Map<String, AttendanceRecord> _attendanceByRegNo = {};

  @override
  void initState() {
    super.initState();
    _loadReg();
    _loadAttendance();
  }

  Future<void> _loadReg() async {
    final r = await WorkstationService.loadOrCreate();
    if (!mounted) return;
    setState(() => reg = r);
  }

  Future<void> _loadAttendance() async {
    final items = await AttendanceMockService.loadAttendance();
    if (!mounted) return;
    setState(() {
      _attendanceByRegNo
        ..clear()
        ..addEntries(
          items.map(
            (item) => MapEntry(item.registrationNumber.toUpperCase(), item),
          ),
        );
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CenterExamPortalController>();
    final cs = Theme.of(context).colorScheme;
    final network = Get.isRegistered<NetworkHealthService>()
        ? Get.find<NetworkHealthService>()
        : null;

    return Obx(() {
      final candidate = controller.candidate.value;

      if (candidate == null) {
        if (controller.isBootstrapping.value) {
          return const KsPageShell(
            padding: EdgeInsets.fromLTRB(16, 32, 16, 20),
            maxContentWidth: 900,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return KsPageShell(
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 20),
          maxContentWidth: 900,
          child: Center(
            child: GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_off_outlined, size: 48),
                  const SizedBox(height: 14),
                  const Text(
                    'No candidate session found',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your session could not be restored. Please return to login and continue.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: () => Get.offAllNamed(Routes.centerLogin),
                    icon: const Icon(Icons.login),
                    label: const Text('Go to Login'),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      final attendanceRecord =
          _attendanceByRegNo[candidate.registrationNumber.toUpperCase()];
      final seatDisplay = (reg?.seatNumber.trim().isNotEmpty ?? false)
          ? reg!.seatNumber
          : (attendanceRecord?.seatNumber ?? '-');
      final hallDisplay = (reg?.hallName.trim().isNotEmpty ?? false)
          ? reg!.hallName
          : (attendanceRecord?.hallName ?? '-');
      final workstationStatus = reg?.status ?? WorkstationStatus.pending;
      final workstationId = reg?.workstationId ?? 'UNREGISTERED';
      final networkStatus = network?.status.value ?? NetworkHealthStatus.online;
      final featuredExam = controller.dueNow.isNotEmpty
          ? controller.dueNow.first
          : (controller.exams.isNotEmpty ? controller.exams.first : null);
      final secondaryExams = controller.exams
          .where((exam) => exam.id != featuredExam?.id)
          .toList();

      return KsPageShell(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
        maxContentWidth: 1500,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 1180;

            final headerBar = PortalHeaderBar(
              networkStatus: networkStatus,
              workstationStatus: workstationStatus,
              onWorkstation: () => Get.toNamed(Routes.deviceRegistration),
              onLogout: controller.logout,
            );

            final dashboardBody = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PortalHeroCard(
                  candidateName: candidate.fullName,
                  regNo: candidate.registrationNumber,
                  level: candidate.level,
                  photoAsset: candidate.photoAsset,
                  department: candidate.department,
                  programme: candidate.programme,
                  hallDisplay: hallDisplay,
                  seatDisplay: seatDisplay,
                  workstationId: workstationId,
                  workstationStatus: workstationStatus,
                  networkStatus: networkStatus,
                  dueNowCount: controller.dueNow.length,
                  upcomingCount: controller.upcoming.length,
                  completedCount: controller.completed.length,
                  totalExams: controller.exams.length,
                ),
                const SizedBox(height: 16),
                ExamLifecyclePanel(
                  dueNowCount: controller.dueNow.length,
                  upcomingCount: controller.upcoming.length,
                  completedCount: controller.completed.length,
                  closedCount: controller.closed.length,
                  totalExams: controller.exams.length,
                ),
                const SizedBox(height: 16),
                ExamOperationsBoard(
                  featuredExam: featuredExam,
                  secondaryExams: secondaryExams,
                  upcomingExams: controller.upcoming,
                  completedCount: controller.completed.length,
                  closedCount: controller.closed.length,
                  dueNowCount: controller.dueNow.length,
                  totalExams: controller.exams.length,
                  networkStatus: networkStatus,
                  workstationStatus: workstationStatus,
                  onStart: controller.startExam,
                ),
              ],
            );

            if (!desktop) {
              return ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  PortalSidebar(
                    candidateName: candidate.fullName,
                    regNo: candidate.registrationNumber,
                    level: candidate.level,
                    photoAsset: candidate.photoAsset,
                    department: candidate.department,
                    programme: candidate.programme,
                    hallDisplay: hallDisplay,
                    seatDisplay: seatDisplay,
                    workstationStatus: workstationStatus,
                    dueNowCount: controller.dueNow.length,
                    upcomingCount: controller.upcoming.length,
                    completedCount: controller.completed.length,
                    closedCount: controller.closed.length,
                    onStartNow: controller.dueNow.isNotEmpty
                        ? () => controller.startExam(controller.dueNow.first)
                        : null,
                    onWorkstation: () => Get.toNamed(Routes.deviceRegistration),
                    onLogout: controller.logout,
                  ),
                  const SizedBox(height: 16),
                  headerBar,
                  const SizedBox(height: 16),
                  dashboardBody,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 298,
                  height: constraints.maxHeight,
                  child: PortalSidebar(
                    candidateName: candidate.fullName,
                    regNo: candidate.registrationNumber,
                    level: candidate.level,
                    photoAsset: candidate.photoAsset,
                    department: candidate.department,
                    programme: candidate.programme,
                    hallDisplay: hallDisplay,
                    seatDisplay: seatDisplay,
                    workstationStatus: workstationStatus,
                    dueNowCount: controller.dueNow.length,
                    upcomingCount: controller.upcoming.length,
                    completedCount: controller.completed.length,
                    closedCount: controller.closed.length,
                    fillHeight: true,
                    onStartNow: controller.dueNow.isNotEmpty
                        ? () => controller.startExam(controller.dueNow.first)
                        : null,
                    onWorkstation: () => Get.toNamed(Routes.deviceRegistration),
                    onLogout: controller.logout,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    children: [
                      headerBar,
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: dashboardBody,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    });
  }
}
