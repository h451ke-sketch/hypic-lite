import 'dart:math';
import '../models/edit_state.dart';
import '../models/filter_preset.dart';

class ColorMatrixBuilder {
  /// Builds a 20-element 4x5 ColorMatrix for Flutter's [ColorFilter.matrix]
  static List<double> build(EditState state) {
    // Start with identity matrix
    List<double> matrix = [
      1, 0, 0, 0, 0, // R
      0, 1, 0, 0, 0, // G
      0, 0, 1, 0, 0, // B
      0, 0, 0, 1, 0, // A
    ];

    // Find active filter preset
    FilterPreset? preset;
    if (state.filterId != 'original') {
      try {
        preset = FilterPreset.presets.firstWhere((p) => p.id == state.filterId);
      } catch (_) {}
    }

    // Blend base state with filter preset
    double effExposure = state.exposure + (preset?.exposure ?? 0.0) * state.filterIntensity;
    double effContrast = state.contrast + (preset?.contrast ?? 0.0) * state.filterIntensity;
    double effSaturation = state.saturation + (preset?.saturation ?? 0.0) * state.filterIntensity;
    double effTemp = state.temperature + (preset?.temperature ?? 0.0) * state.filterIntensity;
    double effTint = state.tint + (preset?.tint ?? 0.0) * state.filterIntensity;
    double effBrightness = state.brightness;

    // Apply skin whitening (boost highlights and skin brightness)
    if (state.skinWhitening > 0.0) {
      effBrightness += state.skinWhitening * 0.15;
      effContrast += state.skinWhitening * 0.05;
      effTemp -= state.skinWhitening * 0.05; // slight cool tone for fair skin
    }

    // 1. Exposure & Brightness
    // Exposure scales RGB multiplicatively; brightness adds an offset
    double expScale = pow(2.0, effExposure).toDouble();
    double bOffset = (effBrightness * 255.0);

    matrix = _multiply(matrix, [
      expScale, 0, 0, 0, bOffset,
      0, expScale, 0, 0, bOffset,
      0, 0, expScale, 0, bOffset,
      0, 0, 0, 1, 0,
    ]);

    // 2. Contrast
    // c: -1.0 to 1.0 -> factor 0.0 to 2.0
    double c = effContrast + 1.0;
    if (c < 0.0) c = 0.0;
    double cOffset = 128.0 * (1.0 - c);

    matrix = _multiply(matrix, [
      c, 0, 0, 0, cOffset,
      0, c, 0, 0, cOffset,
      0, 0, c, 0, cOffset,
      0, 0, 0, 1, 0,
    ]);

    // 3. Saturation
    // s: -1.0 (grayscale) to 1.0 (double saturation)
    double s = effSaturation + 1.0;
    if (s < 0.0) s = 0.0;
    const double lumR = 0.3086;
    const double lumG = 0.6094;
    const double lumB = 0.0820;

    double sr = (1 - s) * lumR;
    double sg = (1 - s) * lumG;
    double sb = (1 - s) * lumB;

    matrix = _multiply(matrix, [
      sr + s, sg, sb, 0, 0,
      sr, sg + s, sb, 0, 0,
      sr, sg, sb + s, 0, 0,
      0, 0, 0, 1, 0,
    ]);

    // 4. Color Temperature (Warm / Cool)
    // Positive = Warm (boost Red/Yellow), Negative = Cool (boost Blue/Cyan)
    double rTemp = 1.0 + effTemp * 0.25;
    double bTemp = 1.0 - effTemp * 0.25;

    matrix = _multiply(matrix, [
      rTemp, 0, 0, 0, 0,
      0, 1.0, 0, 0, 0,
      0, 0, bTemp, 0, 0,
      0, 0, 0, 1, 0,
    ]);

    // 5. Tint (Green / Magenta)
    // Positive = Magenta (boost Red & Blue), Negative = Green (boost Green)
    double gTint = 1.0 - effTint * 0.2;
    double rbTint = 1.0 + effTint * 0.1;

    matrix = _multiply(matrix, [
      rbTint, 0, 0, 0, 0,
      0, gTint, 0, 0, 0,
      0, 0, rbTint, 0, 0,
      0, 0, 0, 1, 0,
    ]);

    return matrix;
  }

  /// 4x5 Matrix multiplication
  static List<double> _multiply(List<double> a, List<double> b) {
    List<double> result = List.filled(20, 0.0);
    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 4; col++) {
        double sum = 0.0;
        for (int k = 0; k < 4; k++) {
          sum += a[row * 5 + k] * b[k * 5 + col];
        }
        result[row * 5 + col] = sum;
      }
      // Translation column
      result[row * 5 + 4] = a[row * 5 + 0] * b[0 * 5 + 4] +
          a[row * 5 + 1] * b[1 * 5 + 4] +
          a[row * 5 + 2] * b[2 * 5 + 4] +
          a[row * 5 + 3] * b[3 * 5 + 4] +
          a[row * 5 + 4];
    }
    return result;
  }
}
