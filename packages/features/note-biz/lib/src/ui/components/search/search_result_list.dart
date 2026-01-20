import 'package:app_core/di.dart';
import 'package:common_ui/style.dart';
import 'package:flutter/material.dart';

import '../../state/ui_state.dart';
import 'doc_result_tile.dart';

class SearchResultList extends ConsumerWidget {
  const SearchResultList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncResults = ref.watch(searchResultProvider);
    final keyword = ref.watch(searchKeywordProvider);
    final searchType = ref.watch(searchTypeStateProvider);

    return asyncResults.when(
      // 1. 加载中
      loading: () => const Center(child: CircularProgressIndicator()),

      // 2. 出错
      error: (err, stack) {
        debugPrint('Search error: $err\n$stack');
        return Center(child: Text('搜索出错: $err'));
      },

      // 3. 数据就绪
      data: (results) {
        // 空状态处理
        if (results.isEmpty) {
          return _EmptyState(keyword: keyword, searchType: searchType);
        }

        // 列表展示
        return ListView.separated(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacings.page,
            vertical: AppSpacings.m,
          ),
          itemCount: results.length,
          separatorBuilder: (_, __) => Gaps.v12,
          itemBuilder: (context, index) {
            return DocResultTile(
              data: results[index],
              keyword: keyword,
              // DocResultTile 不需要 searchType，它只看 data 数据
            );
          },
        );
      },
    );
  }
}

/// 私有组件：空状态
class _EmptyState extends StatelessWidget {
  final String keyword;
  final SearchType searchType;

  const _EmptyState({required this.keyword, required this.searchType});

  @override
  Widget build(BuildContext context) {
    if (keyword.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    // 根据当前模式决定 Empty State 的文案和图标
    final (IconData icon, String message) = switch (searchType) {
      SearchType.hybrid => (
        Icons.search_off_rounded,
        '没有找到 "$keyword"\n(AI 也尽力了)',
      ),
      SearchType.keyword => (
        Icons.find_in_page_outlined,
        '没有找到精准匹配 "$keyword"',
      ),
      SearchType.semantic => (Icons.psychology_alt, 'AI 没有联想到相关内容'),
    };

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: AppSizes.illustration, // 64.0
            color: colorScheme.outline.withValues(alpha: AppAlpha.disabled),
          ),
          Gaps.v16,
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: colorScheme.outline),
          ),
        ],
      ),
    );
  }
}
