import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/attendance_models.dart';
import '../../demo/abu_demo_theme.dart';
import '../controller/general_exam_report_controller.dart';
import '../widgets/invigilator_light_panel.dart';
import '../widgets/invigilator_light_scaffold.dart';
import '../widgets/invigilator_top_actions.dart';

class GeneralExamReportView extends GetView<GeneralExamReportController> {
  const GeneralExamReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return InvigilatorLightScaffold(
      title: 'General Exam Reports',
      actions: buildInvigilatorTopActions(showReports: false),
      maxContentWidth: 1380,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.examOptions.isEmpty) {
          return const Center(child: Text('No examination data is available.'));
        }

        return ListView(
          children: [
            _ReportHeader(controller: controller),
            const SizedBox(height: 14),
            _PrimaryMetrics(controller: controller),
            const SizedBox(height: 14),
            _OperationalSummary(controller: controller),
            const SizedBox(height: 14),
            _HallBreakdown(controller: controller),
            const SizedBox(height: 14),
            _CandidateAudit(controller: controller),
          ],
        );
      }),
    );
  }
}

class _ReportHeader extends StatelessWidget {
  const _ReportHeader({required this.controller});

  final GeneralExamReportController controller;

  @override
  Widget build(BuildContext context) {
    return LightPanel(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final examPicker = DropdownButtonFormField<String>(
            initialValue: controller.selectedExam.value,
            isExpanded: true,
            items: controller.examOptions
                .map((exam) => DropdownMenuItem(value: exam, child: Text(exam)))
                .toList(),
            onChanged: (value) {
              if (value != null) controller.changeExam(value);
            },
            decoration: const InputDecoration(
              labelText: 'Examination',
              prefixIcon: Icon(Icons.menu_book_outlined),
            ),
          );

          final hallPicker = DropdownButtonFormField<String>(
            initialValue: controller.selectedHall.value,
            isExpanded: true,
            items: controller.hallOptions
                .map((hall) => DropdownMenuItem(value: hall, child: Text(hall)))
                .toList(),
            onChanged: (value) {
              if (value != null) controller.changeHall(value);
            },
            decoration: const InputDecoration(
              labelText: 'Report scope',
              prefixIcon: Icon(Icons.meeting_room_outlined),
            ),
          );

          final title = const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Examination Operations Report',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 5),
              Text(
                'Live report derived from attendance, identity verification, workstation assignments, technical operations, candidate controls, incidents and malpractice records.',
                style: TextStyle(
                  color: abuMuted,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
            ],
          );

          if (constraints.maxWidth < 900) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: 14),
                examPicker,
                const SizedBox(height: 10),
                hallPicker,
              ],
            );
          }

          return Row(
            children: [
              const Expanded(flex: 4, child: title),
              const SizedBox(width: 20),
              Expanded(flex: 3, child: examPicker),
              const SizedBox(width: 10),
              SizedBox(width: 220, child: hallPicker),
            ],
          );
        },
      ),
    );
  }
}

class _PrimaryMetrics extends StatelessWidget {
  const _PrimaryMetrics({required this.controller});

  final GeneralExamReportController controller;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        LightStatCard(
          title: 'Registered',
          value: '${controller.registeredCount}',
          icon: Icons.groups_outlined,
          width: 180,
        ),
        LightStatCard(
          title: 'Checked In',
          value: '${controller.checkedInCount}',
          icon: Icons.how_to_reg_outlined,
          width: 180,
        ),
        LightStatCard(
          title: 'Fingerprint',
          value: '${controller.fingerprintVerifiedCount}',
          icon: Icons.fingerprint_outlined,
          width: 180,
        ),
        LightStatCard(
          title: 'Manual Verified',
          value: '${controller.manualVerifiedCount}',
          icon: Icons.verified_user_outlined,
          width: 180,
        ),
        LightStatCard(
          title: 'In Exam',
          value: '${controller.inExamCount}',
          icon: Icons.desktop_windows_outlined,
          width: 180,
        ),
        LightStatCard(
          title: 'Submitted',
          value: '${controller.submittedCount}',
          icon: Icons.task_alt_outlined,
          width: 180,
        ),
        LightStatCard(
          title: 'Absent',
          value: '${controller.absentCount}',
          icon: Icons.person_off_outlined,
          width: 180,
        ),
      ],
    );
  }
}

class _OperationalSummary extends StatelessWidget {
  const _OperationalSummary({required this.controller});

  final GeneralExamReportController controller;

  @override
  Widget build(BuildContext context) {
    return LightPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Operational Events',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Every count below comes from an auditable operational record, not from manually typed report totals.',
            style: TextStyle(color: abuMuted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              _EventChip(
                icon: Icons.build_circle_outlined,
                label: 'Technical',
                value: controller.technicalReports.length,
              ),
              _EventChip(
                icon: Icons.swap_horiz_outlined,
                label: 'Workstation Transfers',
                value: controller.workstationTransfers.length,
              ),
              _EventChip(
                icon: Icons.tune_outlined,
                label: 'Candidate Controls',
                value: controller.examControlEvents.length,
              ),
              _EventChip(
                icon: Icons.done_all_outlined,
                label: 'Force Submitted',
                value: controller.forceSubmittedCount,
              ),
              _EventChip(
                icon: Icons.schedule_outlined,
                label: 'Late Entry',
                value: controller.lateEntryCount,
              ),
              _EventChip(
                icon: Icons.report_problem_outlined,
                label: 'Incidents',
                value: controller.incidents.length,
              ),
              _EventChip(
                icon: Icons.gpp_bad_outlined,
                label: 'Malpractice',
                value: controller.malpracticeReports.length,
              ),
              _EventChip(
                icon: Icons.person_search_outlined,
                label: 'Identity Reviews',
                value: controller.identityReviews.length,
              ),
              _EventChip(
                icon: Icons.receipt_long_outlined,
                label: 'Total Events',
                value: controller.totalOperationalEvents,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EventChip extends StatelessWidget {
  const _EventChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: abuCanvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: abuLine),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: abuGreen),
          const SizedBox(width: 7),
          Text(
            '$value',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: abuMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HallBreakdown extends StatelessWidget {
  const _HallBreakdown({required this.controller});

  final GeneralExamReportController controller;

  @override
  Widget build(BuildContext context) {
    final halls = controller.hallsForExam;
    return LightPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hall Breakdown',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'A hall-level view of candidate progress, identity exceptions and operational issues.',
            style: TextStyle(color: abuMuted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (halls.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text('No halls are associated with this examination.'),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Hall')),
                  DataColumn(label: Text('Registered')),
                  DataColumn(label: Text('In Exam')),
                  DataColumn(label: Text('Submitted')),
                  DataColumn(label: Text('Absent')),
                  DataColumn(label: Text('Manual ID')),
                  DataColumn(label: Text('Issues')),
                ],
                rows: halls.map((hall) {
                  final records = controller.candidatesForHall(hall);
                  return DataRow(
                    cells: [
                      DataCell(Text(hall)),
                      DataCell(Text('${records.length}')),
                      DataCell(Text('${controller.hallInExamCount(hall)}')),
                      DataCell(Text('${controller.hallSubmittedCount(hall)}')),
                      DataCell(Text('${controller.hallAbsentCount(hall)}')),
                      DataCell(Text('${controller.hallManualVerifiedCount(hall)}')),
                      DataCell(Text('${controller.hallIssueCount(hall)}')),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _CandidateAudit extends StatelessWidget {
  const _CandidateAudit({required this.controller});

  final GeneralExamReportController controller;

  @override
  Widget build(BuildContext context) {
    return LightPanel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final title = const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Candidate Audit',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Select a candidate to inspect identity method, workstation binding and related events.',
                      style: TextStyle(
                        color: abuMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
                final search = TextField(
                  controller: controller.searchController,
                  onChanged: controller.updateSearch,
                  decoration: const InputDecoration(
                    isDense: true,
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search name, reg no or workstation',
                    border: OutlineInputBorder(),
                  ),
                );

                if (constraints.maxWidth < 760) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title,
                      const SizedBox(height: 10),
                      search,
                    ],
                  );
                }
                return Row(
                  children: [
                    const Expanded(child: title),
                    const SizedBox(width: 16),
                    SizedBox(width: 330, child: search),
                  ],
                );
              },
            ),
          ),
          const Divider(height: 1),
          Obx(() {
            final items = controller.candidates;
            if (items.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(28),
                child: Center(child: Text('No candidates match this report scope.')),
              );
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Candidate')),
                  DataColumn(label: Text('Stage')),
                  DataColumn(label: Text('Identity')),
                  DataColumn(label: Text('Workstation')),
                  DataColumn(label: Text('Events')),
                  DataColumn(label: Text('')),
                ],
                rows: items.map((record) {
                  final eventCount = controller.attentionCountFor(
                    record.registrationNumber,
                  );
                  return DataRow(
                    onSelectChanged: (_) =>
                        _showCandidateDetails(context, controller, record),
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 220,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record.candidateName,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                              Text(
                                record.registrationNumber,
                                style: const TextStyle(
                                  color: abuMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      DataCell(_Tag(label: controller.stageLabel(record.state))),
                      DataCell(_Tag(label: controller.identityLabel(record))),
                      DataCell(
                        SizedBox(
                          width: 190,
                          child: Text(
                            record.workstationId.isEmpty
                                ? 'Not assigned'
                                : '${record.seatNumber} • ${record.workstationId}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(Text('$eventCount')),
                      const DataCell(Icon(Icons.chevron_right, size: 19)),
                    ],
                  );
                }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: abuGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: abuGreen.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}

Future<void> _showCandidateDetails(
  BuildContext context,
  GeneralExamReportController controller,
  AttendanceRecord record,
) async {
  final identityReviews = controller.identityReviewsFor(record.registrationNumber);
  final controlEvents = controller.controlEventsFor(record.registrationNumber);
  final incidentCount = controller.incidentCountFor(record.registrationNumber);
  final malpracticeCount = controller.malpracticeCountFor(record.registrationNumber);
  final technicalCount = controller.technicalCountFor(record.registrationNumber);
  final transferCount = controller.transferCountFor(record.registrationNumber);

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(record.candidateName),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Detail('Registration', record.registrationNumber),
              _Detail('Exam', record.examTitle),
              _Detail('Hall', record.hallName),
              _Detail(
                'Workstation',
                record.workstationId.isEmpty
                    ? 'Not assigned'
                    : '${record.seatNumber} • ${record.workstationId}',
              ),
              _Detail('Stage', controller.stageLabel(record.state)),
              _Detail('Identity method', controller.identityLabel(record)),
              if (record.manualIdentityVerified) ...[
                _Detail('Manual verified by', record.manualVerifiedBy),
                _Detail('Identity audit ID', record.manualVerificationAuditId),
                if (record.manualVerifiedAt != null)
                  _Detail('Manual verified at', record.manualVerifiedAt!.toIso8601String()),
              ],
              if (record.verificationNote.isNotEmpty)
                _Detail('Verification note', record.verificationNote),
              const Divider(height: 28),
              const Text(
                'Related operational records',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              _Detail('Candidate controls', '${controlEvents.length}'),
              _Detail('Incidents', '$incidentCount'),
              _Detail('Malpractice reports', '$malpracticeCount'),
              _Detail('Technical reports', '$technicalCount'),
              _Detail('Workstation transfers', '$transferCount'),
              _Detail('Identity review requests', '${identityReviews.length}'),
              if (controlEvents.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Candidate control history',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                ...controlEvents.map(
                  (event) => Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Text(
                      '${event.type.label} • ${event.actedBy} • ${event.createdAt.toIso8601String()}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
              if (identityReviews.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Identity review history',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                ...identityReviews.map(
                  (request) => Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Text(
                      '${request.id} • ${request.status.label} • ${request.failureReason.label}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

class _Detail extends StatelessWidget {
  const _Detail(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 145,
            child: Text(
              label,
              style: const TextStyle(
                color: abuMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
