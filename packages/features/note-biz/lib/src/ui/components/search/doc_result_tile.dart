import 'package:app_core/route.dart';
import 'package:common_ui/style.dart';
import 'package:flutter/material.dart';

import '../../../service/note_service.dart';
import '../highlight_text.dart';

class DocResultTile extends StatelessWidget {
  final DocSearchResult data;
  final String keyword;

  const DocResultTile({super.key, required this.data, required this.keyword});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.push('/note/document/${data.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacings.card),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. 标题 (始终尝试高亮)
              _TileHeader(title: data.title, keyword: keyword),

              // 2. 匹配内容块
              if (data.blocks.isNotEmpty) ...[
                Gaps.v12,
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: Theme.of(context).colorScheme.outlineVariant
                      .withValues(alpha: AppAlpha.medium),
                ),
                Gaps.v12,

                // 展示前 3 条
                ...data.blocks
                    .take(3)
                    .map(
                      (block) => _BlockMatchItem(
                        content: block.content,
                        keyword: keyword,
                        isSemanticOnly: block.isSemanticOnly,
                      ),
                    ),

                // 剩余数量提示
                if (data.blocks.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacings.xs),
                    child: Text(
                      '还有 ${data.blocks.length - 3} 处相关...',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 内部组件：标题行
class _TileHeader extends StatelessWidget {
  final String title;
  final String keyword;

  const _TileHeader({required this.title, required this.keyword});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.description_outlined,
          size: AppSizes.iconMedium,
          color: Theme.of(context).colorScheme.primary,
        ),
        Gaps.h8,
        Expanded(
          child: HighlightText(
            text: title,
            keyword: keyword,
            enableHighlight: true, // 标题总是尝试高亮
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

/// 内部组件：单个匹配块
class _BlockMatchItem extends StatelessWidget {
  final String content;
  final String keyword;
  final bool isSemanticOnly;

  const _BlockMatchItem({
    required this.content,
    required this.keyword,
    required this.isSemanticOnly,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacings.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图标指示器
          Padding(
            padding: const EdgeInsets.only(top: 8, right: AppSpacings.s),
            child: Icon(
              // 语义匹配用星星，关键词匹配用圆点
              isSemanticOnly ? Icons.auto_awesome : Icons.circle,
              size: isSemanticOnly ? 14 : 4,
              color: isSemanticOnly
                  ? colorScheme.tertiary
                  : colorScheme.outline,
            ),
          ),

          // 内容文本
          Expanded(
            child: HighlightText(
              text: content,
              keyword: keyword,
              // 如果是纯语义匹配，不高亮；如果是关键词匹配，高亮
              enableHighlight: !isSemanticOnly,
              maxLines: 2,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
