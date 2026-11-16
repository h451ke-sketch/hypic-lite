import 'package:flutter/material.dart';
import '../models/edit_state.dart';

class BlemishPanel extends StatefulWidget {
  final EditState state;
  final double brushRadius;
  final ValueChanged<double> onRadiusChanged;
  final VoidCallback onUndoSpot;
  final VoidCallback onClearAllSpots;

  const BlemishPanel({
    super.key,
    required this.state,
    required this.brushRadius,
    required this.onRadiusChanged,
    required this.onUndoSpot,
    required this.onClearAllSpots,
  });

  @override
  State<BlemishPanel> createState() => _BlemishPanelState();
}

class _BlemishPanelState extends State<BlemishPanel> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 60,
                child: Text('消除笔大小', style: TextStyle(color: Colors.white70, fontSize: 13)),
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
                    value: widget.brushRadius,
                    min: 0.01,
                    max: 0.10,
                    onChanged: widget.onRadiusChanged,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.undo_rounded, size: 20, color: Colors.white70),
                tooltip: '撤销上一个瑕疵点',
                onPressed: widget.state.blemishSpots.isNotEmpty ? widget.onUndoSpot : null,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.white70),
                tooltip: '清除全部修瑕',
                onPressed: widget.state.blemishSpots.isNotEmpty ? widget.onClearAllSpots : null,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '轻触照片上的斑点、痘痘或杂质即可无痕抚平 (已消除 ${widget.state.blemishSpots.length} 处)',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
