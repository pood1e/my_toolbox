import 'package:app_core/di.dart';
import 'package:flutter/material.dart';

import '../../memo_domain.dart';
import '../../memo_service.dart';

class MemoTile extends ConsumerWidget {
  final MemoDomain memo;
  final VoidCallback onTap;

  const MemoTile({super.key, required this.memo, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      // 使用 Theme 定义的 Card 样式
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0, // M3 风格通常由颜色表面区分
      color: colorScheme.surfaceContainer,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12), // 匹配 Card 默认圆角
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 内容摘要
              Text(
                memo.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              // 2. 底部信息栏 (时间 + 状态)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    // 简单的格式化，实际建议用 intl 包
                    "${memo.updatedAt.year}-${memo.updatedAt.month}-${memo.updatedAt.day} ${memo.updatedAt.hour}:${memo.updatedAt.minute}",
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                  Row(
                    children: [
                      // 脏标记 (未同步状态)
                      if (memo.isDirty)
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                      // 更多操作菜单
                      _buildActionMenu(context, ref),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionMenu(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        size: 20,
        color: Theme.of(context).colorScheme.outline,
      ),
      onSelected: (value) async {
        final service = await ref.read(memoServiceProvider.future);
        switch (value) {
          case 'toggle_archive':
            if (memo.isArchived) {
              await service.unarchiveMemo(memo.id);
            } else {
              await service.archiveMemo(memo.id);
            }
            break;
          case 'delete':
            await service.deleteMemo(memo.id);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'toggle_archive',
          child: Row(
            children: [
              Icon(memo.isArchived ? Icons.unarchive : Icons.archive, size: 20),
              const SizedBox(width: 12),
              Text(memo.isArchived ? 'Unarchive' : 'Archive'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 20),
              const SizedBox(width: 12),
              Text('Delete'),
            ],
          ),
        ),
      ],
    );
  }
}
