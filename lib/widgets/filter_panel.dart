import 'package:flutter/material.dart';
import '../models/edit_state.dart';
import '../models/filter_preset.dart';

class FilterPanel extends StatefulWidget {
  final EditState state;
  final VoidCallback onStateChanged;

  const FilterPanel({
    super.key,
    required this.state,
    required this.onStateChanged,
  });

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  @override
  Widget build(BuildContext context) {
    final activePreset = FilterPreset.presets.firstWhere(
      (p) => p.id == widget.state.filterId,
      orElse: () => FilterPreset.presets.first,
    );

    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Filter Intensity Slider (only when non-original filter selected)
          if (widget.state.filterId != 'original')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Text(
                    '${activePreset.name} 浓度',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFFFFD166),
                        inactiveTrackColor: const Color(0xFF3A3A3A),
                        thumbColor: Colors.white,
                        trackHeight: 2.5,
                      ),
                      child: Slider(
                        value: widget.state.filterIntensity,
                        min: 0.0,
                        max: 1.0,
                        onChanged: (val) {
                          setState(() => widget.state.filterIntensity = val);
                          widget.onStateChanged();
                        },
                      ),
                    ),
                  ),
                  Text(
                    '${(widget.state.filterIntensity * 100).round()}%',
                    style: const TextStyle(color: Color(0xFFFFD166), fontSize: 12),
                  ),
                ],
              ),
            ),

          // Horizontal Filter Presets
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: FilterPreset.presets.length,
              itemBuilder: (context, index) {
                final preset = FilterPreset.presets[index];
                final isSelected = preset.id == widget.state.filterId;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      widget.state.filterId = preset.id;
                      if (preset.id == 'original') {
                        widget.state.filterIntensity = 1.0;
                      }
                    });
                    widget.onStateChanged();
                  },
                  child: Container(
                    width: 66,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: preset.previewColor,
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFFFD166)
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFFFD166).withOpacity(0.4),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : null,
                          ),
                          child: isSelected && preset.id != 'original'
                              ? const Center(
                                  child: Icon(Icons.check, size: 20, color: Colors.black87),
                                )
                              : null,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          preset.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? const Color(0xFFFFD166) : Colors.white70,
                          ),
                        ),
                      ],
                    ),
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
