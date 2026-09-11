import 'package:get/get.dart';

import '../../../data/models/seat_map_models.dart';
import '../../../data/services/seat_map_mock_service.dart';

class SeatMapController extends GetxController {
  final isLoading = false.obs;
  final records = <SeatMapRecord>[].obs;
  final selectedHall = 'Hall A'.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      final items = await SeatMapMockService.loadSeatMap();
      records.assignAll(items);

      final halls = hallOptions;
      if (halls.isNotEmpty && !halls.contains(selectedHall.value)) {
        selectedHall.value = halls.first;
      }
    } finally {
      isLoading.value = false;
    }
  }

  List<String> get hallOptions {
    final halls = records.map((e) => e.hallName).toSet().toList()..sort();
    return halls;
  }

  List<SeatMapRecord> get currentHallSeats {
    final hall = selectedHall.value;
    final items = records.where((e) => e.hallName == hall).toList();

    items.sort((a, b) => a.seatNumber.compareTo(b.seatNumber));
    return items;
  }

  void changeHall(String hall) {
    selectedHall.value = hall;
  }
}
