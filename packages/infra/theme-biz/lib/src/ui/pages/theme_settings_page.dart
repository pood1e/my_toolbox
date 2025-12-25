import 'package:app_core/di.dart';
import 'package:flutter/material.dart';

import '../../state/theme_settings_notifier.dart';
import '../components/color_style_section.dart';
import '../components/theme_mode_section.dart';
import '../components/theme_preview_section.dart';

class ThemeSettingsPage extends ConsumerWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSettings = ref.watch(themeSettingsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(title: Text('外观设置')),
          asyncSettings.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    '加载失败: $err',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            ),
            data: (settings) => SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList.list(
                children: [
                  // 3. 模块化组件
                  // 注意：由于现在是 Future，如果这些组件修改了配置，
                  // 必须确保它们调用了 ref.refresh(themeSettingsProvider)
                  // 或者修改的是 AsyncNotifier 的状态，UI 才会刷新。
                  ThemeModeSection(settings: settings),
                  const SizedBox(height: 32),

                  ColorStyleSection(settings: settings),
                  const SizedBox(height: 32),

                  ThemePreviewSection(),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
