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
            _AllocationPolicyPanel(controller: controller),
            const SizedBox(height: 14),
            _ModeActionPanel(controller: controller),
            const SizedBox(height: 14),
            _SummaryPanel(controller: controller),
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
    final cs = Theme.of(context).colorScheme;
    return LightPanel(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final picker = DropdownButtonFormField<String>(
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
          );

          final contextBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Candidate ↔ Workstation Assignment',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 5),
              Text(
                controller.currentExamTitle,
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Seats belong to physical workstations. Candidates are assigned only for this examination session.',
                style: TextStyle(color: abuMuted, fontWeight: FontWeight.w600),
              ),
            ],
          );

          if (constraints.maxWidth < 760) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                contextBlock,
                const SizedBox(height: 14),
                picker,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: contextBlock),
              const SizedBox(width: 24),
              SizedBox(width: 250, child: picker),
            ],
          );
        },
      ),
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
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose how candidates receive a workstation before the exam begins.',
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
                      fontWeight: FontWeight.w650,
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
                  'A candidate may sit at any healthy available workstation. After the first successful login, that candidate is locked to that workstation for the active exam. Moving to another workstation requires an invigilator reassignment.',
                  style: TextStyle(
                    color: abuMuted,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
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
            'Reserve an available workstation for a candidate. The reservation becomes locked after successful candidate login.',
            style: TextStyle(color: abuMuted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final candidatePicker = DropdownButtonFormField<String>(
                initialValue: controller.selectedCandidateRegistration.value.isEmpty
                    ? null
                    : controller.selectedCandidateRegistration.value,
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
              final seatPicker = DropdownButtonFormField<String>(
                initialValue: controller.selectedSeatNumber.value.isEmpty
                    ? null
                    : controller.selectedSeatNumber.value,
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

              if (constraints.maxWidth < 800) {
                return Column(
                  children: [
                    candidatePicker,
                    const SizedBox(height: 12),
                    seatPicker,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: candidatePicker),
                  const SizedBox(width: 12),
                  Expanded(child: seatPicker),
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
            'Automatically reserve healthy available workstations for eligible candidates.',
            style: TextStyle(color: abuMuted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: WorkstationDistributionMode.values.map((mode) {
              return ChoiceChip(
                selected: controller.selectedDistributionMode.value == mode,
                onSelected: (_) => controller.changeDistributionMode(mode),
                label: Text(mode.label),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(
            controller.selectedDistributionMode.value ==
                    WorkstationDistributionMode.fixed
                ? 'Fixed assigns candidates in registration-number order to available seats in seat-number order.'
                : 'Mixed randomizes the available workstation order before creating reservations.',
            style: const TextStyle(color: abuMuted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: controller.isProcessing.value
                  ? null
                  : controller.distributeWorkstations,
              icon: const Icon(Icons.shuffle_outlined),
              label: Text(
                controller.selectedDistributionMode.value ==
                        WorkstationDistributionMode.fixed
                    ? 'Run Fixed Distribution'
                    : 'Run Mixed Distribution',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({required this.controller});

  final WorkstationAllocationController controller;

  @override
  Widget build(BuildContext context) {
    final hallSeats = controller.availableWorkstations.length +
        controller.currentAssignments.length;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _SummaryCard(
          label: 'Tracked',
          value: '$hallSeats',
          icon: Icons.desktop_windows_outlined,
        ),
        _SummaryCard(
          label: 'Available',
          value: '${controller.availableWorkstations.length}',
          icon: Icons.event_seat_outlined,
        ),
        _SummaryCard(
          label: 'Reserved',
          value: '${controller.reservedCount}',
          icon: Icons.bookmark_outline,
        ),
        _SummaryCard(
          label: 'Locked',
          value: '${controller.lockedCount}',
          icon: Icons.lock_outline,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: abuLine),
      ),
      child: Row(
        children: [
          Icon(icon, color: abuGreen),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: abuMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
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
            'Reserved = pre-login assignment. Locked = candidate has successfully logged in and cannot change workstation without invigilator action.',
            style: TextStyle(color: abuMuted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          if (assignments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: Center(
                child: Text(
                  'No workstation assignments yet.',
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
                  DataColumn(label: Text('Seat')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Source')),
                ],
                rows: assignments.map((assignment) {
                  final locked = assignment.isLocked;
                  return DataRow(
                    cells: [
                      DataCell(Text(assignment.candidateName)),
                      DataCell(Text(assignment.registrationNumber)),
                      DataCell(Text(assignment.seatNumber)),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: locked
                                ? const Color(0xFFE8F2EB)
                                : const Color(0xFFFFF5DB),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            locked ? 'Locked' : 'Reserved',
                            style: TextStyle(
                              color: locked
                                  ? abuGreen
                                  : const Color(0xFF8A5A00),
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
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
