import 'package:flutter/material.dart';
import '../models/edit_state.dart';

enum AdjustParam {
  exposure('曝光', -1.0, 1.0),
  contrast('对比度', -1.0, 1.0),
  brightness('亮度', -1.0, 1.0),
  saturation('饱和度', -1.0, 1.0),
  vibrance('自然饱和度', -1.0, 1.0),
  highlights('高光', -1.0, 1.0),
  shadows('阴影', -1.0, 1.0),
  temperature('色温', -1.0, 1.0),
  tint('色调', -1.0, 1.0),
  vignette('暗角', 0.0, 1.0),
  grain('颗粒', 0.0, 1.0);

  final String label;
  final double min;
  final double max;
  const AdjustParam(this.label, this.min, this.max);
}

class AdjustPanel extends StatefulWidget {
  final EditState state;
  final VoidCallback onStateChanged;

  const AdjustPanel({
    super.key,
    required this.state,
    required this.onStateChanged,
  });

  @override
  State<AdjustPanel> createState() => _AdjustPanelState();
}

class _AdjustPanelState extends State<AdjustPanel> {
  AdjustParam _selectedParam = AdjustParam.exposure;

  double _getCurrentValue() {
    switch (_selectedParam) {
      case AdjustParam.exposure:
        return widget.state.exposure;
      case AdjustParam.contrast:
        return widget.state.contrast;
      case AdjustParam.brightness:
        return widget.state.brightness;
      case AdjustParam.saturation:
        return widget.state.saturation;
      case AdjustParam.vibrance:
        return widget.state.vibrance;
      case AdjustParam.highlights:
        return widget.state.highlights;
      case AdjustParam.shadows:
        return widget.state.shadows;
      case AdjustParam.temperature:
        return widget.state.temperature;
      case AdjustParam.tint:
        return widget.state.tint;
      case AdjustParam.vignette:
        return widget.state.vignette;
      case AdjustParam.grain:
        return widget.state.grain;
    }
  }

  void _updateValue(double val) {
    setState(() {
      switch (_selectedParam) {
        case AdjustParam.exposure:
          widget.state.exposure = val;
          break;
        case AdjustParam.contrast:
          widget.state.contrast = val;
          break;
        case AdjustParam.brightness:
          widget.state.brightness = val;
          break;
        case AdjustParam.saturation:
          widget.state.saturation = val;
          break;
        case AdjustParam.vibrance:
          widget.state.vibrance = val;
          break;
        case AdjustParam.highlights:
          widget.state.highlights = val;
          break;
        case AdjustParam.shadows:
          widget.state.shadows = val;
          break;
        case AdjustParam.temperature:
          widget.state.temperature = val;
          break;
        case AdjustParam.tint:
          widget.state.tint = val;
          break;
        case AdjustParam.vignette:
          widget.state.vignette = val;
          break;
        case AdjustParam.grain:
          widget.state.grain = val;
          break;
      }
    });
    widget.onStateChanged();
  }

  @override
  Widget build(BuildContext context) {
    double currentVal = _getCurrentValue();
    int displayPercent = (currentVal * 100).round();

    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Slider and Value Indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  _selectedParam.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: displayPercent != 0
                        ? const Color(0xFFFFD166)
                        : const Color(0xFF333333),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    displayPercent > 0 ? '+$displayPercent' : '$displayPercent',
                    style: TextStyle(
                      color: displayPercent != 0 ? Colors.black : Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18, color: Colors.white54),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: '重置此项',
                  onPressed: () => _updateValue(0.0),
                ),
              ],
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFFFFD166),
              inactiveTrackColor: const Color(0xFF3A3A3A),
              thumbColor: Colors.white,
              overlayColor: const Color(0x33FFD166),
              trackHeight: 3.0,
            ),
            child: Slider(
              value: currentVal.clamp(_selectedParam.min, _selectedParam.max),
              min: _selectedParam.min,
              max: _selectedParam.max,
              onChanged: _updateValue,
            ),
          ),
          const SizedBox(height: 6),
          // Horizontal Param List
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: AdjustParam.values.length,
              itemBuilder: (context, index) {
                final param = AdjustParam.values[index];
                final isSelected = param == _selectedParam;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(param.label),
                    selected: isSelected,
                    selectedColor: const Color(0xFFFFD166),
                    backgroundColor: const Color(0xFF2C2C2C),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedParam = param);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
