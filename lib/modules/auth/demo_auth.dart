import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/routes/app_routes.dart';
import '../../data/models/center_exam_models.dart';
import '../../data/services/center_exam_service.dart';
import '../../data/services/invigilator_session.dart';
import '../exam/controller/center_exam_run_controller.dart';
import '../portal/controller/center_exam_portal_controller.dart';

class DemoAccount {
  const DemoAccount(this.role, this.username, this.name);
  final String role, username, name;
  String get initials => name.split(' ').take(2).map((s) => s[0]).join();
}

/// Demo-only account separation. Student records represent university-held
/// examination records; students do not create or register these profiles.
class DemoAuth {
  static final instance = DemoAuth();
  DemoAccount? account;
  CenterLoginResult? student;

  static const samples = <String, List<(String, String, String)>>{
    'Administrator': [('admin.abu', 'AbuAdmin123!', 'ABU Administrator')],
    'Invigilator': [
      ('invigilator.a', 'invA123', 'Amina Yusuf'),
      ('invigilator.b', 'invB123', 'Musa Ibrahim'),
      ('chief.invigilator', 'chief123', 'Chief Invigilator'),
    ],
    'Student': [
      ('ABU/CSC/001', 'cbt001', 'Zainab Musa'),
      ('ABU/MTH/004', 'cbt004', 'Ibrahim Bashir Yahaya'),
      ('ABU/GST/011', 'cbt011', 'Maryam Bello'),
      ('ABU/CSC/008', 'cbt008', 'Sadiq Lawal'),
      ('ABU/BIO/002', 'cbt002', 'Fatima Musa'),
      ('ABU/CHM/007', 'cbt007', 'Umar Aliyu'),
      ('ABU/PHY/003', 'cbt003', 'Aisha Bello'),
    ],
  };

  /// Opens a student session from an existing university examination record.
  /// This is a record lookup/login step only. Final biometric authentication
  /// happens immediately before the examination is unlocked.
  bool beginStudentSession(String registrationNumber) {
    final session = CenterExamService.restoreCandidateSession(registrationNumber);
    if (session == null) return false;

    student = session;
    account = DemoAccount(
      'Student',
      session.candidate.registrationNumber,
      session.candidate.fullName,
    );
    return true;
  }

  Future<bool> signIn(String role, String username, String password) async {
    if (role == 'Student') return false;
    final match = samples[role]
        ?.where(
          (a) =>
              a.$1.toLowerCase() == username.trim().toLowerCase() &&
              a.$2 == password,
        )
        .firstOrNull;
    if (match == null) return false;
    account = DemoAccount(role, match.$1, match.$3);
    student = null;
    return true;
  }

  Future<void> openWorkspace() async {
    if (student != null) {
      final controller = Get.isRegistered<CenterExamPortalController>()
          ? Get.find<CenterExamPortalController>()
          : Get.put(CenterExamPortalController(), permanent: true);
      await controller.loadCandidateSession(student!, persist: false);
      Get.offAllNamed(Routes.centerPortal);
      return;
    }
    if (account?.role == 'Invigilator') {
      // The real, backend-wired workstation console (evidence review,
      // malpractice reports, terminate exam) rather than the cosmetic
      // Overview/Hall monitoring/Attendance/Candidates/Incidents tabs in
      // the shared admin+invigilator demo workspace below — Administrator
      // still goes there since its broader tour (exam authoring, question
      // bank, results, settings) has no equivalent here.
      InvigilatorSession.currentName = account!.name;
      Get.offAllNamed(Routes.invigilatorDashboard);
      return;
    }
    Get.offAllNamed(Routes.demo);
  }

  Future<void> signOut() async {
    account = null;
    student = null;
    InvigilatorSession.currentName = '';
    if (Get.isRegistered<CenterExamRunController>()) {
      Get.delete<CenterExamRunController>(force: true);
    }
    if (Get.isRegistered<CenterExamPortalController>()) {
      Get.delete<CenterExamPortalController>(force: true);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('center_exam.saved_candidate_reg_no');
    Get.offAllNamed(Routes.centerLogin);
  }
}

class DemoRouteGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (route == Routes.centerLogin || route == Routes.invigilatorLogin) {
      return null;
    }

    final role = DemoAuth.instance.account?.role;
    if (role == null) return const RouteSettings(name: Routes.centerLogin);

    const studentRoutes = [
      Routes.centerPortal,
      Routes.centerExamConfirmation,
      Routes.centerExamInstruction,
      Routes.centerExamFingerprint,
      Routes.centerExamRun,
      Routes.centerExamSubmit,
      Routes.deviceRegistration,
    ];

    if (role == 'Student') {
      if (studentRoutes.contains(route)) return null;
      return const RouteSettings(name: Routes.centerPortal);
    }

    if (studentRoutes.contains(route)) {
      return const RouteSettings(name: Routes.demo);
    }

    return null;
  }
}
