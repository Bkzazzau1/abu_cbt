import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/ks_status_chip.dart';
import '../../../data/models/attendance_models.dart';
import '../controller/attendance_register_controller.dart';
import '../widgets/invigilator_light_panel.dart';
import '../widgets/invigilator_light_scaffold.dart';
import '../widgets/invigilator_top_actions.dart';

class AttendanceRegisterView extends GetView<AttendanceRegisterController> {
  const AttendanceRegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return InvigilatorLightScaffold(
      title: 'Attendance & Verification',
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
            _WorkflowBanner(controller: controller),
            const SizedBox(height: 14),
            _SummaryRow(controller: controller),
            const SizedBox(height: 14),
            _FilterBar(controller: controller),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 1080;
                final register = _AttendanceTable(controller: controller);
                final detail = Obx(() {
                  final selected = controller.selectedRecord;
                  if (selected == null) {
                    return const _NoCandidateSelected();
                  }
                  return _AttendanceDetailPanel(
                    record: selected,
                    controller: controller,
                  );
                });

                if (!wide) {
                  return Column(
                    children: [
                      register,
                      if (controller.selectedRecord != null) ...[
                        const SizedBox(height: 14),
                        detail,
                      ],
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: register),
                    const SizedBox(width: 14),
                    Expanded(flex: 3, child: detail),
                  ],
                );
              },
            ),
          ],
        );
      }),
    );
  }
}

class _WorkflowBanner extends StatelessWidget {
  const _WorkflowBanner({required this.controller});

  final AttendanceRegisterController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LightPanel(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 820;
          final stages = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _FlowStep(number: '1', label: 'Expected'),
              _FlowArrow(),
              _FlowStep(number: '2', label: 'Checked In'),
              _FlowArrow(),
              _FlowStep(number: '3', label: 'Verified'),
              _FlowArrow(),
              _FlowStep(number: '4', label: 'Authorized'),
              _FlowArrow(),
              _FlowStep(number: '5', label: 'In Exam'),
            ],
          );

          final text = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Candidate admission workflow',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                'Identity problems are separated into Attention and must be resolved before authorization.',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.68),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [text, const SizedBox(height: 12), stages],
            );
          }

          return Row(
            children: [
              Expanded(flex: 2, child: text),
              const SizedBox(width: 18),
              Expanded(flex: 3, child: stages),
            ],
          );
        },
      ),
    );
  }
}

class _FlowStep extends StatelessWidget {
  const _FlowStep({required this.number, required this.label});
  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: cs.primary.withValues(alpha: 0.12),
            child: Text(
              number,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: cs.primary,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _FlowArrow extends StatelessWidget {
  const _FlowArrow();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Icon(Icons.chevron_right, size: 18),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.controller});
  final AttendanceRegisterController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          LightStatCard(
            title: 'Expected',
            value: '${controller.expectedCount}',
            width: 160,
            layout: LightStatCardLayout.column,
          ),
          LightStatCard(
            title: 'Checked In',
            value: '${controller.checkedInCount}',
            width: 160,
            layout: LightStatCardLayout.column,
          ),
          LightStatCard(
            title: 'Verified',
            value: '${controller.verifiedCount}',
            width: 160,
            layout: LightStatCardLayout.column,
          ),
          LightStatCard(
            title: 'Authorized',
            value: '${controller.authorizedCount}',
            width: 160,
            layout: LightStatCardLayout.column,
          ),
          LightStatCard(
            title: 'In Exam',
            value: '${controller.inExamCount}',
            width: 160,
            layout: LightStatCardLayout.column,
          ),
          LightStatCard(
            title: 'Attention',
            value: '${controller.attentionCount}',
            icon: Icons.warning_amber_outlined,
            width: 160,
            layout: LightStatCardLayout.column,
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.controller});
  final AttendanceRegisterController controller;

  @override
  Widget build(BuildContext context) {
    return LightPanel(
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 800;
          final search = TextField(
            controller: controller.searchController,
            onChanged: controller.updateSearch,
            decoration: const InputDecoration(
              isDense: true,
              prefixIcon: Icon(Icons.search),
              hintText: 'Search candidate, reg no, seat or workstation',
              border: OutlineInputBorder(),
            ),
          );
          final hall = Obx(
            () => DropdownButtonFormField<String>(
              initialValue: controller.selectedHall.value,
              items: controller.hallOptions
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) {
                if (v != null) controller.updateHall(v);
              },
              decoration: const InputDecoration(
                isDense: true,
                labelText: 'Hall',
                border: OutlineInputBorder(),
              ),
            ),
          );
          final state = Obx(
            () => DropdownButtonFormField<String>(
              initialValue: controller.selectedState.value,
              items: controller.stateOptions
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) {
                if (v != null) controller.updateState(v);
              },
              decoration: const InputDecoration(
                isDense: true,
                labelText: 'Stage',
                border: OutlineInputBorder(),
              ),
            ),
          );

          if (compact) {
            return Column(
              children: [search, const SizedBox(height: 10), hall, const SizedBox(height: 10), state],
            );
          }
          return Row(
            children: [
              Expanded(flex: 3, child: search),
              const SizedBox(width: 10),
              Expanded(child: hall),
              const SizedBox(width: 10),
              Expanded(child: state),
            ],
          );
        },
      ),
    );
  }
}

class _AttendanceTable extends StatelessWidget {
  const _AttendanceTable({required this.controller});
  final AttendanceRegisterController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LightPanel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: const Row(
              children: [
                SizedBox(width: 70, child: _HeaderText('Seat')),
                Expanded(flex: 3, child: _HeaderText('Candidate')),
                Expanded(flex: 2, child: _HeaderText('Stage')),
                Expanded(flex: 2, child: _HeaderText('Identity')),
                SizedBox(width: 90, child: _HeaderText('Arrival')),
                SizedBox(width: 42),
              ],
            ),
          ),
          Obx(() {
            final items = controller.filteredRecords;
            if (items.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No attendance records match the current filters.'),
              );
            }
            return Column(
              children: items.map((record) {
                final selected = controller.selectedRegistration.value ==
                    record.registrationNumber;
                return InkWell(
                  onTap: () => controller.selectRecord(record),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: selected
                          ? cs.primary.withValues(alpha: 0.06)
                          : record.needsAttention
                              ? const Color(0xFFF59E0B).withValues(alpha: 0.04)
                              : null,
                      border: Border(
                        bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.45)),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 70,
                          child: Text(record.seatNumber, style: const TextStyle(fontWeight: FontWeight.w900)),
                        ),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(record.candidateName, style: const TextStyle(fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(record.registrationNumber, style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.62)), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        Expanded(flex: 2, child: _attendanceChip(record.state)),
                        Expanded(flex: 2, child: _identityChip(record.identityState, record.biometricConfidence)),
                        SizedBox(width: 90, child: Text(record.arrivalTimeLabel, style: const TextStyle(fontWeight: FontWeight.w700))),
                        const SizedBox(width: 8),
                        const SizedBox(width: 34, child: Icon(Icons.chevron_right, size: 20)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  const _HeaderText(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.64),
      ),
    );
  }
}

class _AttendanceDetailPanel extends StatelessWidget {
  const _AttendanceDetailPanel({required this.record, required this.controller});
  final AttendanceRecord record;
  final AttendanceRegisterController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LightPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: cs.primary.withValues(alpha: 0.10),
                child: Icon(Icons.person_outline, color: cs.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.candidateName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                    Text(record.registrationNumber, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.65), fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              _attendanceChip(record.state),
            ],
          ),
          const SizedBox(height: 16),
          _detail('Hall / Seat', '${record.hallName} • ${record.seatNumber}'),
          _detail('Workstation', record.workstationId),
          _detail('Exam', record.examTitle),
          _detail('Arrival', record.arrivalTimeLabel),
          const Divider(height: 26),
          const Text('Identity Verification', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          _identityChip(record.identityState, record.biometricConfidence),
          if (record.verificationNote.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              record.verificationNote,
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.72), height: 1.35),
            ),
          ],
          if (record.needsAttention) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.28)),
              ),
              child: const Text(
                'Identity requires attention. Do not authorize until verification is resolved.',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Get.toNamed(Routes.candidateCheckIn, arguments: record),
              icon: const Icon(Icons.verified_user_outlined),
              label: Text(record.needsAttention ? 'Review Check-In' : 'Open Check-In'),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: record.state == AttendanceState.expected
                      ? () => controller.markCheckedIn(record)
                      : null,
                  child: const Text('Check In'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => controller.markAbsent(record),
                  child: const Text('Absent'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _NoCandidateSelected extends StatelessWidget {
  const _NoCandidateSelected();
  @override
  Widget build(BuildContext context) {
    return const LightPanel(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.how_to_reg_outlined, size: 36),
            SizedBox(height: 10),
            Text('Select a candidate to review attendance and identity verification.', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

Widget _attendanceChip(AttendanceState state) {
  switch (state) {
    case AttendanceState.expected:
      return const KsStatusChip(label: 'Expected', tone: KsStatusChipTone.neutral);
    case AttendanceState.checkedIn:
      return const KsStatusChip(label: 'Checked In', tone: KsStatusChipTone.info);
    case AttendanceState.verified:
      return const KsStatusChip(label: 'Verified', tone: KsStatusChipTone.success);
    case AttendanceState.authorized:
      return const KsStatusChip(label: 'Authorized', tone: KsStatusChipTone.success);
    case AttendanceState.inExam:
      return const KsStatusChip(label: 'In Exam', tone: KsStatusChipTone.success);
    case AttendanceState.submitted:
      return const KsStatusChip(label: 'Submitted', tone: KsStatusChipTone.accent);
    case AttendanceState.absent:
      return const KsStatusChip(label: 'Absent', tone: KsStatusChipTone.danger);
    case AttendanceState.issueFlagged:
      return const KsStatusChip(label: 'Attention', tone: KsStatusChipTone.warning);
  }
}

Widget _identityChip(IdentityVerificationState state, double confidence) {
  switch (state) {
    case IdentityVerificationState.pending:
      return const KsStatusChip(label: 'Pending', tone: KsStatusChipTone.neutral);
    case IdentityVerificationState.matched:
      return KsStatusChip(label: 'Matched ${confidence.toStringAsFixed(0)}%', tone: KsStatusChipTone.success);
    case IdentityVerificationState.mismatch:
      return KsStatusChip(label: 'Mismatch ${confidence.toStringAsFixed(0)}%', tone: KsStatusChipTone.danger);
    case IdentityVerificationState.manualReview:
      return KsStatusChip(label: 'Manual Review ${confidence.toStringAsFixed(0)}%', tone: KsStatusChipTone.warning);
  }
}
