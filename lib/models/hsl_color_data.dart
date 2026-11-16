import 'package:flutter/material.dart';

enum HslChannel {
  red('红', Color(0xFFFF4D4F)),
  orange('橙', Color(0xFFFA8C16)),
  yellow('黄', Color(0xFFFADB14)),
  green('绿', Color(0xFF52C41A)),
  cyan('青', Color(0xFF13C2C2)),
  blue('蓝', Color(0xFF1890FF)),
  purple('紫', Color(0xFF722ED1)),
  magenta('洋红', Color(0xFFEB2F96));

  final String label;
  final Color displayColor;
  const HslChannel(this.label, this.displayColor);
}

class HslColorItem {
  double hue; // -180.0 to 180.0 (or -100 to 100 normalized)
  double saturation; // -100.0 to 100.0
  double luminance; // -100.0 to 100.0

  HslColorItem({
    this.hue = 0.0,
    this.saturation = 0.0,
    this.luminance = 0.0,
  });

  HslColorItem copyWith({
    double? hue,
    double? saturation,
    double? luminance,
  }) {
    return HslColorItem(
      hue: hue ?? this.hue,
      saturation: saturation ?? this.saturation,
      luminance: luminance ?? this.luminance,
    );
  }

  bool get isDefault => hue == 0.0 && saturation == 0.0 && luminance == 0.0;
}

class HslSettings {
  final Map<HslChannel, HslColorItem> channels;

  HslSettings({Map<HslChannel, HslColorItem>? channels})
      : channels = channels ??
            {
              for (var channel in HslChannel.values)
                channel: HslColorItem(),
            };

  HslSettings copy() {
    return HslSettings(
      channels: {
        for (var entry in channels.entries)
          entry.key: entry.value.copyWith(),
      },
    );
  }

  bool get isDefault => channels.values.every((item) => item.isDefault);

  void reset() {
    for (var channel in HslChannel.values) {
      channels[channel] = HslColorItem();
    }
  }
}
