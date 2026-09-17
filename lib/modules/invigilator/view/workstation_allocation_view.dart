import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/workstation_assignment_models.dart';
import '../../demo/abu_demo_theme.dart';
import '../controller/workstation_allocation_controller.dart';
import '../widgets/invigilator_light_panel.dart';
import '../widgets/invigilator_light_scaffold.dart';
import '../widgets/invigilator_top_actions.dart';

class WorkstationAllocationView
    extends GetView<WorkstationAllocationController> {
  const WorkstationAllocationView({super.key});

  @override
  Widget build(BuildContext context) {
    return InvigilatorLightScaffold(
      title: 'Workstation Allocation',
      actions: buildInvigilatorTopActions(showAllocation: false),
      maxContentWidth: 1280,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          children: [
            _ExamContextPanel(controller: controller),
            const SizedBox(height: 14),
            _SummaryPanel(controller: controller),
            const SizedBox(height: 14),
            _AllocationPolicyPanel(controller: controller),
            const SizedBox(height: 14),
            _ModeActionPanel(controller: controller),
            const SizedBox(height: 14),
            _AssignmentTable(controller: controller),
          ],
        );
      }),
    );
  }
}

class _ExamContextPanel extends StatelessWidget {
  const _ExamContextPanel({required this.controller});

  final WorkstationAllocationController controller;

  @override
  Widget build(BuildContext context) {
    return LightPanel(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Candidate ↔ Workstation Assignment',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 5),
              Text(
                controller.currentExamTitle,
                style: const TextStyle(
                  color: abuGreen,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'The seat number identifies the physical workstation only. A candidate is bound to that workstation for this exam session, not permanently allocated to the seat.',
                style: TextStyle(
                  color: abuMuted,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
            ],
          );

          final hallPicker = SizedBox(
            width: 260,
            child: DropdownButtonFormField<String>(
              initialValue: controller.selectedHall.value,
              items: controller.hallOptions
                  .map(
                    (hall) => DropdownMenuItem(value: hall, child: Text(hall)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) controller.changeHall(value);
              },
              decoration: const InputDecoration(
                labelText: 'Hall',
                prefixIcon: Icon(Icons.meeting_room_outlined),
              ),
            ),
          );

          if (constraints.maxWidth < 760) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [details, const SizedBox(height: 14), hallPicker],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: details),
              const SizedBox(width: 24),
              hallPicker,
            ],
          );
        },
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({required this.controller});

  final WorkstationAllocationController controller;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        LightStatCard(
          title: 'Candidates',
          value: '${controller.candidatesForHall.length}',
          icon: Icons.groups_outlined,
          width: 200,
        ),
        LightStatCard(
          title: 'Available',
          value: '${controller.availableWorkstations.length}',
          icon: Icons.desktop_windows_outlined,
          width: 200,
        ),
        LightStatCard(
          title: 'Reserved',
          value: '${controller.reservedCount}',
          icon: Icons.bookmark_outline,
          width: 200,
        ),
        LightStatCard(
          title: 'Locked',
          value: '${controller.lockedCount}',
          icon: Icons.lock_outline,
          width: 200,
        ),
      ],
    );
  }
}

class _AllocationPolicyPanel extends StatelessWidget {
  const _AllocationPolicyPanel({required this.controller});

  final WorkstationAllocationController controller;

  @override
  Widget build(BuildContext context) {
    return LightPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Allocation Mode',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose how candidates receive a workstation for this examination.',
            style: TextStyle(color: abuMuted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: WorkstationAssignmentMode.values.map((mode) {
              final selected = controller.selectedMode.value == mode;
              return ChoiceChip(
                selected: selected,
                onSelected: (_) => controller.changeMode(mode),
                avatar: Icon(_modeIcon(mode), size: 18),
                label: Text(mode.label),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: abuCanvas,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: abuLine),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: abuGreen, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    controller.selectedMode.value.description,
                    style: const TextStyle(
                      color: abuInk,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _modeIcon(WorkstationAssignmentMode mode) {
    switch (mode) {
      case WorkstationAssignmentMode.freeSeating:
        return Icons.event_seat_outlined;
      case WorkstationAssignmentMode.manual:
        return Icons.person_add_alt_1_outlined;
      case WorkstationAssignmentMode.systemDistribution:
        return Icons.hub_outlined;
    }
  }
}

class _ModeActionPanel extends StatelessWidget {
  const _ModeActionPanel({required this.controller});

  final WorkstationAllocationController controller;

  @override
  Widget build(BuildContext context) {
    switch (controller.selectedMode.value) {
      case WorkstationAssignmentMode.freeSeating:
        return const _FreeSeatingPanel();
      case WorkstationAssignmentMode.manual:
        return _ManualAssignmentPanel(controller: controller);
      case WorkstationAssignmentMode.systemDistribution:
        return _SystemDistributionPanel(controller: controller);
    }
  }
}

class _FreeSeatingPanel extends StatelessWidget {
  const _FreeSeatingPanel();

  @override
  Widget build(BuildContext context) {
    return LightPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: abuGreen.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lock_outline, color: abuGreen),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Free Seating with Login Lock',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 5),
                Text(
                  'A student may sit at any healthy available workstation. The first successful login locks that candidate and exam to the workstation. A different workstation will reject the same candidate until an invigilator performs a reassignment.',
                  style: TextStyle(
                    color: abuMuted,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualAssignmentPanel extends StatelessWidget {
  const _ManualAssignmentPanel({required this.controller});

  final WorkstationAllocationController controller;

  @override
  Widget build(BuildContext context) {
    final candidates = controller.assignableCandidates;
    final seats = controller.availableWorkstations;

    return LightPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manual Assignment',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Reserve a specific available workstation for a candidate. The reservation becomes locked only after successful login.',
            style: TextStyle(color: abuMuted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final candidatePicker = DropdownButtonFormField<String>(
                initialValue:
                    controller.selectedCandidateRegistration.value.isEmpty
                    ? null
                    : controller.selectedCandidateRegistration.value,
                isExpanded: true,
                items: candidates
                    .map(
                      (candidate) => DropdownMenuItem(
                        value: candidate.registrationNumber,
                        child: Text(
                          '${candidate.registrationNumber} • ${candidate.candidateName}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: controller.selectCandidate,
                decoration: const InputDecoration(
                  labelText: 'Candidate',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              );

              final workstationPicker = DropdownButtonFormField<String>(
                initialValue: controller.selectedSeatNumber.value.isEmpty
                    ? null
                    : controller.selectedSeatNumber.value,
                isExpanded: true,
                items: seats
                    .map(
                      (seat) => DropdownMenuItem(
                        value: seat.seatNumber,
                        child: Text(
                          '${seat.seatNumber} • ${seat.workstationId}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: controller.selectSeat,
                decoration: const InputDecoration(
                  labelText: 'Available workstation',
                  prefixIcon: Icon(Icons.desktop_windows_outlined),
                ),
              );

              if (constraints.maxWidth < 820) {
                return Column(
                  children: [
                    candidatePicker,
                    const SizedBox(height: 12),
                    workstationPicker,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: candidatePicker),
                  const SizedBox(width: 12),
                  Expanded(child: workstationPicker),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: controller.isProcessing.value
                  ? null
                  : controller.reserveSelectedCandidate,
              icon: const Icon(Icons.event_available_outlined),
              label: const Text('Reserve Workstation'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SystemDistributionPanel extends StatelessWidget {
  const _SystemDistributionPanel({required this.controller});

  final WorkstationAllocationController controller;

  @override
  Widget build(BuildContext context) {
    return LightPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Distribution',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Automatically reserve healthy available workstations. Candidates already locked into an exam are never moved by redistribution.',
            style: TextStyle(color: abuMuted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: WorkstationDistributionMode.values
                .map(
                  (mode) => ChoiceChip(
                    selected:
                        controller.selectedDistributionMode.value == mode,
                    onSelected: (_) =>
                        controller.changeDistributionMode(mode),
                    avatar: Icon(
                      mode == WorkstationDistributionMode.fixed
                          ? Icons.format_list_numbered
                          : Icons.shuffle,
                      size: 17,
                    ),
                    label: Text(mode.label),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Text(
            controller.selectedDistributionMode.value ==
                    WorkstationDistributionMode.fixed
                ? 'Fixed / Sequential pairs registration-number order with workstation seat order.'
                : 'Mixed / Randomized shuffles available workstations before reservations are created.',
            style: const TextStyle(color: abuMuted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: controller.isProcessing.value
                  ? null
                  : controller.distributeWorkstations,
              icon: const Icon(Icons.auto_awesome_outlined),
              label: Text(
                controller.isProcessing.value
                    ? 'Distributing…'
                    : 'Distribute Workstations',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignmentTable extends StatelessWidget {
  const _AssignmentTable({required this.controller});

  final WorkstationAllocationController controller;

  @override
  Widget build(BuildContext context) {
    final assignments = controller.currentAssignments;

    return LightPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Exam Bindings',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Reserved = pre-login assignment. Locked = successful login; workstation changes require invigilator reassignment.',
            style: TextStyle(color: abuMuted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          if (assignments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No workstation bindings yet.',
                  style: TextStyle(color: abuMuted, fontWeight: FontWeight.w700),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Candidate')),
                  DataColumn(label: Text('Registration')),
                  DataColumn(label: Text('Seat / Workstation')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Source')),
                ],
                rows: assignments.map((assignment) {
                  final locked = assignment.isLocked;
                  return DataRow(
                    cells: [
                      DataCell(Text(assignment.candidateName)),
                      DataCell(Text(assignment.registrationNumber)),
                      DataCell(
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              assignment.seatNumber,
                              style: const TextStyle(fontWeight: FontWeight.w900),
                            ),
                            Text(
                              assignment.workstationId,
                              style: const TextStyle(
                                color: abuMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(_StatusPill(locked: locked)),
                      DataCell(Text(_sourceLabel(assignment.source))),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  String _sourceLabel(WorkstationAssignmentSource source) {
    switch (source) {
      case WorkstationAssignmentSource.freeLogin:
        return 'Free Seating';
      case WorkstationAssignmentSource.manual:
        return 'Manual';
      case WorkstationAssignmentSource.systemFixed:
        return 'System Fixed';
      case WorkstationAssignmentSource.systemMixed:
        return 'System Mixed';
      case WorkstationAssignmentSource.invigilatorReassignment:
        return 'Reassigned';
    }
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.locked});

  final bool locked;

  @override
  Widget build(BuildContext context) {
    final color = locked ? abuGreen : const Color(0xFF8A5A00);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(locked ? Icons.lock : Icons.schedule, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            locked ? 'Locked' : 'Reserved',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
