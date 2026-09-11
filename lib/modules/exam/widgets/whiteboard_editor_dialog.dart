import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/whiteboard_models.dart';

class WhiteboardEditorDialog extends StatefulWidget {
  const WhiteboardEditorDialog({
    super.key,
    required this.initialStrokes,
    this.prompt,
  });

  final List<WhiteboardStrokeData> initialStrokes;
  final String? prompt;

  @override
  State<WhiteboardEditorDialog> createState() => _WhiteboardEditorDialogState();
}

class _WhiteboardEditorDialogState extends State<WhiteboardEditorDialog> {
  static const _palette = <Color>[
    Color(0xFF111827),
    Color(0xFFB42318),
    Color(0xFF155EEF),
    Color(0xFF0F8A4B),
    Color(0xFFB26A00),
    Color(0xFF6941C6),
  ];

  late final List<WhiteboardStrokeData> _strokes;
  Color _selectedColor = _palette.first;
  double _brushWidth = 3;

  @override
  void initState() {
    super.initState();
    _strokes = List<WhiteboardStrokeData>.from(widget.initialStrokes);
  }

  void _startStroke(Offset point) {
    setState(() {
      _strokes.add(
        WhiteboardStrokeData(
          colorValue: _selectedColor.toARGB32(),
          width: _brushWidth,
          points: [point],
        ),
      );
    });
  }

  void _appendPoint(Offset point) {
    if (_strokes.isEmpty) return;
    final last = _strokes.last;
    setState(() {
      _strokes[_strokes.length - 1] = last.copyWith(
        points: [...last.points, point],
      );
    });
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() {
      _strokes.removeLast();
    });
  }

  void _clear() {
    if (_strokes.isEmpty) return;
    setState(() {
      _strokes.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final screen = MediaQuery.sizeOf(context);
    final maxWidth = math.min(screen.width - 32, 980.0);
    final canvasHeight = screen.height < 760 ? 260.0 : 380.0;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Whiteboard',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              if ((widget.prompt ?? '').trim().isNotEmpty) ...[
                Text(
                  widget.prompt!.trim(),
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Container(
                width: double.infinity,
                height: canvasHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: cs.onSurface.withValues(alpha: 0.16),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: GestureDetector(
                    onPanStart: (details) =>
                        _startStroke(details.localPosition),
                    onPanUpdate: (details) =>
                        _appendPoint(details.localPosition),
                    child: CustomPaint(
                      painter: _WhiteboardPainter(_strokes),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ..._palette.map((color) {
                    final selected =
                        _selectedColor.toARGB32() == color.toARGB32();
                    return InkWell(
                      onTap: () => setState(() => _selectedColor = color),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? cs.primary : Colors.white,
                            width: selected ? 3 : 1,
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 200,
                    child: Slider(
                      min: 1,
                      max: 12,
                      divisions: 11,
                      value: _brushWidth,
                      label: '${_brushWidth.toStringAsFixed(0)} px',
                      onChanged: (v) => setState(() => _brushWidth = v),
                    ),
                  ),
                  Text(
                    '${_brushWidth.toStringAsFixed(0)} px',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _strokes.isEmpty ? null : _undo,
                    icon: const Icon(Icons.undo),
                    label: const Text('Undo'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _strokes.isEmpty ? null : _clear,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Clear'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(List<WhiteboardStrokeData>.from(_strokes)),
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save Drawing'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WhiteboardPainter extends CustomPainter {
  _WhiteboardPainter(this.strokes);

  final List<WhiteboardStrokeData> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      final paint = Paint()
        ..color = Color(stroke.colorValue)
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (stroke.points.length == 1) {
        canvas.drawCircle(stroke.points.first, stroke.width / 2, paint);
        continue;
      }

      final path = Path()
        ..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WhiteboardPainter oldDelegate) {
    return true;
  }
}
