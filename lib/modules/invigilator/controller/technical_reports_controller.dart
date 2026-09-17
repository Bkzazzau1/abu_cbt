import 'package:get/get.dart';

import '../../../data/models/technical_report_models.dart';
import '../../../data/services/invigilator_demo_store.dart';

class TechnicalReportsController extends GetxController {
  final isLoading = false.obs;
  final selectedHall = 'All Halls'.obs;
  final selectedStatus = 'All Statuses'.obs;

  late final InvigilatorDemoStore _store;

  @override
  void onInit() {
    super.onInit();
    _store = Get.isRegistered<InvigilatorDemoStore>()
        ? Get.find<InvigilatorDemoStore>()
        : Get.put(InvigilatorDemoStore(), permanent: true);
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      await _store.ensureLoaded();
    } finally {
      isLoading.value = false;
    }
  }

  List<String> get hallOptions {
    final halls = _store.seats.map((e) => e.hallName).toSet().toList()..sort();
    return ['All Halls', ...halls];
  }

  List<String> get statusOptions => const [
        'All Statuses',
        'Open',
        'In Progress',
        'Resolved',
      ];

  List<TechnicalReportRecord> get filteredReports {
    final items = _store.technicalReports.where((report) {
      final hallOk = selectedHall.value == 'All Halls' ||
          report.hallName == selectedHall.value;
      final statusOk = switch (selectedStatus.value) {
        'Open' => report.status == TechnicalIssueStatus.open,
        'In Progress' => report.status == TechnicalIssueStatus.inProgress,
        'Resolved' => report.status == TechnicalIssueStatus.resolved,
        _ => true,
      };
      return hallOk && statusOk;
    }).toList();

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  List<WorkstationHealthRecord> get filteredHealth {
    final items = _store.buildWorkstationHealth().where((record) {
      return selectedHall.value == 'All Halls' ||
          record.hallName == selectedHall.value;
    }).toList();
    items.sort((a, b) {
      final byHall = a.hallName.compareTo(b.hallName);
      if (byHall != 0) return byHall;
      return a.seatNumber.compareTo(b.seatNumber);
    });
    return items;
  }

  int get totalWorkstations => filteredHealth.length;
  int get healthyCount => filteredHealth
      .where((e) => e.state == WorkstationHealthState.healthy)
      .length;
  int get degradedCount => filteredHealth
      .where((e) => e.state == WorkstationHealthState.degraded)
      .length;
  int get offlineCount => filteredHealth
      .where((e) => e.state == WorkstationHealthState.offline)
      .length;
  int get criticalCount => filteredHealth
      .where((e) => e.state == WorkstationHealthState.critical)
      .length;

  int get openReportCount => _store.technicalReports
      .where((e) => e.status == TechnicalIssueStatus.open)
      .length;
  int get inProgressReportCount => _store.technicalReports
      .where((e) => e.status == TechnicalIssueStatus.inProgress)
      .length;
  int get resolvedReportCount => _store.technicalReports
      .where((e) => e.status == TechnicalIssueStatus.resolved)
      .length;

  void updateHall(String value) {
    selectedHall.value = value;
  }

  void updateStatus(String value) {
    selectedStatus.value = value;
  }

  void markInProgress(TechnicalReportRecord report) {
    _store.updateTechnicalReportStatus(
      report.id,
      TechnicalIssueStatus.inProgress,
    );
  }

  void resolve(TechnicalReportRecord report) {
    _store.updateTechnicalReportStatus(
      report.id,
      TechnicalIssueStatus.resolved,
    );
  }

  void reopen(TechnicalReportRecord report) {
    _store.updateTechnicalReportStatus(
      report.id,
      TechnicalIssueStatus.open,
    );
  }
}
