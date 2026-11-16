import 'package:flutter/material.dart';

enum LiquifyMode {
  push('推脸/瘦脸', Icons.open_with),
  shrink('缩小/缩鼻', Icons.filter_tilt_shift),
  enlarge('放大/大眼', Icons.lens),
  restore('橡皮恢复', Icons.auto_fix_normal);

  final String label;
  final IconData icon;
  const LiquifyMode(this.label, this.icon);
}

class LiquifyAction {
  final Offset start;
  final Offset end;
  final double radius; // Normalized relative to image width/height (0.01 ~ 0.5)
  final double strength; // 0.1 ~ 1.0
  final LiquifyMode mode;

  LiquifyAction({
    required this.start,
    required this.end,
    required this.radius,
    required this.strength,
    required this.mode,
  });

  LiquifyAction copy() => LiquifyAction(
        start: start,
        end: end,
        radius: radius,
        strength: strength,
        mode: mode,
      );
}

class BlemishSpot {
  final Offset center;
  final double radius;

  BlemishSpot({required this.center, required this.radius});

  BlemishSpot copy() => BlemishSpot(center: center, radius: radius);
}
