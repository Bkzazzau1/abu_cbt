import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';

class InvigilatorLoginController extends GetxController {
  static const Map<String, String> _credentials = {
    'invigilator.a': 'invA123',
    'invigilator.b': 'invB123',
    'chief.invigilator': 'chief123',
  };

  final isLoading = false.obs;

  Future<void> login({
    required String username,
    required String password,
  }) async {
    if (isLoading.value) return;

    final normalizedUsername = username.trim().toLowerCase();
    final normalizedPassword = password.trim();

    if (normalizedUsername.isEmpty || normalizedPassword.isEmpty) {
      Get.snackbar(
        'Missing details',
        'Enter username and password.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final expectedPassword = _credentials[normalizedUsername];
    if (expectedPassword == null || expectedPassword != normalizedPassword) {
      Get.snackbar(
        'Login failed',
        'Invalid invigilator username or password.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 500));
    isLoading.value = false;

    Get.offAllNamed(Routes.invigilatorDashboard);
  }
}
