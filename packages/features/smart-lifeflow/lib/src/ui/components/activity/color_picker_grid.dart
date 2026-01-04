import 'package:common_ui/style.dart';
import 'package:flutter/material.dart';

import 'activity_presets.dart';

class ColorPickerGrid extends StatelessWidget {
  final String? selectedHex;
  final ValueChanged<String> onColorSelected;

  const ColorPickerGrid({
    super.key,
    required this.selectedHex,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacings.m, // 12.0
      runSpacing: AppSpacings.m,
      children: ActivityColors.presets.map((hex) {
        final isSelected = selectedHex == hex;
        final color = ActivityColors.fromHex(hex);

        return GestureDetector(
          onTap: () => onColorSelected(hex),
          child: AnimatedContainer(
            duration: AppDurations.fast,
            width: AppSizes.iconBoxSmall,
            // 42.0
            height: AppSizes.iconBoxSmall,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.white, width: 3)
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        // 选中时的高亮阴影 (0.6 Alpha)
                        color: color.withValues(alpha: 0.6),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
