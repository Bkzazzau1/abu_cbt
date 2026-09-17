import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/ks_status_chip.dart';
import '../../../data/models/attendance_models.dart';
import '../../../data/models/hall_monitor_models.dart';
import '../controller/attendance_register_controller.dart';
import '../widgets/invigilator_light_panel.dart';
import '../widgets/invigilator_light_scaffold.dart';
import '../widgets/invigilator_top_actions.dart';

class AttendanceRegisterView extends GetView<AttendanceRegisterController> {
  const AttendanceRegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return InvigilatorLightScaffold(
      title: 'Attendance Register',
      actions: buildInvigilatorTopActions(
          showAttendance: false,
          showSeatMap: true,
        ),
      body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: [
            _SummaryRow(controller: controller),
            const SizedBox(height: 16),
            LightPanel(
              child: Column(
                children: [
                  TextField(
                    controller: controller.searchController,
                    onChanged: controller.updateSearch,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Search candidate, reg no, seat, exam',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => DropdownButtonFormField<String>(
                      initialValue: controller.selectedHall.value,
                      dropdownColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.96,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      items: controller.hallOptions
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) controller.updateHall(v);
                      },
                      decoration: const InputDecoration(
                        labelText: 'Hall',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Obx(() {
              final items = controller.filteredRecords;
              if (items.isEmpty) {
                return const LightPanel(
                  child: Text('No attendance records found.'),
                );
              }

              return Column(
                children: items
                    .map(
                      (record) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _AttendanceCard(
                          record: record,
                          controller: controller,
                        ),
                      ),
                    )
                    .toList(),
              );
            }),
            ],
          );
        }),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.controller});

  final AttendanceRegisterController controller;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        LightStatCard(
          title: 'Expected',
          value: '${controller.expectedCount}',
          width: 170,
          layout: LightStatCardLayout.column,
        ),
        LightStatCard(
          title: 'Present',
          value: '${controller.presentCount}',
          width: 170,
          layout: LightStatCardLayout.column,
        ),
        LightStatCard(
          title: 'Seated',
          value: '${controller.seatedCount}',
          width: 170,
          layout: LightStatCardLayout.column,
        ),
        LightStatCard(
          title: 'Absent',
          value: '${controller.absentCount}',
          width: 170,
          layout: LightStatCardLayout.column,
        ),
      ],
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({required this.record, required this.controller});

  final AttendanceRecord record;
  final AttendanceRegisterController controller;

  @override
  Widget build(BuildContext context) {
    return LightPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  record.candidateName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _stateChip(record.state),
            ],
          ),
          const SizedBox(height: 8),
          Text(record.registrationNumber),
          Text('${record.hallName} • Seat ${record.seatNumber}'),
          Text(record.examTitle),
          Text('Workstation: ${record.workstationId}'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => controller.markPresent(record),
                child: const Text('Mark Present'),
              ),
              OutlinedButton(
                onPressed: () => controller.markSeated(record),
                child: const Text('Mark Seated'),
              ),
              OutlinedButton(
                onPressed: () => controller.markAuthorized(record),
                child: const Text('Authorize'),
              ),
              OutlinedButton(
                onPressed: () => controller.markAbsent(record),
                child: const Text('Absent'),
              ),
              FilledButton.tonal(
                onPressed: () {
                  final hallRecord = HallMonitorRecord(
                    workstationId: record.workstationId,
                    hallName: record.hallName,
                    seatNumber: record.seatNumber,
                    candidateName: record.candidateName,
                    registrationNumber: record.registrationNumber,
                    examTitle: record.examTitle,
                    state: HallCandidateLiveState.checkedIn,
                    lastSeenLabel: 'Just now',
                    hasIncident: false,
                    hasMalpractice: false,
                  );
                  Get.toNamed(Routes.candidateCheckIn, arguments: hallRecord);
                },
                child: const Text('Open Check-In'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stateChip(AttendanceState state) {
    late final String text;
    late final KsStatusChipTone tone;

    switch (state) {
      case AttendanceState.expected:
        text = 'Expected';
        tone = KsStatusChipTone.neutral;
        break;
      case AttendanceState.present:
        text = 'Present';
        tone = KsStatusChipTone.info;
        break;
      case AttendanceState.absent:
        text = 'Absent';
        tone = KsStatusChipTone.danger;
        break;
      case AttendanceState.seated:
        text = 'Seated';
        tone = KsStatusChipTone.warningSoft;
        break;
      case AttendanceState.authorized:
        text = 'Authorized';
        tone = KsStatusChipTone.success;
        break;
      case AttendanceState.inExam:
        text = 'In Exam';
        tone = KsStatusChipTone.success;
        break;
      case AttendanceState.submitted:
        text = 'Submitted';
        tone = KsStatusChipTone.accent;
        break;
    }

    return KsStatusChip(label: text, tone: tone);
  }
}
