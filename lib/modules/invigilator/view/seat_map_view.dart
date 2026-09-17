import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../data/models/hall_monitor_models.dart';
import '../../../data/models/seat_map_models.dart';
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
      body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: [
            LightPanel(
              child: Obx(
                () => DropdownButtonFormField<String>(
                  initialValue: controller.selectedHall.value,
                  dropdownColor: cs.surfaceContainerHighest.withValues(
                    alpha: 0.96,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  items: controller.hallOptions
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) controller.changeHall(v);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Hall',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            LightPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seat Legend',
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _legend('Empty', const Color(0xFFF2F4F7)),
                      _legend('Expected', const Color(0xFFDCEBFF)),
                      _legend('Seated', const Color(0xFFFFE7C2)),
                      _legend('In Exam', const Color(0xFFDFF7E8)),
                      _legend('Submitted', const Color(0xFFEDE9FE)),
                      _legend('Absent', const Color(0xFFFFE4E2)),
                      _legend('Issue', const Color(0xFFFFE8BF)),
                      _legend('Malpractice', const Color(0xFFFFD6D2)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Obx(() {
              final seats = controller.currentHallSeats;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: seats.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.25,
                ),
                itemBuilder: (_, i) => _SeatCard(record: seats[i]),
              );
            }),
            ],
          );
        }),
    );
  }

  Widget _legend(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}

class _SeatCard extends StatelessWidget {
  const _SeatCard({required this.record});

  final SeatMapRecord record;

  @override
  Widget build(BuildContext context) {
    final style = _seatStyle(record.state);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        final hallRecord = HallMonitorRecord(
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

        if (record.candidateName.isNotEmpty) {
          Get.toNamed(Routes.candidateActionPanel, arguments: hallRecord);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: style.bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: style.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              record.seatNumber,
              style: TextStyle(
                color: style.fg,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              record.candidateName.isEmpty
                  ? 'No candidate'
                  : record.candidateName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              record.examTitle.isEmpty ? '-' : record.examTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: style.fg.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                style.label,
                style: TextStyle(
                  color: style.fg,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _SeatStyle _seatStyle(SeatOccupancyState state) {
    switch (state) {
      case SeatOccupancyState.empty:
        return _SeatStyle(
          label: 'Empty',
          fg: const Color(0xFF667085),
          bg: const Color(0xFFF2F4F7),
          border: const Color(0xFFD0D5DD),
        );
      case SeatOccupancyState.expected:
        return _SeatStyle(
          label: 'Expected',
          fg: const Color(0xFF155EEF),
          bg: const Color(0xFFDCEBFF),
          border: const Color(0xFFA4BCFD),
        );
      case SeatOccupancyState.seated:
        return _SeatStyle(
          label: 'Seated',
          fg: const Color(0xFF7A4B00),
          bg: const Color(0xFFFFE7C2),
          border: const Color(0xFFF7B955),
        );
      case SeatOccupancyState.authorized:
        return _SeatStyle(
          label: 'Authorized',
          fg: const Color(0xFF0F8A4B),
          bg: const Color(0xFFDFF7E8),
          border: const Color(0xFF75D89A),
        );
      case SeatOccupancyState.inExam:
        return _SeatStyle(
          label: 'In Exam',
          fg: const Color(0xFF0F8A4B),
          bg: const Color(0xFFDFF7E8),
          border: const Color(0xFF75D89A),
        );
      case SeatOccupancyState.submitted:
        return _SeatStyle(
          label: 'Submitted',
          fg: const Color(0xFF6941C6),
          bg: const Color(0xFFEDE9FE),
          border: const Color(0xFFC4B5FD),
        );
      case SeatOccupancyState.absent:
        return _SeatStyle(
          label: 'Absent',
          fg: const Color(0xFFB42318),
          bg: const Color(0xFFFFE4E2),
          border: const Color(0xFFFDA29B),
        );
      case SeatOccupancyState.issue:
        return _SeatStyle(
          label: 'Issue',
          fg: const Color(0xFF8A5A00),
          bg: const Color(0xFFFFE8BF),
          border: const Color(0xFFF7B955),
        );
      case SeatOccupancyState.malpractice:
        return _SeatStyle(
          label: 'Malpractice',
          fg: const Color(0xFFB42318),
          bg: const Color(0xFFFFD6D2),
          border: const Color(0xFFF97066),
        );
    }
  }
}

class _SeatStyle {
  _SeatStyle({
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
