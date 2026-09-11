import 'dart:ui';

class WhiteboardStrokeData {
  WhiteboardStrokeData({
    required this.colorValue,
    required this.width,
    required this.points,
  });

  final int colorValue;
  final double width;
  final List<Offset> points;

  WhiteboardStrokeData copyWith({
    int? colorValue,
    double? width,
    List<Offset>? points,
  }) {
    return WhiteboardStrokeData(
      colorValue: colorValue ?? this.colorValue,
      width: width ?? this.width,
      points: points ?? this.points,
    );
  }
}
