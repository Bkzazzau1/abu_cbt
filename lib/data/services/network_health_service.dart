import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

import '../models/workstation_models.dart';

class NetworkHealthService extends GetxService {
  final status = NetworkHealthStatus.online.obs;

  StreamSubscription<List<ConnectivityResult>>? _sub;

  Future<NetworkHealthService> init() async {
    final current = await Connectivity().checkConnectivity();
    _apply(current);
    _sub = Connectivity().onConnectivityChanged.listen(_apply);
    return this;
  }

  void _apply(List<ConnectivityResult> results) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      status.value = NetworkHealthStatus.offline;
      return;
    }

    if (results.contains(ConnectivityResult.mobile)) {
      status.value = NetworkHealthStatus.lowNetwork;
      return;
    }

    status.value = NetworkHealthStatus.online;
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
