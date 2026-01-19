import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:common_ui/style.dart';
import 'package:flutter/material.dart';

class EditorCanvas extends StatelessWidget {
  final EditorState editorState;

  const EditorCanvas({super.key, required this.editorState});

  @override
  Widget build(BuildContext context) {
    final editorStyle = EditorStyle.mobile(
      cursorColor: context.colorScheme.primary,
      dragHandleColor: context.colorScheme.primary,
      selectionColor: context.colorScheme.primary.withValues(
        alpha: AppAlpha.medium,
      ),
      textStyleConfiguration: TextStyleConfiguration(
        text: context.textTheme.bodyLarge!.copyWith(
          height: 1.6,
          color: context.colorScheme.onSurface,
          fontSize: 16,
        ),
      ),
      // 将 padding 加在这里，而不是外部的 SliverPadding
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacings.page,
        vertical: AppSpacings.m,
      ), // 底部留白直接加在编辑器 padding 里
    );


    return AppFlowyEditor(
      editorState: editorState,
      editable: true,
      editorStyle: editorStyle,
      // 关键修改：
      // 1. 设为 false，让 Editor 自己处理滚动，恢复懒加载性能
      // 2. 放在 NestedScrollView body 里，它会自动接管滚动事件
      shrinkWrap: false,
    );
  }
}
