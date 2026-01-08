import 'package:app_core/di.dart';
import 'package:common_ui/style.dart';
import 'package:flutter/material.dart';

import '../../memo_domain.dart';
import '../../memo_service.dart';

class MemoTile extends ConsumerWidget {
  final MemoDomain memo;
  final VoidCallback onTap;

  const MemoTile({super.key, required this.memo, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      // 1. 使用预设边距
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacings.page, // 24.0
        vertical: AppSpacings.s, // 8.0
      ),
      elevation: 0,
      color: context.colorScheme.surfaceContainer,
      // 2. 使用语义化 Shape (虽然 Card 默认有圆角，但显式指定更安全)
      shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.card,
        child: Padding(
          // 3. 使用预设内边距
          padding: const EdgeInsets.all(AppSpacings.card),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                memo.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodyLarge,
              ),
              // 4. 使用预设间隔
              Gaps.v12,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(memo.updatedAt),
                    style: context.textTheme.labelSmall?.copyWith(
                      color: context.colorScheme.outline,
                    ),
                  ),
                  Row(
                    children: [
                      if (memo.isDirty) ...[
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: AppSizes.iconSmall, // 16.0
                          color: context.colorScheme.primary,
                        ),
                        Gaps.h8,
                      ],
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
    // PopupMenu 的样式比较特殊，通常保持默认或单独封装
    return SizedBox(
      height: AppSizes.iconMedium, // 24.0
      width: AppSizes.iconMedium,
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        icon: Icon(
          Icons.more_vert,
          size: AppSizes.iconSmall, // 使用统一尺寸
          color: context.colorScheme.outline,
        ),
        onSelected: (value) async {
          final service = await ref.read(memoServiceProvider.future);
          if (value == 'toggle_archive') {
            memo.isArchived
                ? await service.unarchiveMemo(memo.id)
                : await service.archiveMemo(memo.id);
          } else if (value == 'delete') {
            await service.deleteMemo(memo.id);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'toggle_archive',
            child: Row(
              children: [
                Icon(
                  memo.isArchived ? Icons.unarchive : Icons.archive,
                  size: AppSizes.iconMedium,
                ),
                Gaps.h12,
                Text(memo.isArchived ? 'Unarchive' : 'Archive'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: AppSizes.iconMedium),
                Gaps.h12,
                Text('Delete'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month}-${d.day} ${d.hour}:${d.minute}';
}
