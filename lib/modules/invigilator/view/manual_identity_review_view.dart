import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/ks_status_chip.dart';
import '../../../data/models/manual_identity_verification_models.dart';
import '../../demo/abu_demo_theme.dart';
import '../controller/manual_identity_review_controller.dart';
import '../widgets/invigilator_light_panel.dart';
import '../widgets/invigilator_light_scaffold.dart';
import '../widgets/invigilator_top_actions.dart';

class ManualIdentityReviewView extends GetView<ManualIdentityReviewController> {
  const ManualIdentityReviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return InvigilatorLightScaffold(
      title: 'Manual Identity Verification',
      actions: buildInvigilatorTopActions(showIdentity: false),
      maxContentWidth: 1320,
      body: Obx(() {
        return ListView(
          children: [
            _PolicyBanner(controller: controller),
            const SizedBox(height: 14),
            _SummaryRow(controller: controller),
            const SizedBox(height: 14),
            _FilterBar(controller: controller),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 980;
                final list = _RequestList(controller: controller);
                final detail = Obx(() {
                  final selected = controller.selectedRequest;
                  return selected == null
                      ? const _NoRequestSelected()
                      : _ReviewPanel(
                          request: selected,
                          controller: controller,
                        );
                });

                if (!wide) {
                  return Column(
                    children: [
                      list,
                      if (controller.selectedRequest != null) ...[
                        const SizedBox(height: 14),
                        detail,
                      ],
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: list),
                    const SizedBox(width: 14),
                    Expanded(flex: 4, child: detail),
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

class _PolicyBanner extends StatelessWidget {
  const _PolicyBanner({required this.controller});

  final ManualIdentityReviewController controller;

  @override
  Widget build(BuildContext context) {
    return LightPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: abuGreen.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.verified_user_outlined, color: abuGreen),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Controlled manual identity verification',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 5),
                Text(
                  'Use this only when fingerprint authentication cannot be completed. Compare the candidate against the university photo/record and physical ID. Approval requires an invigilator note and is fully audited; there is no student-side fingerprint bypass.',
                  style: TextStyle(
                    color: abuMuted,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
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

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.controller});

  final ManualIdentityReviewController controller;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        LightStatCard(
          title: 'Pending',
          value: '${controller.pendingCount}',
          icon: Icons.pending_actions_outlined,
          width: 190,
        ),
        LightStatCard(
          title: 'Manual Approved',
          value: '${controller.approvedCount}',
          icon: Icons.person_search_outlined,
          width: 190,
        ),
        LightStatCard(
          title: 'Rejected',
          value: '${controller.rejectedCount}',
          icon: Icons.block_outlined,
          width: 190,
        ),
        LightStatCard(
          title: 'Fingerprint Retry',
          value: '${controller.fingerprintResolvedCount}',
          icon: Icons.fingerprint_outlined,
          width: 190,
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.controller});

  final ManualIdentityReviewController controller;

  @override
  Widget build(BuildContext context) {
    return LightPanel(
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final search = TextField(
            controller: controller.searchController,
            onChanged: controller.updateSearch,
            decoration: const InputDecoration(
              isDense: true,
              prefixIcon: Icon(Icons.search),
              hintText: 'Search candidate, reg no, workstation or review ID',
              border: OutlineInputBorder(),
            ),
          );
          final status = DropdownButtonFormField<String>(
            initialValue: controller.selectedStatus.value,
            items: controller.statusOptions
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) {
              if (value != null) controller.updateStatus(value);
            },
            decoration: const InputDecoration(
              isDense: true,
              labelText: 'Status',
              border: OutlineInputBorder(),
            ),
          );

          if (constraints.maxWidth < 720) {
            return Column(
              children: [
                search,
                const SizedBox(height: 10),
                status,
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 3, child: search),
              const SizedBox(width: 10),
              SizedBox(width: 230, child: status),
            ],
          );
        },
      ),
    );
  }
}

class _RequestList extends StatelessWidget {
  const _RequestList({required this.controller});

  final ManualIdentityReviewController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = controller.filteredRequests;

    return LightPanel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: _Header('Candidate')),
                Expanded(flex: 2, child: _Header('Workstation')),
                Expanded(flex: 2, child: _Header('Reason')),
                SizedBox(width: 105, child: _Header('Status')),
                SizedBox(width: 36),
              ],
            ),
          ),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Text(
                'No identity verification requests match the current filter.',
                textAlign: TextAlign.center,
                style: TextStyle(color: abuMuted, fontWeight: FontWeight.w700),
              ),
            )
          else
            ...items.map((request) {
              final selected =
                  controller.selectedRequestId.value == request.id;
              return InkWell(
                onTap: () => controller.selectRequest(request),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: selected
                        ? cs.primary.withValues(alpha: 0.06)
                        : request.isPending
                            ? const Color(0xFFF59E0B).withValues(alpha: 0.035)
                            : null,
                    border: Border(
                      bottom: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.candidateName,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              request.registrationNumber,
                              style: const TextStyle(
                                color: abuMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          request.seatNumber.isEmpty
                              ? request.workstationId
                              : '${request.seatNumber} • ${request.workstationId}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          request.failureReason.label,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      SizedBox(width: 105, child: _statusChip(request.status)),
                      const SizedBox(
                        width: 36,
                        child: Icon(Icons.chevron_right, size: 20),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _ReviewPanel extends StatelessWidget {
  const _ReviewPanel({required this.request, required this.controller});

  final ManualIdentityVerificationRequest request;
  final ManualIdentityReviewController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return LightPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 76,
                  height: 86,
                  child: request.photoAsset.isEmpty
                      ? const ColoredBox(
                          color: abuCanvas,
                          child: Icon(Icons.person_outline, size: 42),
                        )
                      : Image.asset(
                          request.photoAsset,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const ColoredBox(
                            color: abuCanvas,
                            child: Icon(Icons.person_outline, size: 42),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.candidateName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      request.registrationNumber,
                      style: const TextStyle(
                        color: abuMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _statusChip(request.status),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _detail('Department / Level', '${request.department} • ${request.level}'),
          _detail('Exam', request.examTitle),
          _detail(
            'Workstation',
            '${request.hallName} • ${request.seatNumber.isEmpty ? 'Seat not reported' : request.seatNumber}\n${request.workstationId}',
          ),
          _detail('Fingerprint issue', request.failureReason.label),
          _detail('Attempts', '${request.fingerprintAttempts}'),
          _detail('Review ID', request.id),
          _detail('Requested', _timeLabel(request.requestedAt)),
          const Divider(height: 28),
          if (request.isPending) ...[
            const Text(
              'Manual verification record',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            const Text(
              'Confirm the university record/photo and physical ID before approving. Do not approve only because the fingerprint device failed.',
              style: TextStyle(
                color: abuMuted,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.reviewNoteController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Required review note',
                hintText:
                    'Example: Candidate photo, registration record and ABU ID physically confirmed.',
                prefixIcon: Icon(Icons.notes_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Obx(
              () => Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: controller.isProcessing.value
                          ? null
                          : controller.rejectSelected,
                      icon: const Icon(Icons.block_outlined),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFB42318),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: controller.isProcessing.value
                          ? null
                          : controller.approveSelected,
                      icon: const Icon(Icons.verified_user_outlined),
                      label: const Text('Approve Manual Verification'),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.status.label,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 5),
                  if (request.reviewedBy.isNotEmpty)
                    Text('By: ${request.reviewedBy}'),
                  if (request.reviewedAt != null)
                    Text('At: ${_timeLabel(request.reviewedAt!)}'),
                  if (request.reviewNote.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      request.reviewNote,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: abuMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _NoRequestSelected extends StatelessWidget {
  const _NoRequestSelected();

  @override
  Widget build(BuildContext context) {
    return const LightPanel(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 36),
        child: Column(
          children: [
            Icon(Icons.person_search_outlined, size: 38, color: abuMuted),
            SizedBox(height: 10),
            Text(
              'Select an identity review request to inspect the candidate and take action.',
              textAlign: TextAlign.center,
              style: TextStyle(color: abuMuted, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: abuMuted,
        fontSize: 12,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

Widget _statusChip(ManualIdentityVerificationStatus status) {
  switch (status) {
    case ManualIdentityVerificationStatus.pending:
      return const KsStatusChip(
        label: 'Pending',
        tone: KsStatusChipTone.warning,
      );
    case ManualIdentityVerificationStatus.approved:
      return const KsStatusChip(
        label: 'Manual Verified',
        tone: KsStatusChipTone.success,
      );
    case ManualIdentityVerificationStatus.rejected:
      return const KsStatusChip(
        label: 'Rejected',
        tone: KsStatusChipTone.danger,
      );
    case ManualIdentityVerificationStatus.resolvedByFingerprint:
      return const KsStatusChip(
        label: 'Fingerprint Passed',
        tone: KsStatusChipTone.info,
      );
  }
}

String _timeLabel(DateTime time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  final second = time.second.toString().padLeft(2, '0');
  return '$hour:$minute:$second';
}
