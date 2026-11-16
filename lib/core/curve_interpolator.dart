import 'dart:math';
import '../models/curve_data.dart';

class CurveInterpolator {
  /// Evaluates 256 lookup table for a given channel curve
  static List<int> buildLookupTable(ChannelCurve curve) {
    if (curve.isLinear) {
      return List<int>.generate(256, (i) => i);
    }

    // Sort control points by X
    List<CurvePoint> pts = List.from(curve.points);
    pts.sort((a, b) => a.x.compareTo(b.x));

    // Ensure boundary points exist
    if (pts.first.x > 0.0) {
      pts.insert(0, CurvePoint(0.0, pts.first.y));
    }
    if (pts.last.x < 1.0) {
      pts.add(CurvePoint(1.0, pts.last.y));
    }

    int n = pts.length;
    List<double> x = pts.map((p) => p.x * 255.0).toList();
    List<double> y = pts.map((p) => p.y * 255.0).toList();

    // Fritsch-Carlson Monotone Cubic Interpolation
    List<double> dx = List.filled(n - 1, 0.0);
    List<double> dy = List.filled(n - 1, 0.0);
    List<double> slopes = List.filled(n - 1, 0.0);

    for (int i = 0; i < n - 1; i++) {
      dx[i] = max(0.0001, x[i + 1] - x[i]);
      dy[i] = y[i + 1] - y[i];
      slopes[i] = dy[i] / dx[i];
    }

    List<double> m = List.filled(n, 0.0);
    m[0] = slopes[0];
    for (int i = 1; i < n - 1; i++) {
      m[i] = (slopes[i - 1] + slopes[i]) / 2.0;
    }
    m[n - 1] = slopes[n - 2];

    for (int i = 0; i < n - 1; i++) {
      if (dy[i] == 0.0) {
        m[i] = 0.0;
        m[i + 1] = 0.0;
      } else {
        double alpha = m[i] / slopes[i];
        double beta = m[i + 1] / slopes[i];
        if (alpha < 0.0) m[i] = 0.0;
        if (beta < 0.0) m[i + 1] = 0.0;
        double dist = alpha * alpha + beta * beta;
        if (dist > 9.0) {
          double tau = 3.0 / sqrt(dist);
          m[i] = tau * alpha * slopes[i];
          m[i + 1] = tau * beta * slopes[i];
        }
      }
    }

    // Build 256-entry table
    List<int> lut = List.filled(256, 0);
    int seg = 0;
    for (int i = 0; i < 256; i++) {
      double t = i.toDouble();
      while (seg < n - 2 && t > x[seg + 1]) {
        seg++;
      }
      double h = dx[seg];
      double diff = t - x[seg];
      double norm = diff / h;
      double h00 = (1 + 2 * norm) * (1 - norm) * (1 - norm);
      double h10 = norm * (1 - norm) * (1 - norm);
      double h01 = norm * norm * (3 - 2 * norm);
      double h11 = norm * norm * (norm - 1);

      double val = h00 * y[seg] +
          h10 * h * m[seg] +
          h01 * y[seg + 1] +
          h11 * h * m[seg + 1];

      lut[i] = val.round().clamp(0, 255);
    }

    return lut;
  }
}
