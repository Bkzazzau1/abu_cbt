import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../data/models/hall_monitor_models.dart';
import '../../../data/models/seat_map_models.dart';
import '../../demo/abu_demo_theme.dart';
import '../controller/seat_map_controller.dart';
import '../widgets/invigilator_light_panel.dart';
import '../widgets/invigilator_light_scaffold.dart';
import '../widgets/invigilator_top_actions.dart';

class SeatMapView extends GetView<SeatMapController> {
  const SeatMapView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InvigilatorLightScaffold(
      title: 'Hall Seat Map',
      actions: buildInvigilatorTopActions(showSeatMap: false),
      maxContentWidth: 1180,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final seats = controller.currentHallSeats;

        return ListView(
          children: [
            LightPanel(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 760;
                  final hallPicker = Obx(
                    () => DropdownButtonFormField<String>(
                      initialValue: controller.selectedHall.value,
                      dropdownColor: cs.surfaceContainerHighest.withValues(
                        alpha: 0.98,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      items: controller.hallOptions
                          .map(
                            (hall) => DropdownMenuItem(
                              value: hall,
                              child: Text(hall),
                            ),
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

                  final summary = Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: compact
                        ? WrapAlignment.start
                        : WrapAlignment.end,
                    children: [
                      _SummaryChip(
                        label: '${seats.length} Seats',
                        icon: Icons.chair_alt_outlined,
                      ),
                      _SummaryChip(
                        label:
                            '${_count(seats, SeatOccupancyState.inExam)} In Exam',
                        icon: Icons.task_alt_outlined,
                      ),
                      _SummaryChip(
                        label:
                            '${_count(seats, SeatOccupancyState.issue)} Issues',
                        icon: Icons.report_problem_outlined,
                      ),
                      _SummaryChip(
                        label:
                            '${_count(seats, SeatOccupancyState.empty)} Available',
                        icon: Icons.event_seat_outlined,
                      ),
                    ],
                  );

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [hallPicker, const SizedBox(height: 14), summary],
                    );
                  }

                  return Row(
                    children: [
                      SizedBox(width: 280, child: hallPicker),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: summary,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            LightPanel(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Live Hall Layout',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Compact workstation view. Select a seat to inspect the candidate and workstation.',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.68),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _legend('Available', SeatOccupancyState.empty),
                      _legend('Expected', SeatOccupancyState.expected),
                      _legend('Seated', SeatOccupancyState.seated),
                      _legend('In Exam', SeatOccupancyState.inExam),
                      _legend('Submitted', SeatOccupancyState.submitted),
                      _legend('Absent', SeatOccupancyState.absent),
                      _legend('Issue', SeatOccupancyState.issue),
                      _legend('Malpractice', SeatOccupancyState.malpractice),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.desktop_windows_outlined, color: cs.primary),
                        const SizedBox(width: 8),
                        Text(
                          'FRONT / INVIGILATOR DESK',
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _HallGrid(
                    seats: seats,
                    onSeatTap: (record) => _showSeatDetails(context, record),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.door_front_door_outlined,
                        size: 18,
                        color: cs.onSurface.withValues(alpha: 0.55),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'EXIT',
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.55),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  int _count(List<SeatMapRecord> seats, SeatOccupancyState state) =>
      seats.where((seat) => seat.state == state).length;

  Widget _legend(String label, SeatOccupancyState state) {
    final style = seatStyle(state);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: style.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: style.fg,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: style.fg,
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSeatDetails(
    BuildContext context,
    SeatMapRecord record,
  ) async {
    final style = seatStyle(record.state);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Theme(
          data: abuDemoTheme(),
          child: AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
          contentPadding: const EdgeInsets.fromLTRB(22, 8, 22, 6),
          actionsPadding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
          title: Row(
            children: [
              Container(
                width: 48,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: style.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: style.border),
                ),
                child: Text(
                  record.seatNumber,
                  style: TextStyle(
                    color: style.fg,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.candidateName.isEmpty
                          ? 'Available Workstation'
                          : record.candidateName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      style.label,
                      style: TextStyle(
                        color: style.fg,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DetailRow(label: 'Hall', value: record.hallName),
                _DetailRow(label: 'Seat', value: record.seatNumber),
                _DetailRow(
                  label: 'Registration',
                  value: record.registrationNumber.isEmpty
                      ? '—'
                      : record.registrationNumber,
                ),
                _DetailRow(
                  label: 'Exam',
                  value: record.examTitle.isEmpty ? '—' : record.examTitle,
                ),
                _DetailRow(label: 'Workstation', value: record.workstationId),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
            if (record.candidateName.isNotEmpty)
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Get.toNamed(
                    Routes.candidateActionPanel,
                    arguments: _toHallRecord(record),
                  );
                },
                icon: const Icon(Icons.tune_outlined),
                label: const Text('Candidate Actions'),
              ),
          ],
          ),
        );
      },
    );
  }

  HallMonitorRecord _toHallRecord(SeatMapRecord record) {
    return HallMonitorRecord(
      workstationId: record.workstationId,
      hallName: record.hallName,
      seatNumber: record.seatNumber,
      candidateName: record.candidateName,
      registrationNumber: record.registrationNumber,
      examTitle: record.examTitle,
      state: switch (record.state) {
        SeatOccupancyState.empty => HallCandidateLiveState.ready,
        SeatOccupancyState.expected => HallCandidateLiveState.ready,
        SeatOccupancyState.seated => HallCandidateLiveState.checkedIn,
        SeatOccupancyState.authorized => HallCandidateLiveState.authorized,
        SeatOccupancyState.inExam => HallCandidateLiveState.inExam,
        SeatOccupancyState.submitted => HallCandidateLiveState.submitted,
        SeatOccupancyState.absent => HallCandidateLiveState.absent,
        SeatOccupancyState.issue => HallCandidateLiveState.issueFlagged,
        SeatOccupancyState.malpractice =>
          HallCandidateLiveState.malpracticeFlagged,
      },
      lastSeenLabel: 'Just now',
      hasIncident: record.state == SeatOccupancyState.issue,
      hasMalpractice: record.state == SeatOccupancyState.malpractice,
    );
  }
}

class _HallGrid extends StatelessWidget {
  const _HallGrid({required this.seats, required this.onSeatTap});

  final List<SeatMapRecord> seats;
  final ValueChanged<SeatMapRecord> onSeatTap;

  @override
  Widget build(BuildContext context) {
    final rows = <List<SeatMapRecord>>[];
    for (var index = 0; index < seats.length; index += 8) {
      final end = index + 8 > seats.length ? seats.length : index + 8;
      rows.add(seats.sublist(index, end));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 760),
        child: Column(
          children: [
            for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var index = 0; index < rows[rowIndex].length; index++) ...[
                    _SeatTile(
                      record: rows[rowIndex][index],
                      onTap: () => onSeatTap(rows[rowIndex][index]),
                    ),
                    if (index == 3)
                      const SizedBox(width: 34)
                    else if (index < rows[rowIndex].length - 1)
                      const SizedBox(width: 8),
                  ],
                ],
              ),
              if (rowIndex < rows.length - 1) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _SeatTile extends StatelessWidget {
  const _SeatTile({required this.record, required this.onTap});

  final SeatMapRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = seatStyle(record.state);

    return Tooltip(
      message: record.candidateName.isEmpty
          ? '${record.seatNumber} • ${style.label}'
          : '${record.seatNumber} • ${record.candidateName} • ${style.label}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 76,
          height: 66,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: style.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: style.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                record.seatNumber,
                style: TextStyle(
                  color: style.fg,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: style.fg,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.primary.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: cs.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: cs.primary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.60),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

SeatStyle seatStyle(SeatOccupancyState state) {
  switch (state) {
    case SeatOccupancyState.empty:
      return const SeatStyle(
        label: 'Available',
        fg: Color(0xFF667085),
        bg: Color(0xFFF8FAFC),
        border: Color(0xFFD0D5DD),
      );
    case SeatOccupancyState.expected:
      return const SeatStyle(
        label: 'Expected',
        fg: Color(0xFF155EEF),
        bg: Color(0xFFEFF6FF),
        border: Color(0xFFA4BCFD),
      );
    case SeatOccupancyState.seated:
      return const SeatStyle(
        label: 'Seated',
        fg: Color(0xFF7A4B00),
        bg: Color(0xFFFFF7E8),
        border: Color(0xFFF7B955),
      );
    case SeatOccupancyState.authorized:
      return const SeatStyle(
        label: 'Authorized',
        fg: Color(0xFF0F8A4B),
        bg: Color(0xFFECFDF3),
        border: Color(0xFF75D89A),
      );
    case SeatOccupancyState.inExam:
      return const SeatStyle(
        label: 'In Exam',
        fg: Color(0xFF0F8A4B),
        bg: Color(0xFFECFDF3),
        border: Color(0xFF75D89A),
      );
    case SeatOccupancyState.submitted:
      return const SeatStyle(
        label: 'Submitted',
        fg: Color(0xFF6941C6),
        bg: Color(0xFFF5F3FF),
        border: Color(0xFFC4B5FD),
      );
    case SeatOccupancyState.absent:
      return const SeatStyle(
        label: 'Absent',
        fg: Color(0xFFB42318),
        bg: Color(0xFFFFF1F0),
        border: Color(0xFFFDA29B),
      );
    case SeatOccupancyState.issue:
      return const SeatStyle(
        label: 'Technical Issue',
        fg: Color(0xFF8A5A00),
        bg: Color(0xFFFFFAEB),
        border: Color(0xFFF7B955),
      );
    case SeatOccupancyState.malpractice:
      return const SeatStyle(
        label: 'Malpractice',
        fg: Color(0xFFB42318),
        bg: Color(0xFFFFE4E2),
        border: Color(0xFFF97066),
      );
  }
}

class SeatStyle {
  const SeatStyle({
    required this.label,
    required this.fg,
    required this.bg,
    required this.border,
  });

  final String label;
  final Color fg;
  final Color bg;
  final Color border;
}
