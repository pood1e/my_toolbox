import 'package:app_core/di.dart';
import 'package:flutter/material.dart';

import '../../domain/theme_settings.dart';
import '../../state/theme_settings_notifier.dart';

class ThemeModeSection extends ConsumerWidget {
  final ThemeSettings _settings;

  const ThemeModeSection({super.key, required ThemeSettings settings})
    : _settings = settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '主题模式',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('跟随系统'),
                icon: Icon(Icons.brightness_auto),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('浅色'),
                icon: Icon(Icons.wb_sunny),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('深色'),
                icon: Icon(Icons.dark_mode),
              ),
            ],
            selected: {_settings.themeMode},
            onSelectionChanged: (newSelection) {
              ref
                  .read(themeSettingsProvider.notifier)
                  .updateTheme(
                    _settings.copyWith(themeMode: newSelection.first),
                  );
            },
          ),
        ),
      ],
    );
  }
}
