import 'dart:async';

import 'package:app_core/di.dart';
import 'package:common_ui/style.dart';
import 'package:flutter/material.dart';

import '../../state/ui_state.dart';

class SearchAppBar extends ConsumerStatefulWidget
    implements PreferredSizeWidget {
  const SearchAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  ConsumerState<SearchAppBar> createState() => _SearchAppBarState();
}

class _SearchAppBarState extends ConsumerState<SearchAppBar> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _controller.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    // 防抖：避免用户每输入一个字符都触发重搜索
    _debounceTimer = Timer(AppDurations.medium, () {
      ref.read(searchKeywordProvider.notifier).set(query);
    });
  }

  void _onClear() {
    _controller.clear();
    // 立即清空，不需要防抖
    ref.read(searchKeywordProvider.notifier).set('');
  }

  void _onToggleMode() {
    // 1. 切换模式
    ref.read(searchTypeStateProvider.notifier).toggle();

    // 2. 获取切换后的状态用于提示
    // 注意：这里读取的是 next state，因为上面已经 toggle 过了，但 build 还没刷新完，
    // 为了准确提示，直接读 provider 的新值比较稳妥，或者简单地让 UI 重建后由 build 里的逻辑决定。
    // 这里我们简单做一个延迟读取或者直接根据新状态做提示。

    // 更好的体验是：UI 刷新会自动更新图标，SnackBar 辅助提示文字
    final newType = ref.read(searchTypeStateProvider);
    final String label = switch (newType) {
      SearchType.hybrid => '混合模式 (智能推荐)',
      SearchType.keyword => '关键词模式 (精确匹配)',
      SearchType.semantic => '语义模式 (AI联想)',
    };

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(label),
        duration: const Duration(milliseconds: 1000),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchType = ref.watch(searchTypeStateProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // 根据模式定义 UI 元素
    final (
      IconData typeIcon,
      String hintText,
      Color iconColor,
    ) = switch (searchType) {
      SearchType.hybrid => (
        Icons.auto_awesome,
        '搜索标题、内容或相关意思...',
        colorScheme.primary, // 混合模式用主色高亮
      ),
      SearchType.keyword => (
        Icons.text_fields,
        '精确搜索关键词...',
        colorScheme.outline,
      ),
      SearchType.semantic => (
        Icons.psychology,
        '描述你的想法 (AI)...',
        colorScheme.secondary,
      ),
    };

    return AppBar(
      titleSpacing: 0, // 减小左侧间距
      title: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.search,
        style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: textTheme.bodyLarge?.copyWith(
            color: colorScheme.outline.withValues(alpha: AppAlpha.high),
          ),
          border: InputBorder.none,
          // 调整输入框内边距，使其垂直居中
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacings.m),
        ),
        onChanged: _onSearchChanged,
      ),
      actions: [
        // 1. 清除按钮 (仅当有内容时显示)
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (context, value, child) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.close),
              onPressed: _onClear,
              tooltip: '清除',
            );
          },
        ),

        // 2. 模式切换按钮
        IconButton(
          onPressed: _onToggleMode,
          icon: Icon(typeIcon, color: iconColor),
          tooltip: '切换搜索模式',
        ),

        Gaps.h8, // 右侧留白
      ],
    );
  }
}
