import 'package:flutter/material.dart';

enum CurveChannel {
  master('RGB', Colors.white),
  red('红', Color(0xFFFF4D4F)),
  green('绿', Color(0xFF52C41A)),
  blue('蓝', Color(0xFF1890FF));

  final String label;
  final Color color;
  const CurveChannel(this.label, this.color);
}

class CurvePoint {
  double x; // 0.0 ~ 1.0
  double y; // 0.0 ~ 1.0

  CurvePoint(this.x, this.y);

  CurvePoint copy() => CurvePoint(x, y);
}

class ChannelCurve {
  final List<CurvePoint> points;

  ChannelCurve({List<CurvePoint>? points})
      : points = points ??
            [
              CurvePoint(0.0, 0.0),
              CurvePoint(1.0, 1.0),
            ];

  ChannelCurve copy() {
    return ChannelCurve(points: points.map((p) => p.copy()).toList());
  }

  bool get isLinear {
    if (points.length != 2) return false;
    return (points[0].x - 0.0).abs() < 0.001 &&
        (points[0].y - 0.0).abs() < 0.001 &&
        (points[1].x - 1.0).abs() < 0.001 &&
        (points[1].y - 1.0).abs() < 0.001;
  }
}

class ToneCurves {
  final Map<CurveChannel, ChannelCurve> channels;

  ToneCurves({Map<CurveChannel, ChannelCurve>? channels})
      : channels = channels ??
            {
              for (var c in CurveChannel.values) c: ChannelCurve(),
            };

  ToneCurves copy() {
    return ToneCurves(
      channels: {
        for (var entry in channels.entries) entry.key: entry.value.copy(),
      },
    );
  }

  bool get isDefault => channels.values.every((c) => c.isLinear);

  void reset() {
    for (var c in CurveChannel.values) {
      channels[c] = ChannelCurve();
    }
  }
}
