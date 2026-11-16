import 'package:flutter/material.dart';

enum MainTool {
  filter('滤镜', Icons.filter_vintage_outlined),
  adjust('调色', Icons.tune_rounded),
  curves('曲线', Icons.show_chart_rounded),
  hsl('HSL', Icons.palette_outlined),
  beauty('美颜', Icons.face_retouching_natural_rounded),
  liquify('液化推脸', Icons.blur_circular_rounded),
  blemish('修瑕', Icons.healing_rounded),
  crop('裁切旋转', Icons.crop_rotate_rounded);

  final String label;
  final IconData icon;
  const MainTool(this.label, this.icon);
}

class BottomToolbar extends StatelessWidget {
  final MainTool activeTool;
  final ValueChanged<MainTool> onToolSelected;

  const BottomToolbar({
    super.key,
    required this.activeTool,
    required this.onToolSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        border: Border(
          top: BorderSide(color: Color(0xFF222222), width: 1.0),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: MainTool.values.length,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemBuilder: (context, index) {
          final tool = MainTool.values[index];
          final isSelected = tool == activeTool;

          return InkWell(
            onTap: () => onToolSelected(tool),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 68,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisAlignment: MainTool.values.length > 5
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.spaceEvenly,
                children: [
                  Icon(
                    tool.icon,
                    size: 24,
                    color: isSelected ? const Color(0xFFFFD166) : const Color(0xFF999999),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tool.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? const Color(0xFFFFD166) : const Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
