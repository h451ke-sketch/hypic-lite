import 'package:flutter/material.dart';
import '../models/edit_state.dart';

enum CropRatio {
  free('自由', null),
  r1_1('1:1', 1.0),
  r3_4('3:4', 3.0 / 4.0),
  r4_3('4:3', 4.0 / 3.0),
  r9_16('9:16', 9.0 / 16.0),
  r16_9('16:9', 16.0 / 9.0);

  final String label;
  final double? ratio;
  const CropRatio(this.label, this.ratio);
}

class CropPanel extends StatefulWidget {
  final EditState state;
  final VoidCallback onStateChanged;

  const CropPanel({
    super.key,
    required this.state,
    required this.onStateChanged,
  });

  @override
  State<CropPanel> createState() => _CropPanelState();
}

class _CropPanelState extends State<CropPanel> {
  CropRatio _selectedRatio = CropRatio.free;

  void _applyRatio(CropRatio cropRatio) {
    setState(() => _selectedRatio = cropRatio);
    if (cropRatio.ratio == null) {
      widget.state.cropRect = null;
    } else {
      double targetRatio = cropRatio.ratio!;
      // Center crop in normalized [0, 1] space
      if (targetRatio >= 1.0) {
        double height = 1.0 / targetRatio;
        double top = (1.0 - height) / 2.0;
        widget.state.cropRect = Rect.fromLTWH(0.0, top, 1.0, height);
      } else {
        double width = targetRatio;
        double left = (1.0 - width) / 2.0;
        widget.state.cropRect = Rect.fromLTWH(left, 0.0, width, 1.0);
      }
    }
    widget.onStateChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quick Rotate / Flip Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.rotate_right_rounded, size: 18),
                  label: const Text('旋转90°'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF444444)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    setState(() {
                      widget.state.rotationQuarterTurns =
                          (widget.state.rotationQuarterTurns + 1) % 4;
                    });
                    widget.onStateChanged();
                  },
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.flip_rounded, size: 18),
                  label: const Text('水平镜像'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: widget.state.flipHorizontal
                        ? const Color(0xFFFFD166)
                        : Colors.white,
                    side: BorderSide(
                      color: widget.state.flipHorizontal
                          ? const Color(0xFFFFD166)
                          : const Color(0xFF444444),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    setState(() {
                      widget.state.flipHorizontal = !widget.state.flipHorizontal;
                    });
                    widget.onStateChanged();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Aspect Ratio List
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: CropRatio.values.length,
              itemBuilder: (context, index) {
                final ratio = CropRatio.values[index];
                final isSelected = ratio == _selectedRatio;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(ratio.label),
                    selected: isSelected,
                    selectedColor: const Color(0xFFFFD166),
                    backgroundColor: const Color(0xFF2C2C2C),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onSelected: (val) {
                      if (val) _applyRatio(ratio);
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
