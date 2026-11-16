import 'package:flutter/material.dart';
import '../models/edit_state.dart';
import '../models/hsl_color_data.dart';

class HslPanel extends StatefulWidget {
  final EditState state;
  final VoidCallback onStateChanged;

  const HslPanel({
    super.key,
    required this.state,
    required this.onStateChanged,
  });

  @override
  State<HslPanel> createState() => _HslPanelState();
}

class _HslPanelState extends State<HslPanel> {
  HslChannel _activeChannel = HslChannel.red;

  @override
  Widget build(BuildContext context) {
    final item = widget.state.hsl.channels[_activeChannel]!;

    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 8 Color Dots
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: HslChannel.values.map((channel) {
                final isSelected = channel == _activeChannel;
                final channelItem = widget.state.hsl.channels[channel]!;
                final isModified = !channelItem.isDefault;

                return GestureDetector(
                  onTap: () => setState(() => _activeChannel = channel),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: channel.displayColor,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: channel.displayColor.withOpacity(0.6),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  )
                                ]
                              : null,
                        ),
                      ),
                      if (isModified && !isSelected)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // Hue Slider
          _buildSliderRow(
            label: '色相',
            value: item.hue,
            min: -100.0,
            max: 100.0,
            onChanged: (v) {
              setState(() => item.hue = v);
              widget.onStateChanged();
            },
          ),

          // Saturation Slider
          _buildSliderRow(
            label: '饱和度',
            value: item.saturation,
            min: -100.0,
            max: 100.0,
            onChanged: (v) {
              setState(() => item.saturation = v);
              widget.onStateChanged();
            },
          ),

          // Luminance Slider
          _buildSliderRow(
            label: '明度',
            value: item.luminance,
            min: -100.0,
            max: 100.0,
            onChanged: (v) {
              setState(() => item.luminance = v);
              widget.onStateChanged();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    int displayVal = value.round();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFFFFD166),
                inactiveTrackColor: const Color(0xFF333333),
                thumbColor: Colors.white,
                trackHeight: 2.5,
              ),
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 38,
            child: Text(
              displayVal > 0 ? '+$displayVal' : '$displayVal',
              textAlign: TextAlign.end,
              style: TextStyle(
                color: displayVal != 0 ? const Color(0xFFFFD166) : Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
