import 'dart:math';
import 'package:flutter/material.dart';
import '../models/edit_state.dart';
import '../models/curve_data.dart';
import '../core/curve_interpolator.dart';

class CurvePanel extends StatefulWidget {
  final EditState state;
  final VoidCallback onStateChanged;

  const CurvePanel({
    super.key,
    required this.state,
    required this.onStateChanged,
  });

  @override
  State<CurvePanel> createState() => _CurvePanelState();
}

class _CurvePanelState extends State<CurvePanel> {
  CurveChannel _activeChannel = CurveChannel.master;
  int? _draggedPointIndex;

  @override
  Widget build(BuildContext context) {
    final activeCurve = widget.state.curves.channels[_activeChannel]!;

    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Channel Selector Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: CurveChannel.values.map((c) {
                    final isSel = c == _activeChannel;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(c.label),
                        selected: isSel,
                        selectedColor: c.color.withOpacity(0.3),
                        side: BorderSide(
                          color: isSel ? c.color : Colors.white24,
                          width: 1.5,
                        ),
                        backgroundColor: const Color(0xFF2C2C2C),
                        labelStyle: TextStyle(
                          color: isSel ? c.color : Colors.white70,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _activeChannel = c);
                        },
                      ),
                    );
                  }).toList(),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.refresh, size: 16, color: Colors.white54),
                  label: const Text('重置', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  onPressed: () {
                    setState(() {
                      widget.state.curves.channels[_activeChannel] = ChannelCurve();
                    });
                    widget.onStateChanged();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Interactive Curve Canvas
          Center(
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF333333)),
              ),
              child: GestureDetector(
                onPanDown: (details) {
                  final renderBox = context.findRenderObject() as RenderBox?;
                  if (renderBox == null) return;
                  final localPos = details.localPosition;
                  final normX = (localPos.dx / 180).clamp(0.0, 1.0);
                  final normY = (1.0 - (localPos.dy / 180)).clamp(0.0, 1.0);

                  // Check if near existing point
                  int closest = -1;
                  double minDist = 0.15;
                  for (int i = 0; i < activeCurve.points.length; i++) {
                    final pt = activeCurve.points[i];
                    double d = sqrt(pow(pt.x - normX, 2) + pow(pt.y - normY, 2));
                    if (d < minDist) {
                      minDist = d;
                      closest = i;
                    }
                  }

                  if (closest != -1) {
                    _draggedPointIndex = closest;
                  } else if (activeCurve.points.length < 5) {
                    // Add new control point
                    final newPt = CurvePoint(normX, normY);
                    setState(() {
                      activeCurve.points.add(newPt);
                      activeCurve.points.sort((a, b) => a.x.compareTo(b.x));
                      _draggedPointIndex = activeCurve.points.indexOf(newPt);
                    });
                    widget.onStateChanged();
                  }
                },
                onPanUpdate: (details) {
                  if (_draggedPointIndex == null) return;
                  final localPos = details.localPosition;
                  final normX = (localPos.dx / 180).clamp(0.0, 1.0);
                  final normY = (1.0 - (localPos.dy / 180)).clamp(0.0, 1.0);

                  setState(() {
                    if (_draggedPointIndex == 0) {
                      // Anchor first point x = 0
                      activeCurve.points[0].y = normY;
                    } else if (_draggedPointIndex == activeCurve.points.length - 1) {
                      // Anchor last point x = 1
                      activeCurve.points.last.y = normY;
                    } else {
                      activeCurve.points[_draggedPointIndex!].x = normX;
                      activeCurve.points[_draggedPointIndex!].y = normY;
                      activeCurve.points.sort((a, b) => a.x.compareTo(b.x));
                    }
                  });
                  widget.onStateChanged();
                },
                onPanEnd: (_) {
                  _draggedPointIndex = null;
                },
                child: CustomPaint(
                  size: const Size(180, 180),
                  painter: _CurveCanvasPainter(
                    curve: activeCurve,
                    channelColor: _activeChannel.color,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '点击曲线添加控制点，拖拽调整明暗关系',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _CurveCanvasPainter extends CustomPainter {
  final ChannelCurve curve;
  final Color channelColor;

  _CurveCanvasPainter({required this.curve, required this.channelColor});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFF262626)
      ..strokeWidth = 1.0;

    for (int i = 1; i < 4; i++) {
      double pos = size.width * (i / 4.0);
      canvas.drawLine(Offset(pos, 0), Offset(pos, size.height), gridPaint);
      canvas.drawLine(Offset(0, pos), Offset(size.width, pos), gridPaint);
    }

    // Diagonal reference
    final diagPaint = Paint()
      ..color = const Color(0xFF2E2E2E)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, size.height), Offset(size.width, 0), diagPaint);

    // 2. Evaluated spline curve
    final lut = CurveInterpolator.buildLookupTable(curve);
    final curvePath = Path();
    curvePath.moveTo(0, size.height - (lut[0] / 255.0) * size.height);

    for (int i = 1; i < 256; i++) {
      double x = (i / 255.0) * size.width;
      double y = size.height - (lut[i] / 255.0) * size.height;
      curvePath.lineTo(x, y);
    }

    final linePaint = Paint()
      ..color = channelColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(curvePath, linePaint);

    // 3. Control Points
    final pointPaint = Paint()
      ..color = channelColor
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (var pt in curve.points) {
      Offset c = Offset(pt.x * size.width, size.height - pt.y * size.height);
      canvas.drawCircle(c, 5.0, pointPaint);
      canvas.drawCircle(c, 5.0, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CurveCanvasPainter oldDelegate) => true;
}
