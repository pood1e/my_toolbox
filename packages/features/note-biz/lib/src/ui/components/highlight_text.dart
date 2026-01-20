import 'package:flutter/material.dart';

class HighlightText extends StatelessWidget {
  final String text;
  final String keyword;
  final TextStyle? style;
  final int maxLines;

  /// 是否启用高亮逻辑
  /// - 关键词搜索：true
  /// - 纯语义搜索：false (显示原文本)
  final bool enableHighlight;

  const HighlightText({
    super.key,
    required this.text,
    required this.keyword,
    this.style,
    this.maxLines = 1,
    this.enableHighlight = true,
  });

  @override
  Widget build(BuildContext context) {
    // 1. 如果禁用高亮，或者关键词为空，直接返回普通文本
    if (!enableHighlight || keyword.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    final spans = <InlineSpan>[];
    final lowerText = text.toLowerCase();
    final lowerKeyword = keyword.toLowerCase();
    int start = 0;

    // 2. 查找匹配位置
    int index = lowerText.indexOf(lowerKeyword, start);

    while (index != -1) {
      // A. 匹配前的普通文本
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }

      // B. 匹配的高亮文本
      spans.add(
        TextSpan(
          text: text.substring(index, index + keyword.length),
          style: style?.copyWith(
            // 使用 Material 3 标准的高亮容器色
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      start = index + keyword.length;
      index = lowerText.indexOf(lowerKeyword, start);
    }

    // C. 剩余文本
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return Text.rich(
      TextSpan(children: spans, style: style),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}
