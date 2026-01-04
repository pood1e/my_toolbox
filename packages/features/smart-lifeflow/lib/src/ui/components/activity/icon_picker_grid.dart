import 'package:common_ui/style.dart';
import 'package:flutter/material.dart';

import 'activity_presets.dart';

class IconPickerGrid extends StatelessWidget {
  final String? selectedIcon;
  final ValueChanged<String> onIconSelected;

  const IconPickerGrid({
    super.key,
    required this.selectedIcon,
    required this.onIconSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacings.m, // 12.0
      runSpacing: AppSpacings.m,
      children: ActivityIcons.presets.map((icon) {
        final isSelected = selectedIcon == icon;

        return GestureDetector(
          onTap: () => onIconSelected(icon),
          child: AnimatedContainer(
            duration: AppDurations.fast,
            width: AppSizes.iconBoxMedium,
            // 48.0
            height: AppSizes.iconBoxMedium,
            decoration: BoxDecoration(
              color: isSelected
                  ? context.colorScheme.primary.withValues(
                      alpha: AppAlpha.medium,
                    )
                  : context.colorScheme.surfaceContainerHighest.withValues(
                      alpha: AppAlpha.medium,
                    ),
              borderRadius: BorderRadius.all(AppRadius.circleL), // 12.0
              border: isSelected
                  ? Border.all(color: context.colorScheme.primary, width: 2)
                  : Border.all(color: Colors.transparent),
            ),
            alignment: Alignment.center,
            child: Text(icon, style: context.textTheme.headlineSmall),
          ),
        );
      }).toList(),
    );
  }
}
