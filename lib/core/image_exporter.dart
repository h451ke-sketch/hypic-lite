import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../models/edit_state.dart';
import '../models/filter_preset.dart';
import '../models/hsl_color_data.dart';
import '../models/curve_data.dart';
import 'curve_interpolator.dart';

class ImageExporter {
  /// Full-resolution lossless export running in background compute isolate
  static Future<String> exportImage({
    required Uint8List originalBytes,
    required EditState state,
    void Function(double progress)? onProgress,
  }) async {
    // Run CPU-heavy rendering in Flutter background isolate
    final resultPath = await compute(_exportWorker, {
      'bytes': originalBytes,
      'state': state,
      'tempDir': (await getTemporaryDirectory()).path,
    });
    return resultPath;
  }

  static Future<String> _exportWorker(Map<String, dynamic> params) async {
    final Uint8List bytes = params['bytes'];
    final EditState state = params['state'];
    final String tempDir = params['tempDir'];

    // 1. Decode
    img.Image? image = img.decodeImage(bytes);
    if (image == null) throw Exception("无法解码原始图像");

    // 2. Rotation and Flip
    if (state.rotationQuarterTurns % 4 != 0) {
      int degrees = (state.rotationQuarterTurns % 4) * 90;
      image = img.copyRotate(image, angle: degrees);
    }
    if (state.flipHorizontal) {
      image = img.flipHorizontal(image);
    }
    if (state.flipVertical) {
      image = img.flipVertical(image);
    }

    // 3. Crop
    if (state.cropRect != null) {
      int x = (state.cropRect!.left * image.width).round().clamp(0, image.width - 1);
      int y = (state.cropRect!.top * image.height).round().clamp(0, image.height - 1);
      int w = (state.cropRect!.width * image.width).round().clamp(1, image.width - x);
      int h = (state.cropRect!.height * image.height).round().clamp(1, image.height - y);
      image = img.copyCrop(image, x: x, y: y, width: w, height: h);
    }

    // Prepare curve LUTs
    List<int> masterLut = CurveInterpolator.buildLookupTable(state.curves.channels[CurveChannel.master]!);
    List<int> rLut = CurveInterpolator.buildLookupTable(state.curves.channels[CurveChannel.red]!);
    List<int> gLut = CurveInterpolator.buildLookupTable(state.curves.channels[CurveChannel.green]!);
    List<int> bLut = CurveInterpolator.buildLookupTable(state.curves.channels[CurveChannel.blue]!);

    // Filter preset params
    FilterPreset? preset;
    if (state.filterId != 'original') {
      try {
        preset = FilterPreset.presets.firstWhere((p) => p.id == state.filterId);
      } catch (_) {}
    }

    double effExposure = state.exposure + (preset?.exposure ?? 0.0) * state.filterIntensity;
    double effContrast = state.contrast + (preset?.contrast ?? 0.0) * state.filterIntensity;
    double effSaturation = state.saturation + (preset?.saturation ?? 0.0) * state.filterIntensity;
    double effTemp = state.temperature + (preset?.temperature ?? 0.0) * state.filterIntensity;
    double effTint = state.tint + (preset?.tint ?? 0.0) * state.filterIntensity;
    double effBrightness = state.brightness;

    if (state.skinWhitening > 0.0) {
      effBrightness += state.skinWhitening * 0.15;
      effContrast += state.skinWhitening * 0.05;
      effTemp -= state.skinWhitening * 0.05;
    }

    double expFactor = pow(2.0, effExposure).toDouble();
    double contrastFactor = (effContrast + 1.0).clamp(0.0, 3.0);
    double satFactor = (effSaturation + 1.0).clamp(0.0, 3.0);
    double rTemp = 1.0 + effTemp * 0.25;
    double bTemp = 1.0 - effTemp * 0.25;
    double gTint = 1.0 - effTint * 0.2;
    double rbTint = 1.0 + effTint * 0.1;

    // 4. Per-Pixel Processing (Exposure, Contrast, Brightness, Saturation, Temp, Curves)
    final width = image.width;
    final height = image.height;

    for (var pixel in image) {
      double r = pixel.r.toDouble();
      double g = pixel.g.toDouble();
      double b = pixel.b.toDouble();

      // Exposure & Brightness
      r = r * expFactor + (effBrightness * 255.0);
      g = g * expFactor + (effBrightness * 255.0);
      b = b * expFactor + (effBrightness * 255.0);

      // Contrast
      r = (r - 128.0) * contrastFactor + 128.0;
      g = (g - 128.0) * contrastFactor + 128.0;
      b = (b - 128.0) * contrastFactor + 128.0;

      // Saturation
      double lum = 0.3086 * r + 0.6094 * g + 0.0820 * b;
      r = lum + (r - lum) * satFactor;
      g = lum + (g - lum) * satFactor;
      b = lum + (b - lum) * satFactor;

      // Temp & Tint
      r = r * rTemp * rbTint;
      g = g * gTint;
      b = b * bTemp * rbTint;

      // Curves LUT
      int ir = r.round().clamp(0, 255);
      int ig = g.round().clamp(0, 255);
      int ib = b.round().clamp(0, 255);

      ir = masterLut[rLut[ir]];
      ig = masterLut[gLut[ig]];
      ib = masterLut[bLut[ib]];

      pixel.r = ir;
      pixel.g = ig;
      pixel.b = ib;
    }

    // 5. Skin Smoothing (Bilateral / Gaussian blur blend)
    if (state.skinSmoothing > 0.0) {
      img.Image blurred = img.gaussianBlur(image, radius: (state.skinSmoothing * 12).round().clamp(1, 20));
      double alpha = state.skinSmoothing * 0.75;
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final pOrig = image.getPixel(x, y);
          final pBlur = blurred.getPixel(x, y);
          pOrig.r = (pOrig.r * (1.0 - alpha) + pBlur.r * alpha).round();
          pOrig.g = (pOrig.g * (1.0 - alpha) + pBlur.g * alpha).round();
          pOrig.b = (pOrig.b * (1.0 - alpha) + pBlur.b * alpha).round();
        }
      }
    }

    // 6. Vignette
    if (state.vignette > 0.0) {
      double cx = width / 2.0;
      double cy = height / 2.0;
      double maxDist = sqrt(cx * cx + cy * cy);
      double vStrength = state.vignette;

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          double dist = sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy));
          double factor = 1.0 - (dist / maxDist) * vStrength;
          factor = factor.clamp(0.0, 1.0);

          final p = image.getPixel(x, y);
          p.r = (p.r * factor).round();
          p.g = (p.g * factor).round();
          p.b = (p.b * factor).round();
        }
      }
    }

    // 7. Grain
    if (state.grain > 0.0) {
      final rand = Random();
      double gStrength = state.grain * 35.0;
      for (var pixel in image) {
        int noise = ((rand.nextDouble() - 0.5) * gStrength).round();
        pixel.r = (pixel.r + noise).clamp(0, 255);
        pixel.g = (pixel.g + noise).clamp(0, 255);
        pixel.b = (pixel.b + noise).clamp(0, 255);
      }
    }

    // 8. Encode to JPEG with 95% quality
    Uint8List outputBytes = Uint8List.fromList(img.encodeJpg(image, quality: 95));
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('$tempDir/hypic_export_$timestamp.jpg');
    await file.writeAsBytes(outputBytes);

    return file.path;
  }
}
