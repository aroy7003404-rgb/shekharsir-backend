import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WhiteboardPoint {
  final Offset offset;
  final Paint paint;

  WhiteboardPoint({required this.offset, required this.paint});

  Map<String, dynamic> toJson() {
    return {
      'x': offset.dx,
      'y': offset.dy,
      'color': paint.color.value,
      'strokeWidth': paint.strokeWidth,
    };
  }
}

class WhiteboardState {
  final List<WhiteboardPoint?> points;
  final Color selectedColor;
  final double strokeWidth;
  final bool isEraserMode;

  const WhiteboardState({
    this.points = const [],
    this.selectedColor = const Color(0xFF2563EB),
    this.strokeWidth = 4.0,
    this.isEraserMode = false,
  });

  WhiteboardState copyWith({
    List<WhiteboardPoint?>? points,
    Color? selectedColor,
    double? strokeWidth,
    bool? isEraserMode,
  }) {
    return WhiteboardState(
      points: points ?? this.points,
      selectedColor: selectedColor ?? this.selectedColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      isEraserMode: isEraserMode ?? this.isEraserMode,
    );
  }
}

class WhiteboardNotifier extends StateNotifier<WhiteboardState> {
  WhiteboardNotifier() : super(const WhiteboardState());

  void addPoint(Offset offset) {
    final paint = Paint()
      ..color = state.isEraserMode ? Colors.white : state.selectedColor
      ..isAntiAlias = true
      ..strokeWidth = state.isEraserMode ? 20.0 : state.strokeWidth
      ..strokeCap = StrokeCap.round;

    final newPoints = List<WhiteboardPoint?>.from(state.points)
      ..add(WhiteboardPoint(offset: offset, paint: paint));

    state = state.copyWith(points: newPoints);
  }

  void endPath() {
    final newPoints = List<WhiteboardPoint?>.from(state.points)..add(null);
    state = state.copyWith(points: newPoints);
  }

  void setColor(Color color) {
    state = state.copyWith(selectedColor: color, isEraserMode: false);
  }

  void setStrokeWidth(double width) {
    state = state.copyWith(strokeWidth: width);
  }

  void toggleEraser() {
    state = state.copyWith(isEraserMode: !state.isEraserMode);
  }

  void clearCanvas() {
    state = state.copyWith(points: []);
  }
}

final whiteboardProvider =
    StateNotifierProvider.autoDispose<WhiteboardNotifier, WhiteboardState>((ref) {
  return WhiteboardNotifier();
});
