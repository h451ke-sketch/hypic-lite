import 'package:flutter/material.dart';

class FilterPreset {
  final String id;
  final String name;
  final String description;
  final Color previewColor;
  final double exposure;
  final double contrast;
  final double saturation;
  final double temperature;
  final double tint;
  final double highlights;
  final double shadows;
  final double vignette;
  final double grain;

  const FilterPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.previewColor,
    this.exposure = 0.0,
    this.contrast = 0.0,
    this.saturation = 0.0,
    this.temperature = 0.0,
    this.tint = 0.0,
    this.highlights = 0.0,
    this.shadows = 0.0,
    this.vignette = 0.0,
    this.grain = 0.0,
  });

  static const List<FilterPreset> presets = [
    FilterPreset(
      id: 'original',
      name: '原图',
      description: '未添加滤镜效果',
      previewColor: Color(0xFF888888),
    ),
    FilterPreset(
      id: 'cool_white',
      name: '冷白皮',
      description: '通透冷调、皮肤白皙无暇',
      previewColor: Color(0xFFD4E6F1),
      exposure: 0.15,
      contrast: 0.10,
      saturation: -0.05,
      temperature: -0.25,
      tint: 0.10,
      highlights: 0.20,
      shadows: 0.15,
    ),
    FilterPreset(
      id: 'japanese_fresh',
      name: '日杂清透',
      description: '低对比、柔和空气感高光',
      previewColor: Color(0xFFE8F8F5),
      exposure: 0.20,
      contrast: -0.15,
      saturation: 0.10,
      temperature: 0.08,
      tint: 0.05,
      highlights: 0.30,
      shadows: 0.25,
    ),
    FilterPreset(
      id: 'creamy_skin',
      name: '奶油肌',
      description: '暖润光泽、人像元气柔和',
      previewColor: Color(0xFFFDF2E9),
      exposure: 0.12,
      contrast: -0.05,
      saturation: 0.05,
      temperature: 0.15,
      tint: 0.12,
      highlights: 0.10,
    ),
    FilterPreset(
      id: 'vintage_film',
      name: '港风复古',
      description: '浓郁暖棕、经典胶片微粒',
      previewColor: Color(0xFFEDBB99),
      exposure: -0.05,
      contrast: 0.25,
      saturation: -0.10,
      temperature: 0.30,
      tint: -0.10,
      vignette: 0.30,
      grain: 0.35,
    ),
    FilterPreset(
      id: 'french_movie',
      name: '法式电影',
      description: '青黄电影色调、情绪故事感',
      previewColor: Color(0xFFA3E4D7),
      exposure: 0.05,
      contrast: 0.20,
      saturation: -0.15,
      temperature: -0.12,
      tint: -0.15,
      shadows: -0.10,
      vignette: 0.25,
    ),
    FilterPreset(
      id: 'golden_hour',
      name: '暖阳暮色',
      description: '斜阳金光、温暖治愈氛围',
      previewColor: Color(0xFFF9E79F),
      exposure: 0.10,
      contrast: 0.15,
      saturation: 0.20,
      temperature: 0.40,
      tint: 0.10,
      highlights: -0.10,
      shadows: 0.10,
    ),
    FilterPreset(
      id: 'cyberpunk',
      name: '赛博霓虹',
      description: '高反差、青蓝与洋红碰撞',
      previewColor: Color(0xFFD7BDE2),
      exposure: 0.0,
      contrast: 0.35,
      saturation: 0.30,
      temperature: -0.45,
      tint: 0.40,
      shadows: -0.20,
    ),
    FilterPreset(
      id: 'monochrome_pure',
      name: '质感黑白',
      description: '纯粹光影、雕塑般明暗对比',
      previewColor: Color(0xFF333333),
      exposure: 0.05,
      contrast: 0.40,
      saturation: -1.0,
      highlights: 0.15,
      shadows: -0.20,
      grain: 0.20,
    ),
  ];
}
