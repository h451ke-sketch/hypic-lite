import 'package:flutter/material.dart';
import '../models/edit_state.dart';

class BeautyPanel extends StatefulWidget {
  final EditState state;
  final VoidCallback onStateChanged;

  const BeautyPanel({
    super.key,
    required this.state,
    required this.onStateChanged,
  });

  @override
  State<BeautyPanel> createState() => _BeautyPanelState();
}

class _BeautyPanelState extends State<BeautyPanel> {
  @override
  Widget build(BuildContext context) {
    int smoothPercent = (widget.state.skinSmoothing * 100).round();
    int whitePercent = (widget.state.skinWhitening * 100).round();

    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Skin Smoothing
          Row(
            children: [
              const Icon(Icons.blur_on_rounded, size: 20, color: Color(0xFFFFD166)),
              const SizedBox(width: 8),
              const SizedBox(
                width: 65,
                child: Text('质感磨皮', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
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
                    value: widget.state.skinSmoothing,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (val) {
                      setState(() => widget.state.skinSmoothing = val);
                      widget.onStateChanged();
                    },
                  ),
                ),
              ),
              SizedBox(
                width: 36,
                child: Text(
                  '$smoothPercent%',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: smoothPercent > 0 ? const Color(0xFFFFD166) : Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Skin Whitening
          Row(
            children: [
              const Icon(Icons.brightness_high_rounded, size: 20, color: Color(0xFFFFD166)),
              const SizedBox(width: 8),
              const SizedBox(
                width: 65,
                child: Text('冷白美肤', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
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
                    value: widget.state.skinWhitening,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (val) {
                      setState(() => widget.state.skinWhitening = val);
                      widget.onStateChanged();
                    },
                  ),
                ),
              ),
              SizedBox(
                width: 36,
                child: Text(
                  '$whitePercent%',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: whitePercent > 0 ? const Color(0xFFFFD166) : Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
