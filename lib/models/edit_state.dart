import 'package:flutter/material.dart';
import 'filter_preset.dart';
import 'curve_data.dart';
import 'hsl_color_data.dart';
import 'liquify_point.dart';

class EditState {
  // 基础光影调色 (-1.0 ~ 1.0)
  double exposure;
  double brightness;
  double contrast;
  double saturation;
  double vibrance;
  double highlights;
  double shadows;
  double temperature;
  double tint;
  double sharpness;
  double vignette;
  double grain;

  // 美颜人像 (0.0 ~ 1.0)
  double skinSmoothing;
  double skinWhitening;

  // 滤镜
  String filterId;
  double filterIntensity; // 0.0 ~ 1.0

  // 曲线 & HSL
  ToneCurves curves;
  HslSettings hsl;

  // 液化与修瑕
  List<LiquifyAction> liquifyActions;
  List<BlemishSpot> blemishSpots;

  // 裁切与翻转
  int rotationQuarterTurns; // 0, 1, 2, 3
  bool flipHorizontal;
  bool flipVertical;
  Rect? cropRect; // Normalized 0.0 ~ 1.0

  EditState({
    this.exposure = 0.0,
    this.brightness = 0.0,
    this.contrast = 0.0,
    this.saturation = 0.0,
    this.vibrance = 0.0,
    this.highlights = 0.0,
    this.shadows = 0.0,
    this.temperature = 0.0,
    this.tint = 0.0,
    this.sharpness = 0.0,
    this.vignette = 0.0,
    this.grain = 0.0,
    this.skinSmoothing = 0.0,
    this.skinWhitening = 0.0,
    this.filterId = 'original',
    this.filterIntensity = 1.0,
    ToneCurves? curves,
    HslSettings? hsl,
    List<LiquifyAction>? liquifyActions,
    List<BlemishSpot>? blemishSpots,
    this.rotationQuarterTurns = 0,
    this.flipHorizontal = false,
    this.flipVertical = false,
    this.cropRect,
  })  : curves = curves ?? ToneCurves(),
        hsl = hsl ?? HslSettings(),
        liquifyActions = liquifyActions ?? [],
        blemishSpots = blemishSpots ?? [];

  EditState copy() {
    return EditState(
      exposure: exposure,
      brightness: brightness,
      contrast: contrast,
      saturation: saturation,
      vibrance: vibrance,
      highlights: highlights,
      shadows: shadows,
      temperature: temperature,
      tint: tint,
      sharpness: sharpness,
      vignette: vignette,
      grain: grain,
      skinSmoothing: skinSmoothing,
      skinWhitening: skinWhitening,
      filterId: filterId,
      filterIntensity: filterIntensity,
      curves: curves.copy(),
      hsl: hsl.copy(),
      liquifyActions: liquifyActions.map((a) => a.copy()).toList(),
      blemishSpots: blemishSpots.map((b) => b.copy()).toList(),
      rotationQuarterTurns: rotationQuarterTurns,
      flipHorizontal: flipHorizontal,
      flipVertical: flipVertical,
      cropRect: cropRect,
    );
  }

  void resetAll() {
    exposure = 0.0;
    brightness = 0.0;
    contrast = 0.0;
    saturation = 0.0;
    vibrance = 0.0;
    highlights = 0.0;
    shadows = 0.0;
    temperature = 0.0;
    tint = 0.0;
    sharpness = 0.0;
    vignette = 0.0;
    grain = 0.0;
    skinSmoothing = 0.0;
    skinWhitening = 0.0;
    filterId = 'original';
    filterIntensity = 1.0;
    curves.reset();
    hsl.reset();
    liquifyActions.clear();
    blemishSpots.clear();
    rotationQuarterTurns = 0;
    flipHorizontal = false;
    flipVertical = false;
    cropRect = null;
  }
}
