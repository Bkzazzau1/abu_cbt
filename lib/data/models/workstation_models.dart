enum WorkstationStatus { pending, whitelisted, disabled, revoked }

enum NetworkHealthStatus { online, lowNetwork, offline }

class WorkstationRegistration {
  WorkstationRegistration({
    required this.workstationId,
    required this.centerName,
    required this.hallName,
    required this.seatNumber,
    required this.status,
    required this.installedAtIso,
    required this.lastSeenAtIso,
  });

  final String workstationId;
  final String centerName;
  final String hallName;
  final String seatNumber;
  final WorkstationStatus status;
  final String installedAtIso;
  final String lastSeenAtIso;

  WorkstationRegistration copyWith({
    String? workstationId,
    String? centerName,
    String? hallName,
    String? seatNumber,
    WorkstationStatus? status,
    String? installedAtIso,
    String? lastSeenAtIso,
  }) {
    return WorkstationRegistration(
      workstationId: workstationId ?? this.workstationId,
      centerName: centerName ?? this.centerName,
      hallName: hallName ?? this.hallName,
      seatNumber: seatNumber ?? this.seatNumber,
      status: status ?? this.status,
      installedAtIso: installedAtIso ?? this.installedAtIso,
      lastSeenAtIso: lastSeenAtIso ?? this.lastSeenAtIso,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'workstationId': workstationId,
      'centerName': centerName,
      'hallName': hallName,
      'seatNumber': seatNumber,
      'status': status.name,
      'installedAtIso': installedAtIso,
      'lastSeenAtIso': lastSeenAtIso,
    };
  }

  factory WorkstationRegistration.fromJson(Map<String, dynamic> json) {
    return WorkstationRegistration(
      workstationId: (json['workstationId'] ?? '').toString(),
      centerName: (json['centerName'] ?? '').toString(),
      hallName: (json['hallName'] ?? '').toString(),
      seatNumber: (json['seatNumber'] ?? '').toString(),
      status: WorkstationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => WorkstationStatus.pending,
      ),
      installedAtIso: (json['installedAtIso'] ?? '').toString(),
      lastSeenAtIso: (json['lastSeenAtIso'] ?? '').toString(),
    );
  }
}
