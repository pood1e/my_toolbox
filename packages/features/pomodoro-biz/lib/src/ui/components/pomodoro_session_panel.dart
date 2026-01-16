import 'package:app_core/di.dart';
import 'package:flutter/material.dart';

import '../../pomodoro_domain.dart';
import '../../providers.dart';

class PomodoroSessionPanel extends ConsumerWidget {
  final PomodoroSession session;

  const PomodoroSessionPanel({super.key, required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      // 1. 确保 Column 内部元素水平居中
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // === 任务名称 (Name) ===
        _AutoSaveTextField(
          key: ValueKey('name_${session.id}'),
          initialText: session.name,
          // 2. 传入居中参数
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
          hintText: '任务名称',
          maxLines: 1,
          onSave: (newName) async {
            if (newName != session.name) {
              final service = await ref.read(pomodoroServiceProvider.future);
              await service.updateSession(session.id, newName, session.note);
            }
          },
        ),

        const SizedBox(height: 8),

        // === 备注 (Note) ===
        // 3. 移除了之前的 Container 和 decoration (边框/背景)
        // 现在看起来就是一行普通的灰色文字
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24), // 给一点左右边距防止贴边
          child: _AutoSaveTextField(
            key: ValueKey('note_${session.id}'),
            initialText: session.note ?? '',
            textAlign: TextAlign.center,
            // 居中
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
              // 颜色淡一点
              height: 1.3,
            ),
            hintText: '点击添加备注...',
            // 提示语
            minLines: 1,
            maxLines: 3,
            // 限制最大行数
            onSave: (newNote) async {
              if (newNote != session.note) {
                final service = await ref.read(pomodoroServiceProvider.future);
                await service.updateSession(session.id, session.name, newNote);
              }
            },
          ),
        ),
      ],
    );
  }
}

// =========================================================
// 内部私有组件：处理焦点与自动保存逻辑
// =========================================================

class _AutoSaveTextField extends StatefulWidget {
  final String initialText;
  final TextStyle? style;
  final String hintText;
  final int minLines;
  final int maxLines;
  final TextAlign textAlign; // 新增：对齐方式
  final Future<void> Function(String newValue) onSave;

  const _AutoSaveTextField({
    super.key,
    required this.initialText,
    this.style,
    required this.hintText,
    this.minLines = 1,
    this.maxLines = 1,
    this.textAlign = TextAlign.start, // 默认为左对齐
    required this.onSave,
  });

  @override
  State<_AutoSaveTextField> createState() => _AutoSaveTextFieldState();
}

class _AutoSaveTextFieldState extends State<_AutoSaveTextField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late String _lastSavedValue;

  @override
  void initState() {
    super.initState();
    _lastSavedValue = widget.initialText;
    _controller = TextEditingController(text: widget.initialText);
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant _AutoSaveTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialText != oldWidget.initialText && !_focusNode.hasFocus) {
      _lastSavedValue = widget.initialText;
      _controller.text = widget.initialText;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      final currentText = _controller.text.trim();
      if (currentText != _lastSavedValue) {
        _lastSavedValue = currentText;
        widget.onSave(currentText);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      style: widget.style,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      textAlign: widget.textAlign,
      // 应用对齐方式
      // collapsed 去除所有边框，实现"所见即所得"的文本效果
      decoration: InputDecoration.collapsed(
        hintText: widget.hintText,
        hintStyle: widget.style?.copyWith(
          color: Theme.of(context).hintColor.withOpacity(0.4),
        ),
      ),
      textInputAction: widget.maxLines == 1
          ? TextInputAction.done
          : TextInputAction.newline,
      onSubmitted: widget.maxLines == 1 ? (_) => _focusNode.unfocus() : null,
    );
  }
}
