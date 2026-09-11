import 'package:get/get.dart';

import '../../../data/models/workstation_models.dart';
import '../../../data/services/workstation_service.dart';

class DeviceBlockedController extends GetxController {
  final registration = Rxn<WorkstationRegistration>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    registration.value = await WorkstationService.loadOrCreate();
  }
}
