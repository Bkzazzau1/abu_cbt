import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../data/models/workstation_models.dart';
import '../../../data/services/workstation_service.dart';

class WorkstationGateController extends GetxController {
  final isLoading = true.obs;
  final registration = Rxn<WorkstationRegistration>();

  @override
  void onInit() {
    super.onInit();
    initGate();
  }

  Future<void> initGate() async {
    isLoading.value = true;
    try {
      final reg = await WorkstationService.touchLastSeen();
      registration.value = reg;

      switch (reg.status) {
        case WorkstationStatus.whitelisted:
          Get.offAllNamed(Routes.centerLogin);
          break;
        case WorkstationStatus.pending:
          Get.offAllNamed(Routes.deviceRegistration);
          break;
        case WorkstationStatus.disabled:
        case WorkstationStatus.revoked:
          Get.offAllNamed(Routes.deviceBlocked);
          break;
      }
    } finally {
      isLoading.value = false;
    }
  }
}
