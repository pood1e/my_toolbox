import 'package:common_ui/style.dart';
import 'package:flutter/material.dart';

class EditorTitle extends StatelessWidget {
  final TextEditingController controller;

  const EditorTitle({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: context.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: context.colorScheme.onSurface,
        height: 1.3,
      ),
      decoration: InputDecoration(
        hintText: '无标题',
        hintStyle: context.textTheme.headlineSmall?.copyWith(
          color: context.colorScheme.outline.withValues(
            alpha: AppAlpha.disabled,
          ),
          fontWeight: FontWeight.bold,
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        isDense: true,
      ),
      maxLines: null,
      textInputAction: TextInputAction.next,
    );
  }
}
