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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _DiagramFrame(
      title: 'Average lookup complexity',
      child: Table(
        border: TableBorder.all(color: cs.outlineVariant),
        columnWidths: const {
          0: FlexColumnWidth(2.2),
          1: FlexColumnWidth(1.4),
          2: FlexColumnWidth(1.4),
        },
        children: const [
          TableRow(
            children: [
              _TableCellText('Data structure', bold: true),
              _TableCellText('Average lookup', bold: true),
              _TableCellText('Worst case', bold: true),
            ],
          ),
          TableRow(
            children: [
              _TableCellText('Hash table'),
              _TableCellText('O(1)'),
              _TableCellText('O(n)'),
            ],
          ),
          TableRow(
            children: [
              _TableCellText('Balanced BST'),
              _TableCellText('O(log n)'),
              _TableCellText('O(log n)'),
            ],
          ),
          TableRow(
            children: [
              _TableCellText('Unsorted array'),
              _TableCellText('O(n)'),
              _TableCellText('O(n)'),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
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
      title: 'Binary tree traversal prompt',
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
      'A': Offset(size.width * .50, 28),
      'B': Offset(size.width * .30, 90),
      'C': Offset(size.width * .70, 90),
      'D': Offset(size.width * .17, 165),
      'E': Offset(size.width * .40, 165),
      'F': Offset(size.width * .60, 165),
      'G': Offset(size.width * .83, 165),
    };

    void edge(String a, String b) => canvas.drawLine(nodes[a]!, nodes[b]!, line);
    edge('A', 'B');
    edge('A', 'C');
    edge('B', 'D');
    edge('B', 'E');
    edge('C', 'F');
    edge('C', 'G');

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
      title: 'Cell division snapshot',
      child: SizedBox(
        height: 215,
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
    final center = Offset(size.width / 2, 100);
    final cellOutline = Paint()
      ..color = const Color(0xFF125C45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final chromosome = Paint()
      ..color = const Color(0xFF5B21B6)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    final spindle = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 1.4;
    final equator = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.2;

    final radiusX = size.width < 500 ? size.width * .34 : 175.0;
    const radiusY = 76.0;
    final cellRect = Rect.fromCenter(
      center: center,
      width: radiusX * 2,
      height: radiusY * 2,
    );
    canvas.drawOval(cellRect, cellOutline);

    final leftPole = Offset(center.dx - radiusX + 25, center.dy);
    final rightPole = Offset(center.dx + radiusX - 25, center.dy);
    canvas.drawCircle(leftPole, 6, Paint()..color = const Color(0xFF334155));
    canvas.drawCircle(rightPole, 6, Paint()..color = const Color(0xFF334155));

    canvas.drawLine(
      Offset(center.dx, center.dy - 62),
      Offset(center.dx, center.dy + 62),
      equator,
    );

    for (final dy in [-40.0, -20.0, 0.0, 20.0, 40.0]) {
      final chromosomeCenter = Offset(center.dx, center.dy + dy);
      canvas.drawLine(leftPole, chromosomeCenter, spindle);
      canvas.drawLine(rightPole, chromosomeCenter, spindle);
      _drawX(canvas, chromosomeCenter, chromosome);
    }

    _paintText(
      canvas,
      'Chromosomes aligned at the cell equator',
      Offset(center.dx, 197),
      fontSize: 11,
      bold: true,
    );
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
    final graph = Paint()
      ..color = const Color(0xFF125C45)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

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

    final start = Offset(left, bottom);
    final end = Offset(right - 35, top + 28);
    canvas.drawLine(start, end, graph);
    canvas.drawCircle(start, 4.5, Paint()..color = const Color(0xFF125C45));
    canvas.drawCircle(end, 4.5, Paint()..color = const Color(0xFF125C45));

    _paintText(
      canvas,
      'Time (s)',
      Offset((left + right) / 2, size.height - 8),
      fontSize: 11,
      bold: true,
    );
    _paintText(
      canvas,
      'Velocity',
      const Offset(33, 10),
      fontSize: 11,
      bold: true,
    );
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
