import 'package:common_ui/style.dart';
import 'package:flutter/material.dart';

import 'activity_preview_card.dart';
import 'color_picker_grid.dart';
import 'icon_picker_grid.dart';

class EditActivityFormBody extends StatelessWidget {
  final TextEditingController nameController;
  final String selectedIcon;
  final String selectedColorHex;

  // Callbacks
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onColorSelected;
  final ValueChanged<String> onIconSelected;

  const EditActivityFormBody({
    super.key,
    required this.nameController,
    required this.selectedIcon,
    required this.selectedColorHex,
    required this.onNameChanged,
    required this.onColorSelected,
    required this.onIconSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacings.page),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 预览区域
          Center(
            child: ActivityPreviewCard(
              name: nameController.text,
              icon: selectedIcon,
              colorHex: selectedColorHex,
            ),
          ),

          Gaps.v32,

          // 2. 名称输入
          _SectionLabel(label: '活动名称 (Name)'),
          Gaps.v8,
          TextFormField(
            controller: nameController,
            onChanged: onNameChanged,
            // 触发父组件 setState 或通知 Logic
            style: context.textTheme.bodyLarge,
            decoration: AppInputStyles.outline(
              context,
              label: '例如: 写代码, 健身, 阅读...',
              prefixIcon: Icons.edit_outlined,
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? '名称不能为空' : null,
          ),

          Gaps.v24,

          // 3. 颜色选择
          _SectionLabel(label: '主题色 (Color)'),
          Gaps.v12,
          ColorPickerGrid(
            selectedHex: selectedColorHex,
            onColorSelected: onColorSelected,
          ),

          Gaps.v24,

          // 4. 图标选择
          _SectionLabel(label: '图标 (Icon)'),
          Gaps.v12,
          IconPickerGrid(
            selectedIcon: selectedIcon,
            onIconSelected: onIconSelected,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: context.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: context.colorScheme.onSurface.withValues(alpha: AppAlpha.high),
        letterSpacing: 0.5,
      ),
    );
  }
}
