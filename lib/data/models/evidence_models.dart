/// Structured on-device detection evidence for invigilator review — timing
/// (and a confidence score, where the detector produces one) computed on
/// the candidate's own workstation. Never a saved camera frame (the
/// detector never writes frames to disk — see
/// backend/object_detection/README.md) and never a recorded audio clip (the
/// microphone check classifies and immediately discards each ~30ms block).
/// This is the machine's own account of what it detected, not proof of
/// misconduct; final judgment stays with the invigilator/exam officer.
class EvidenceType {
  EvidenceType._();

  static const phone = 'phone';
  static const identity = 'identity';
  static const talking = 'talking';
  static const usb = 'usb';
}

class EvidenceEvent {
  EvidenceEvent({
    required this.id,
    required this.workstationId,
    required this.centerName,
    required this.hallName,
    required this.seatNumber,
    required this.registrationNumber,
    required this.candidateName,
    required this.examTitle,
    required this.evidenceType,
    this.confidence,
    this.details = '',
    required this.detectedAtIso,
    this.escalated = false,
    this.escalatedBy = '',
    this.escalatedAtIso = '',
  });

  final String id;
  final String workstationId;
  final String centerName;
  final String hallName;
  final String seatNumber;
  final String registrationNumber;
  final String candidateName;
  final String examTitle;
  final String evidenceType;
  final double? confidence;
  final String details;
  final String detectedAtIso;
  final bool escalated;
  final String escalatedBy;
  final String escalatedAtIso;

  factory EvidenceEvent.fromJson(Map<String, dynamic> json) {
    return EvidenceEvent(
      id: (json['id'] ?? '').toString(),
      workstationId: (json['workstationId'] ?? '').toString(),
      centerName: (json['centerName'] ?? '').toString(),
      hallName: (json['hallName'] ?? '').toString(),
      seatNumber: (json['seatNumber'] ?? '').toString(),
      registrationNumber: (json['registrationNumber'] ?? '').toString(),
      candidateName: (json['candidateName'] ?? '').toString(),
      examTitle: (json['examTitle'] ?? '').toString(),
      evidenceType: (json['evidenceType'] ?? '').toString(),
      confidence: (json['confidence'] as num?)?.toDouble(),
      details: (json['details'] ?? '').toString(),
      detectedAtIso: (json['detectedAtIso'] ?? '').toString(),
      escalated: json['escalated'] == true,
      escalatedBy: (json['escalatedBy'] ?? '').toString(),
      escalatedAtIso: (json['escalatedAtIso'] ?? '').toString(),
    );
  }
}
