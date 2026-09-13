import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/routes/app_routes.dart';
import '../../data/models/center_exam_models.dart';
import '../../data/services/center_exam_service.dart';
import '../portal/controller/center_exam_portal_controller.dart';
import '../exam/controller/center_exam_run_controller.dart';
import 'fingerprint_reader.dart';

class DemoAccount {
  const DemoAccount(this.role, this.username, this.name);
  final String role, username, name;
  String get initials => name.split(' ').take(2).map((s) => s[0]).join();
}

/// Demo-only account separation. Credentials are sample data, not a backend.
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
  bool completeStudentFingerprint(
    String registration,
    FingerprintResult verification,
  ) {
    if (verification != FingerprintResult.matched) return false;
    final session = CenterExamService.restoreCandidateSession(registration);
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
    }
    Get.offAllNamed(Routes.demo);
  }

  Future<void> signOut() async {
    account = null;
    student = null;
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
      Routes.centerExamInstruction,
      Routes.centerExamConfirmation,
      Routes.centerExamRun,
      Routes.centerExamSubmit,
    ];
    if (route == Routes.demo) return null;
    if (role == 'Student' && !studentRoutes.contains(route)) {
      return const RouteSettings(name: Routes.demo);
    }
    if (role != 'Student' && studentRoutes.contains(route)) {
      return const RouteSettings(name: Routes.demo);
    }
    return null;
  }
}
