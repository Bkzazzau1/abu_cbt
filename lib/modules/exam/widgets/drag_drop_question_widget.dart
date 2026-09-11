import 'package:flutter/material.dart';

import '../../../data/models/center_question_models.dart';
import 'question_shell_card.dart';

class DragDropQuestionWidget extends StatefulWidget {
  const DragDropQuestionWidget({
    super.key,
    required this.question,
    required this.assignments,
    required this.onChanged,
  });

  final CenterQuestion question;
  final Map<String, String> assignments;
  final ValueChanged<Map<String, String>> onChanged;

  @override
  State<DragDropQuestionWidget> createState() => _DragDropQuestionWidgetState();
}

class _DragDropQuestionWidgetState extends State<DragDropQuestionWidget> {
  late Map<String, String> currentAssignments;

  @override
  void initState() {
    super.initState();
    currentAssignments = Map<String, String>.from(widget.assignments);
  }

  @override
  void didUpdateWidget(covariant DragDropQuestionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id ||
        oldWidget.assignments != widget.assignments) {
      currentAssignments = Map<String, String>.from(widget.assignments);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return QuestionShellCard(
      question: widget.question,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Drag each item to the correct target.',
            style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: widget.question.dragItems.map((item) {
              return Draggable<String>(
                data: item,
                feedback: Material(
                  color: Colors.transparent,
                  child: _dragChip(context, item, dragging: true),
                ),
                childWhenDragging: _dragChip(context, item, faded: true),
                child: _dragChip(context, item),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          ...widget.question.dropTargets.map((target) {
            final matchedItems = currentAssignments.entries
                .where((e) => e.value == target)
                .map((e) => e.key)
                .toList();

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DragTarget<String>(
                onAcceptWithDetails: (details) {
                  setState(() {
                    currentAssignments[details.data] = target;
                  });
                  widget.onChanged(
                    Map<String, String>.from(currentAssignments),
                  );
                },
                builder: (context, candidateData, rejectedData) {
                  final active = candidateData.isNotEmpty;

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: active
                          ? cs.primary.withValues(alpha: 0.08)
                          : cs.surfaceContainerHighest.withValues(alpha: 0.30),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: active
                            ? cs.primary.withValues(alpha: 0.24)
                            : cs.onSurface.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          target,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        if (matchedItems.isEmpty)
                          Text(
                            'Drop item here',
                            style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.65),
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: matchedItems.map((item) {
                              return Chip(
                                label: Text(item),
                                onDeleted: () {
                                  setState(() {
                                    currentAssignments.remove(item);
                                  });
                                  widget.onChanged(
                                    Map<String, String>.from(
                                      currentAssignments,
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _dragChip(
    BuildContext context,
    String label, {
    bool dragging = false,
    bool faded = false,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: dragging
            ? cs.primary.withValues(alpha: 0.18)
            : cs.primary.withValues(alpha: faded ? 0.04 : 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.primary.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800),
      ),
    );
  }
}
