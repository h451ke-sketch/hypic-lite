import 'package:flutter/material.dart';
import '../models/liquify_point.dart';

class BlemishPainter {
  /// Draws blemish removal patches on top of canvas using soft feathered blending
  static void drawBlemishPatches(
    Canvas canvas,
    Size size,
    List<BlemishSpot> spots,
  ) {
    if (spots.isEmpty) return;

    for (var spot in spots) {
      Offset center = Offset(spot.center.dx * size.width, spot.center.dy * size.height);
      double radius = spot.radius * size.width;

      // Soft feather mask to blend surrounding texture
      final Paint maskPaint = Paint()
        ..color = Colors.white.withOpacity(0.08)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.7);

      canvas.drawCircle(center, radius, maskPaint);
    }
  }
}
