import 'package:get/get.dart';

import '../../modules/auth/controller/center_login_controller.dart';
import '../../modules/auth/view/center_login_view.dart';
import '../../modules/exam/controller/center_exam_run_controller.dart';
import '../../modules/exam/view/center_exam_confirmation_view.dart';
import '../../modules/exam/view/center_exam_instruction_view.dart';
import '../../modules/exam/view/center_exam_run_view.dart';
import '../../modules/exam/view/center_exam_submit_view.dart';
import '../../modules/invigilator/controller/attendance_register_controller.dart';
import '../../modules/invigilator/controller/candidate_action_panel_controller.dart';
import '../../modules/invigilator/controller/candidate_checkin_controller.dart';
import '../../modules/invigilator/controller/exam_session_dashboard_controller.dart';
import '../../modules/invigilator/controller/hall_monitoring_controller.dart';
import '../../modules/invigilator/controller/incident_report_controller.dart';
import '../../modules/invigilator/controller/invigilator_dashboard_controller.dart';
import '../../modules/invigilator/controller/invigilator_login_controller.dart';
import '../../modules/invigilator/controller/malpractice_report_controller.dart';
import '../../modules/invigilator/controller/seat_map_controller.dart';
import '../../modules/invigilator/view/attendance_register_view.dart';
import '../../modules/invigilator/view/candidate_action_panel_view.dart';
import '../../modules/invigilator/view/candidate_checkin_view.dart';
import '../../modules/invigilator/view/exam_session_dashboard_view.dart';
import '../../modules/invigilator/view/hall_monitoring_view.dart';
import '../../modules/invigilator/view/incident_report_view.dart';
import '../../modules/invigilator/view/invigilator_dashboard_view.dart';
import '../../modules/invigilator/view/invigilator_login_view.dart';
import '../../modules/invigilator/view/malpractice_report_view.dart';
import '../../modules/invigilator/view/seat_map_view.dart';
import '../../modules/portal/controller/center_exam_portal_controller.dart';
import '../../modules/portal/view/center_exam_portal_view.dart';
import '../../modules/workstation/controller/device_blocked_controller.dart';
import '../../modules/workstation/controller/device_registration_controller.dart';
import '../../modules/workstation/controller/workstation_gate_controller.dart';
import '../../modules/workstation/view/device_blocked_view.dart';
import '../../modules/workstation/view/device_registration_view.dart';
import '../../modules/workstation/view/workstation_gate_view.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = <GetPage>[
    GetPage(
      name: Routes.workstationGate,
      page: () => const WorkstationGateView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<WorkstationGateController>(
          () => WorkstationGateController(),
        );
      }),
    ),
    GetPage(
      name: Routes.deviceRegistration,
      page: () => const DeviceRegistrationView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<DeviceRegistrationController>(
          () => DeviceRegistrationController(),
        );
      }),
    ),
    GetPage(
      name: Routes.deviceBlocked,
      page: () => const DeviceBlockedView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<DeviceBlockedController>(() => DeviceBlockedController());
      }),
    ),
    GetPage(
      name: Routes.centerLogin,
      page: () => const CenterLoginView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<CenterLoginController>(() => CenterLoginController());
      }),
    ),
    GetPage(
      name: Routes.centerPortal,
      page: () => const CenterExamPortalView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<CenterExamPortalController>(
          () => CenterExamPortalController(),
        );
      }),
    ),
    GetPage(
      name: Routes.centerExamInstruction,
      page: () => const CenterExamInstructionView(),
    ),
    GetPage(
      name: Routes.centerExamConfirmation,
      page: () => const CenterExamConfirmationView(),
    ),
    GetPage(
      name: Routes.centerExamRun,
      page: () => const CenterExamRunView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<CenterExamRunController>(() => CenterExamRunController());
      }),
    ),
    GetPage(
      name: Routes.centerExamSubmit,
      page: () => const CenterExamSubmitView(),
    ),
    GetPage(
      name: Routes.invigilatorLogin,
      page: () => const InvigilatorLoginView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<InvigilatorLoginController>(
          () => InvigilatorLoginController(),
        );
      }),
    ),
    GetPage(
      name: Routes.invigilatorDashboard,
      page: () => const InvigilatorDashboardView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<InvigilatorDashboardController>(
          () => InvigilatorDashboardController(),
        );
      }),
    ),
    GetPage(
      name: Routes.candidateCheckIn,
      page: () => const CandidateCheckInView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<CandidateCheckInController>(
          () => CandidateCheckInController(),
        );
      }),
    ),
    GetPage(
      name: Routes.incidentReport,
      page: () => const IncidentReportView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<IncidentReportController>(() => IncidentReportController());
      }),
    ),
    GetPage(
      name: Routes.malpracticeReport,
      page: () => const MalpracticeReportView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<MalpracticeReportController>(
          () => MalpracticeReportController(),
        );
      }),
    ),
    GetPage(
      name: Routes.hallMonitoring,
      page: () => const HallMonitoringView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<HallMonitoringController>(() => HallMonitoringController());
      }),
    ),
    GetPage(
      name: Routes.candidateActionPanel,
      page: () => const CandidateActionPanelView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<CandidateActionPanelController>(
          () => CandidateActionPanelController(),
        );
      }),
    ),
    GetPage(
      name: Routes.attendanceRegister,
      page: () => const AttendanceRegisterView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<AttendanceRegisterController>(
          () => AttendanceRegisterController(),
        );
      }),
    ),
    GetPage(
      name: Routes.seatMap,
      page: () => const SeatMapView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<SeatMapController>(() => SeatMapController());
      }),
    ),
    GetPage(
      name: Routes.examSessionDashboard,
      page: () => const ExamSessionDashboardView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ExamSessionDashboardController>(
          () => ExamSessionDashboardController(),
        );
      }),
    ),
  ];
}
