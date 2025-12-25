import 'package:app_core/di.dart';
import 'package:flutter/material.dart';

import '../../domain/theme_settings.dart';
import '../../state/theme_settings_notifier.dart';

class ColorStyleSection extends ConsumerWidget {
  final ThemeSettings _settings;

  const ColorStyleSection({super.key, required ThemeSettings settings})
    : _settings = settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSystemColor = _settings.followSystemColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '色彩风格',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('动态取色'),
          subtitle: const Text('基于当前壁纸生成配色方案'),
          value: isSystemColor,
          onChanged: (val) {
            ref
                .read(themeSettingsProvider.notifier)
                .updateTheme(_settings.copyWith(followSystemColor: val));
          },
        ),

        const SizedBox(height: 16),

        // 颜色网格 (带禁用动画)
        _ColorSheet(settings: _settings),
      ],
    );
  }
}

class _ColorSheet extends ConsumerWidget {
  static const List<Color> _colorOptions = [
    Color(0xFF6750A4), // M3 Standard Purple
    Colors.blue,
    Colors.teal,
    Colors.green,
    Colors.orange,
    Colors.deepOrange,
    Colors.red,
    Colors.pink,
    Colors.brown,
    Colors.blueGrey,
  ];

  final ThemeSettings _settings;

  const _ColorSheet({required ThemeSettings settings}) : _settings = settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      opacity: _settings.followSystemColor ? 0.3 : 1.0,
      child: IgnorePointer(
        ignoring: _settings.followSystemColor, // 禁用交互
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('或选择预设主题色：', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: _colorOptions.map((color) {
                final isSelected =
                    !_settings.followSystemColor &&
                    _settings.seedColorValue == color.toARGB32();
                return _ColorCircle(
                  color: color,
                  isSelected: isSelected,
                  onTap: () {
                    // 自动关闭系统取色，并设置新颜色
                    ref
                        .read(themeSettingsProvider.notifier)
                        .updateTheme(
                          _settings.copyWith(
                            followSystemColor: false,
                            seedColorValue: color.toARGB32(),
                          ),
                        );
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorCircle extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorCircle({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            // 选中时边框变色，未选中时透明
            color: isSelected
                ? Theme.of(context).colorScheme.onSurface
                : Colors.transparent,
            width: 2.5,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: .4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 28)
            : null,
      ),
    );
  }
}
