import 'package:get/get.dart';

import '../../../data/models/seat_map_models.dart';
import '../../../data/services/invigilator_demo_store.dart';

class SeatMapController extends GetxController {
  final isLoading = false.obs;
  final selectedHall = 'Hall A'.obs;

  late final InvigilatorDemoStore _demoStore;

  @override
  void onInit() {
    super.onInit();
    _demoStore = Get.isRegistered<InvigilatorDemoStore>()
        ? Get.find<InvigilatorDemoStore>()
        : Get.put(InvigilatorDemoStore(), permanent: true);
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      await _demoStore.ensureLoaded();

      final halls = hallOptions;
      if (halls.isNotEmpty && !halls.contains(selectedHall.value)) {
        selectedHall.value = halls.first;
      }
    } finally {
      isLoading.value = false;
    }
  }

  List<String> get hallOptions {
    final halls = _demoStore.seats.map((e) => e.hallName).toSet().toList()..sort();
    return halls;
  }

  List<SeatMapRecord> get currentHallSeats {
    final hall = selectedHall.value;
    final items = _demoStore.seats.where((e) => e.hallName == hall).toList();
    items.sort((a, b) => a.seatNumber.compareTo(b.seatNumber));
    return items;
  }

  void changeHall(String hall) {
    selectedHall.value = hall;
  }
}
