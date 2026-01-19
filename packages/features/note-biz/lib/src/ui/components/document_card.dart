// lib/ui/common/cards/document_card.dart
import 'package:app_core/utils.dart';
import 'package:common_ui/style.dart';
import 'package:flutter/material.dart';

import '../../note_domain.dart';

extension DocumentDisplayX on Document {
  /// 1. 获取展示标题
  /// 逻辑：有标题显示标题；没标题尝试截取正文前 20 字；都没有显示“无标题”
  String get displayTitle {
    if (title.isNotEmpty) return title;

    final contentText = _extractTextFromJson(content);
    if (contentText.isNotEmpty) {
      return contentText.length > 20
          ? '${contentText.substring(0, 20)}...'
          : contentText;
    }

    return '无标题笔记';
  }

  /// 2. 获取展示预览 (Body)
  /// 逻辑：从 JSON 中递归提取所有文本，拼接成字符串
  String get displayPreview {
    return _extractTextFromJson(content);
  }

  /// 私有辅助方法：从 AppFlowy/Quill 的复杂 JSON 中提取纯文本
  String _extractTextFromJson(Map<String, dynamic> json) {
    // 简单实现：递归查找所有的 'text' 字段
    // 实际项目中可能需要根据 AppFlowy 的 Node 结构做更精准的解析
    final buffer = StringBuffer();

    void visit(dynamic node) {
      if (node is Map) {
        if (node.containsKey('text') && node['text'] is String) {
          buffer.write(node['text']);
          buffer.write(' '); // 加个空格防止粘连
        }
        node.values.forEach(visit);
      } else if (node is List) {
        node.forEach(visit);
      }
    }

    visit(json);
    return buffer.toString().trim();
  }
}

/// ----------------------------------------------------------------------------
/// 主组件：DocumentCard
/// 职责：负责数据准备、整体容器样式、手势交互
/// ----------------------------------------------------------------------------
class DocumentCard extends StatelessWidget {
  final Document document;
  final VoidCallback onTap;

  const DocumentCard({super.key, required this.document, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // 1. 数据准备 (Data Preparation)
    final displayTitle = document.displayTitle;
    final displayPreview = document.displayPreview;
    final dateStr = DateFormat('MM-dd HH:mm').format(document.updatedAt);
    final isUntitled = document.title.isEmpty;

    // 2. 视觉组装 (Visual Assembly)
    return Card(
      elevation: 0,
      color: context.colorScheme.surfaceContainerLow,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacings.page,
        vertical: AppSpacings.xs,
      ),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.card,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacings.card),
          child: Column(
            mainAxisSize: MainAxisSize.min, // 紧凑布局
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A. 头部：标题与时间
              _CardHeader(
                title: displayTitle,
                date: dateStr,
                isUntitled: isUntitled,
              ),

              // B. 中部：正文预览
              // 逻辑：只有当"非无标题"且"有预览内容"时才显示，避免重复信息
              if (!isUntitled && displayPreview.isNotEmpty) ...[
                Gaps.v4,
                _CardBody(text: displayPreview),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// ----------------------------------------------------------------------------
/// 子组件：头部区域 (Title + Date)
/// ----------------------------------------------------------------------------
class _CardHeader extends StatelessWidget {
  final String title;
  final String date;
  final bool isUntitled;

  const _CardHeader({
    required this.title,
    required this.date,
    required this.isUntitled,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // 顶部对齐
      children: [
        // 1. 标题 (占据剩余空间)
        Expanded(
          child: Text(
            title,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              // 如果是自动提取的标题，颜色淡一点
              color: isUntitled
                  ? context.colorScheme.onSurface.withValues(
                      alpha: AppAlpha.high,
                    )
                  : context.colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // 2. 间距
        Gaps.h8,

        // 3. 时间 (固定宽度或自适应)
        Text(
          date,
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.outline,
            // 防止时间换行，保持一行
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

/// ----------------------------------------------------------------------------
/// 子组件：内容预览区域
/// ----------------------------------------------------------------------------
class _CardBody extends StatelessWidget {
  final String text;

  const _CardBody({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.textTheme.bodyMedium?.copyWith(
        color: context.colorScheme.onSurfaceVariant,
        height: 1.4, // 增加行高，提升阅读体验
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
