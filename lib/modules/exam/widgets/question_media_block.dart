import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class QuestionMediaBlock extends StatelessWidget {
  const QuestionMediaBlock({
    super.key,
    required this.imagePath,
    this.imageCaption,
  });

  final String? imagePath;
  final String? imageCaption;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (imagePath == null || imagePath!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final builtInDiagram = _builtInExamDiagram(imagePath!);
    Widget imageWidget;

    if (builtInDiagram != null) {
      imageWidget = builtInDiagram;
    } else if (imagePath!.startsWith('assets/')) {
      imageWidget = Image.asset(
        imagePath!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _errorBox(cs),
      );
    } else if (!kIsWeb) {
      imageWidget = Image.file(
        File(imagePath!),
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _errorBox(cs),
      );
    } else {
      imageWidget = _errorBox(cs);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageWidget,
            ),
          ),
          if (imageCaption != null && imageCaption!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              imageCaption!.trim(),
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.72),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget? _builtInExamDiagram(String path) {
    if (path.endsWith('hash_lookup_chart.png')) {
      return const _HashLookupDiagram();
    }
    if (path.endsWith('tree_traversal_prompt.png')) {
      return const _TreeTraversalDiagram();
    }
    if (path.endsWith('mitosis_phase.png')) {
      return const _MitosisDiagram();
    }
    if (path.endsWith('velocity_time_graph.png')) {
      return const _VelocityTimeDiagram();
    }
    return null;
  }

  Widget _errorBox(ColorScheme cs) {
    return Container(
      height: 180,
      alignment: Alignment.center,
      color: cs.surfaceContainerHighest,
      child: Text(
        'Image not available',
        style: TextStyle(
          color: cs.onSurface.withValues(alpha: 0.7),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DiagramFrame extends StatelessWidget {
  const _DiagramFrame({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: cs.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _HashLookupDiagram extends StatelessWidget {
  const _HashLookupDiagram();

  static const values = <String>[
    '—',
    '31 → 41',
    '22 → 32',
    '73',
    '44',
    '—',
    '—',
    '—',
    '18',
    '59',
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _DiagramFrame(
      title: 'Hash table using h(k) = k mod 10',
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Keys inserted: 18, 41, 22, 44, 59, 32, 31, 73',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
          Table(
            border: TableBorder.all(color: cs.outlineVariant),
            columnWidths: const {
              0: FixedColumnWidth(60),
              1: FlexColumnWidth(),
            },
            children: [
              const TableRow(
                children: [
                  _TableCellText('Index', bold: true),
                  _TableCellText('Stored key(s)', bold: true),
                ],
              ),
              ...List.generate(
                values.length,
                (index) => TableRow(
                  children: [
                    _TableCellText('$index', bold: true),
                    _TableCellText(values[index]),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TableCellText extends StatelessWidget {
  const _TableCellText(this.text, {this.bold = false});

  final String text;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    );
  }
}

class _TreeTraversalDiagram extends StatelessWidget {
  const _TreeTraversalDiagram();

  @override
  Widget build(BuildContext context) {
    return const _DiagramFrame(
      title: 'Binary search tree',
      child: SizedBox(
        height: 215,
        width: double.infinity,
        child: CustomPaint(painter: _TreePainter()),
      ),
    );
  }
}

class _TreePainter extends CustomPainter {
  const _TreePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0xFF64748B)
      ..strokeWidth = 2;
    final nodeFill = Paint()..color = const Color(0xFFE8F2EB);
    final nodeBorder = Paint()
      ..color = const Color(0xFF125C45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final nodes = <String, Offset>{
      '8': Offset(size.width * .50, 28),
      '3': Offset(size.width * .30, 90),
      '10': Offset(size.width * .70, 90),
      '1': Offset(size.width * .17, 165),
      '6': Offset(size.width * .40, 165),
      '14': Offset(size.width * .82, 165),
    };

    void edge(String a, String b) => canvas.drawLine(nodes[a]!, nodes[b]!, line);
    edge('8', '3');
    edge('8', '10');
    edge('3', '1');
    edge('3', '6');
    edge('10', '14');

    for (final entry in nodes.entries) {
      canvas.drawCircle(entry.value, 21, nodeFill);
      canvas.drawCircle(entry.value, 21, nodeBorder);
      _paintText(canvas, entry.key, entry.value, fontSize: 13, bold: true);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MitosisDiagram extends StatelessWidget {
  const _MitosisDiagram();

  @override
  Widget build(BuildContext context) {
    return const _DiagramFrame(
      title: 'Stages of mitosis',
      child: SizedBox(
        height: 205,
        width: double.infinity,
        child: CustomPaint(painter: _MitosisPainter()),
      ),
    );
  }
}

class _MitosisPainter extends CustomPainter {
  const _MitosisPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Paint()
      ..color = const Color(0xFF125C45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final chromosome = Paint()
      ..color = const Color(0xFF7C3AED)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final spindle = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 1.4;

    final centers = [
      Offset(size.width * .13, 82),
      Offset(size.width * .38, 82),
      Offset(size.width * .63, 82),
      Offset(size.width * .87, 82),
    ];
    const labels = ['Prophase', 'Metaphase', 'Anaphase', 'Telophase'];

    for (var i = 0; i < centers.length; i++) {
      final c = centers[i];
      canvas.drawCircle(c, 48, outline);
      if (i == 0) {
        for (final dx in [-14.0, 0.0, 14.0]) {
          _drawX(canvas, Offset(c.dx + dx, c.dy), chromosome);
        }
      } else if (i == 1) {
        canvas.drawLine(Offset(c.dx - 38, c.dy), Offset(c.dx + 38, c.dy), spindle);
        for (final dy in [-18.0, 0.0, 18.0]) {
          _drawX(canvas, Offset(c.dx, c.dy + dy), chromosome);
        }
      } else if (i == 2) {
        for (final dy in [-16.0, 0.0, 16.0]) {
          canvas.drawLine(Offset(c.dx - 18, c.dy + dy), Offset(c.dx - 31, c.dy + dy), chromosome);
          canvas.drawLine(Offset(c.dx + 18, c.dy + dy), Offset(c.dx + 31, c.dy + dy), chromosome);
        }
      } else {
        canvas.drawCircle(Offset(c.dx - 20, c.dy), 17, outline);
        canvas.drawCircle(Offset(c.dx + 20, c.dy), 17, outline);
        canvas.drawLine(Offset(c.dx, c.dy - 40), Offset(c.dx, c.dy + 40), spindle);
      }
      _paintText(canvas, labels[i], Offset(c.dx, 154), fontSize: 11, bold: true);
    }
  }

  void _drawX(Canvas canvas, Offset center, Paint paint) {
    canvas.drawLine(center + const Offset(-6, -8), center + const Offset(6, 8), paint);
    canvas.drawLine(center + const Offset(6, -8), center + const Offset(-6, 8), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _VelocityTimeDiagram extends StatelessWidget {
  const _VelocityTimeDiagram();

  @override
  Widget build(BuildContext context) {
    return const _DiagramFrame(
      title: 'Velocity–time graph',
      child: SizedBox(
        height: 220,
        width: double.infinity,
        child: CustomPaint(painter: _VelocityTimePainter()),
      ),
    );
  }
}

class _VelocityTimePainter extends CustomPainter {
  const _VelocityTimePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final axis = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 2;
    final grid = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;
    final curve = Paint()
      ..color = const Color(0xFF125C45)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final left = 56.0;
    final bottom = size.height - 38;
    final right = size.width - 24;
    final top = 18.0;

    for (var i = 1; i <= 4; i++) {
      final y = bottom - (bottom - top) * i / 4;
      canvas.drawLine(Offset(left, y), Offset(right, y), grid);
    }
    for (var i = 1; i <= 6; i++) {
      final x = left + (right - left) * i / 6;
      canvas.drawLine(Offset(x, top), Offset(x, bottom), grid);
    }

    canvas.drawLine(Offset(left, bottom), Offset(right, bottom), axis);
    canvas.drawLine(Offset(left, bottom), Offset(left, top), axis);

    Offset point(double t, double v) {
      final x = left + (right - left) * (t / 12);
      final y = bottom - (bottom - top) * (v / 10);
      return Offset(x, y);
    }

    final path = Path()
      ..moveTo(point(0, 0).dx, point(0, 0).dy)
      ..lineTo(point(4, 8).dx, point(4, 8).dy)
      ..lineTo(point(8, 8).dx, point(8, 8).dy)
      ..lineTo(point(12, 0).dx, point(12, 0).dy);
    canvas.drawPath(path, curve);

    for (final t in [0, 4, 8, 12]) {
      _paintText(canvas, '$t', Offset(point(t.toDouble(), 0).dx, bottom + 17), fontSize: 10);
    }
    for (final v in [0, 4, 8]) {
      _paintText(canvas, '$v', Offset(left - 22, point(0, v.toDouble()).dy), fontSize: 10);
    }

    _paintText(canvas, 'Time (s)', Offset((left + right) / 2, size.height - 8), fontSize: 11, bold: true);
    _paintText(canvas, 'Velocity (m/s)', const Offset(45, 8), fontSize: 11, bold: true);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

void _paintText(
  Canvas canvas,
  String text,
  Offset center, {
  double fontSize = 12,
  bool bold = false,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: const Color(0xFF1F2937),
        fontSize: fontSize,
        fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(
    canvas,
    Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
  );
}
