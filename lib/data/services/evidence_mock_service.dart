import '../models/evidence_models.dart';

/// Sample detection evidence for demos/presentations, so the dashboard's
/// evidence feed has realistic content to show without needing a live
/// candidate session actually tripping the detector. Reuses the same
/// workstation/candidate identities as [InvigilatorMockService] so the
/// dashboard reads as one consistent scenario. These ids are local to this
/// mock (prefixed `DEMO-`) and are never submitted to a real backend, so
/// escalating one during a demo without a live server connected is a
/// harmless no-op, same as the other mock-seeded actions on this dashboard.
class EvidenceMockService {
  static Future<List<EvidenceEvent>> loadEvidenceEvents() async {
    await Future.delayed(const Duration(milliseconds: 400));
    final now = DateTime.now().toUtc();

    return <EvidenceEvent>[
      EvidenceEvent(
        id: 'DEMO-phone-001',
        workstationId: 'ABU-CBT-A12F-93KD-7M21',
        centerName: 'ABU',
        hallName: 'Hall A',
        seatNumber: 'A-01',
        registrationNumber: 'ABU/CSC/001',
        candidateName: 'Zainab Musa',
        examTitle: 'CSC 305 - Data Structures',
        evidenceType: EvidenceType.phone,
        confidence: 0.91,
        details: 'Possible phone in view.',
        detectedAtIso: now
            .subtract(const Duration(minutes: 3))
            .toIso8601String(),
      ),
      EvidenceEvent(
        id: 'DEMO-identity-001',
        workstationId: 'ABU-CBT-B74L-18QX-4N22',
        centerName: 'ABU',
        hallName: 'Hall A',
        seatNumber: 'A-02',
        registrationNumber: 'ABU/MTH/004',
        candidateName: 'Bashir Yahaya',
        examTitle: 'MTH 202 - Linear Algebra',
        evidenceType: EvidenceType.identity,
        details:
            'Identity snapshot did not match the enrolled photo (distance 82.4).',
        detectedAtIso: now
            .subtract(const Duration(minutes: 11))
            .toIso8601String(),
        escalated: true,
        escalatedBy: 'invigilator.a',
        escalatedAtIso: now
            .subtract(const Duration(minutes: 9))
            .toIso8601String(),
      ),
      EvidenceEvent(
        id: 'DEMO-talking-001',
        workstationId: 'ABU-CBT-D43R-29HJ-8W10',
        centerName: 'ABU',
        hallName: 'Hall A',
        seatNumber: 'A-04',
        registrationNumber: 'ABU/GST/011',
        candidateName: 'Maryam Bello',
        examTitle: 'GST 201 - Use of English',
        evidenceType: EvidenceType.talking,
        confidence: 0.63,
        details:
            'Elevated talking near this seat. No audio was recorded or transcribed.',
        detectedAtIso: now
            .subtract(const Duration(minutes: 6))
            .toIso8601String(),
      ),
      EvidenceEvent(
        id: 'DEMO-usb-001',
        workstationId: 'ABU-CBT-E18X-64BV-5K31',
        centerName: 'ABU',
        hallName: 'Hall B',
        seatNumber: 'B-01',
        registrationNumber: 'ABU/PHY/007',
        candidateName: 'Ibrahim Sule',
        examTitle: 'PHY 101 - General Physics',
        evidenceType: EvidenceType.usb,
        details: 'USB device connected: USB Mass Storage (SanDisk Cruzer).',
        detectedAtIso: now
            .subtract(const Duration(minutes: 1))
            .toIso8601String(),
      ),
    ];
  }
}
