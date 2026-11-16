import 'package:flutter/material.dart';
import '../models/edit_state.dart';
import '../models/liquify_point.dart';

class LiquifyPanel extends StatefulWidget {
  final EditState state;
  final LiquifyMode activeMode;
  final double brushRadius;
  final double brushStrength;
  final ValueChanged<LiquifyMode> onModeChanged;
  final ValueChanged<double> onRadiusChanged;
  final ValueChanged<double> onStrengthChanged;
  final VoidCallback onResetLiquify;

  const LiquifyPanel({
    super.key,
    required this.state,
    required this.activeMode,
    required this.brushRadius,
    required this.brushStrength,
    required this.onModeChanged,
    required this.onRadiusChanged,
    required this.onStrengthChanged,
    required this.onResetLiquify,
  });

  @override
  State<LiquifyPanel> createState() => _LiquifyPanelState();
}

class _LiquifyPanelState extends State<LiquifyPanel> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mode Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ...LiquifyMode.values.map((mode) {
                  final isSelected = mode == widget.activeMode;
                  return ChoiceChip(
                    avatar: Icon(
                      mode.icon,
                      size: 16,
                      color: isSelected ? Colors.black : Colors.white70,
                    ),
                    label: Text(mode.label),
                    selected: isSelected,
                    selectedColor: const Color(0xFFFFD166),
                    backgroundColor: const Color(0xFF2C2C2C),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 11,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onSelected: (val) {
                      if (val) widget.onModeChanged(mode);
                    },
                  );
                }),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20, color: Colors.white54),
                  tooltip: '重置液化',
                  onPressed: widget.onResetLiquify,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Brush Size & Strength Sliders
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const SizedBox(
                  width: 50,
                  child: Text('画笔大小', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFFFFD166),
                      inactiveTrackColor: const Color(0xFF333333),
                      thumbColor: Colors.white,
                      trackHeight: 2.0,
                    ),
                    child: Slider(
                      value: widget.brushRadius,
                      min: 0.05,
                      max: 0.35,
                      onChanged: widget.onRadiusChanged,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const SizedBox(
                  width: 50,
                  child: Text('形变力度', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFFFFD166),
                      inactiveTrackColor: const Color(0xFF333333),
                      thumbColor: Colors.white,
                      trackHeight: 2.0,
                    ),
                    child: Slider(
                      value: widget.brushStrength,
                      min: 0.1,
                      max: 1.0,
                      onChanged: widget.onStrengthChanged,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Text(
            '手势在照片上滑动推拉即可精细瘦脸/微调',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
