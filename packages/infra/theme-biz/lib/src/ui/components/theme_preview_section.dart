import 'package:flutter/material.dart';

class ThemePreviewSection extends StatelessWidget {
  const ThemePreviewSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.palette_outlined, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  '预览效果',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('当前的颜色策略将应用到按钮、图标、状态栏以及各个页面的强调色中。'),
            const SizedBox(height: 20),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Primary'),
                ),
                const SizedBox(width: 12),
                FilledButton.tonal(
                  onPressed: () {},
                  child: const Text('Tonal'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Switch 组件'),
                Switch(value: true, onChanged: (_) {}),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
