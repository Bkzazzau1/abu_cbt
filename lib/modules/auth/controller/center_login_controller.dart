import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../data/models/center_exam_models.dart';
import '../../../data/models/invigilator_models.dart';
import '../../../data/models/workstation_presence_models.dart';
import '../../../data/models/workstation_models.dart';
import '../../../data/services/center_exam_service.dart';
import '../../../data/services/hall_network_risk_service.dart';
import '../../../data/services/workstation_presence_ws_service.dart';
import '../../../data/services/workstation_service.dart';
import '../../portal/controller/center_exam_portal_controller.dart';

class CenterLoginController extends GetxController {
  final isLoading = false.obs;

  Future<void> login({
    required String registrationNumber,
    required String password,
  }) async {
    if (isLoading.value) return;

    isLoading.value = true;
    try {
      final result = await CenterExamService.login(
        registrationNumber: registrationNumber.trim(),
        password: password,
      );

      if (result == null) {
        Get.snackbar(
          'Login failed',
          'Invalid registration number or password.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final portal = Get.isRegistered<CenterExamPortalController>()
          ? Get.find<CenterExamPortalController>()
          : Get.put(CenterExamPortalController());

      portal.loadCandidateSession(result);
      await _emitLoginPresence(result);

      Get.offAllNamed(Routes.centerPortal);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _emitLoginPresence(CenterLoginResult result) async {
    try {
      final registration =
          await WorkstationService.ensureAssignmentFromAttendance(
            candidateRegistrationNumber: result.candidate.registrationNumber,
          );
      if (registration.workstationId.trim().isEmpty) return;

      CenterExam? liveExam;
      for (final item in result.exams) {
        if (item.status == CenterExamStatus.dueNow) {
          liveExam = item;
          break;
        }
      }

      final wsService = Get.isRegistered<WorkstationPresenceWsService>()
          ? Get.find<WorkstationPresenceWsService>()
          : Get.put(WorkstationPresenceWsService());

      final isApproved = registration.status == WorkstationStatus.whitelisted;
      final isNewDevice = !await WorkstationService.hasSubmissionHistory(
        registration.workstationId,
      );
      final ipAssessment = await HallNetworkRiskService.assess(
        hallName: registration.hallName,
      );
      final reasons = <String>[];
      if (!isApproved) {
        reasons.add('Workstation ID is not yet whitelisted by invigilator.');
      }
      if (isNewDevice) {
        reasons.add('New workstation detected (no prior submission history).');
      }

      var ipInRange = ipAssessment.matchesExpectedRange;
      if (!ipAssessment.hasExpectedRange || !ipAssessment.hasIp) {
        ipInRange = false;
      }
      if (!ipInRange) {
        reasons.add(
          ipAssessment.hasIp && ipAssessment.hasExpectedRange
              ? 'IP ${ipAssessment.ipAddress} is outside hall range ${ipAssessment.expectedRangeLabel}.'
              : 'IP range verification could not be completed.',
        );
      }

      var riskScore = 0;
      if (!isApproved) riskScore += 45;
      if (isNewDevice) riskScore += 25;
      if (!ipInRange) {
        riskScore = riskScore < 90 ? 90 : riskScore;
      }
      if (riskScore > 100) riskScore = 100;
      final riskLevel = switch (riskScore) {
        >= 90 => 'critical',
        >= 70 => 'high',
        >= 40 => 'medium',
        _ => 'low',
      };

      await wsService.connectWorkstation();
      wsService.sendHeartbeat(
        WorkstationPresenceRecord(
          workstationId: registration.workstationId,
          centerName: registration.centerName.isEmpty
              ? 'ABU'
              : registration.centerName,
          hallName: registration.hallName,
          seatNumber: registration.seatNumber,
          registrationNumber: result.candidate.registrationNumber,
          candidateName: result.candidate.fullName,
          examTitle: liveExam == null
              ? ''
              : '${liveExam.courseCode} - ${liveExam.courseTitle}',
          usageState: WorkstationUsageState.candidateLoggedIn,
          workstationStatus: registration.status,
          eventAtIso: DateTime.now().toIso8601String(),
          workstationApproved: isApproved,
          riskFlagged: reasons.isNotEmpty,
          riskScore: riskScore,
          riskLevel: riskLevel,
          isNewWorkstation: isNewDevice,
          clientIpAddress: ipAssessment.ipAddress,
          expectedHallIpRange: ipAssessment.expectedRangeLabel,
          ipInExpectedRange: ipInRange,
          riskReasons: reasons,
        ),
      );
    } catch (_) {
      // WebSocket heartbeat should never block candidate login.
    }
  }
}
