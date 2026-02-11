import 'package:app_core/di.dart';
import 'package:common_ui/component.dart';
import 'package:flutter/material.dart';

import '../../../../domain/property.dart';
import '../../../property_draft/draft_controller.dart';
import '../components/edit_container.dart';
import '../components/property_card_shell.dart';
import '../components/read_container.dart';
import '../property_editor_definition.dart';

class InlinePropertyCard extends ConsumerStatefulWidget {
  final PropertyKey propertyKey;
  final InlineEditorDefinition definition;

  const InlinePropertyCard({
    super.key,
    required this.propertyKey,
    required this.definition,
  });

  @override
  ConsumerState<InlinePropertyCard> createState() => _InlinePropertyCardState();
}

class _InlinePropertyCardState extends ConsumerState<InlinePropertyCard> {
  // 本地 UI 状态：是否处于编辑模式
  bool _isEditing = false;

  void _enterEditMode() {
    setState(() {
      _isEditing = true;
    });
    // 可选：进入编辑模式时通知 Controller 聚焦，暂停自动同步
    ref
        .read(propertyDraftControllerProvider(widget.propertyKey).notifier)
        .setFocus(true);
  }

  void _exitEditMode({bool save = false}) {
    if (mounted) {
      setState(() {
        _isEditing = false;
      });
    }
    // 退出编辑模式，恢复自动同步
    ref
        .read(propertyDraftControllerProvider(widget.propertyKey).notifier)
        .setFocus(false);
  }

  Future<void> _handleSave() async {
    final notifier = ref.read(
      propertyDraftControllerProvider(widget.propertyKey).notifier,
    );

    await notifier.performSave();

    // 重新获取最新状态检查是否有错误
    final currentState = ref
        .read(propertyDraftControllerProvider(widget.propertyKey))
        .value;

    // 只有在没有错误的情况下才退出编辑模式
    if (currentState != null && currentState.error == null) {
      _exitEditMode(save: true);
    } else {
      // 可选：这里可以弹出一个 SnackBar 提示错误
      if (mounted && currentState?.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: ${currentState!.error}')));
      }
    }
  }

  void _handleCancel() {
    ref
        .read(propertyDraftControllerProvider(widget.propertyKey).notifier)
        .undo();
    _exitEditMode();
  }

  @override
  Widget build(BuildContext context) {
    final propertyKey = widget.propertyKey;
    final definition = widget.definition;

    final draftStateAsync = ref.watch(
      propertyDraftControllerProvider(propertyKey),
    );

    return draftStateAsync.whenUI(
      data: (draftState) {
        final isDirty = draftState.isDirty;
        final hasError = draftState.error != null;
        final isSaving = draftState.isSaving;

        // 允许保存条件：数据变脏 且 无验证错误 且 没有正在保存
        final canSave = isDirty && !hasError && !isSaving;
        final layout = definition.onSpecOrEditChanged == null
            ? PropertyViewLayout.horizontal
            : definition.onSpecOrEditChanged!(
                draftState.currentSpec,
                _isEditing,
              );

        return PropertyCardShell(
          layout: layout,
          propertyKey: propertyKey,
          definition: definition,
          showDelete: !_isEditing,
          // 编辑模式下通常隐藏删除按钮

          // 使用 Collection if 简化 Action 构建
          actions: [
            if (_isEditing) ...[
              // 保存按钮
              if (isSaving)
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                IconButton(
                  icon: Icon(
                    Icons.check_circle,
                    color: canSave ? Colors.green : Colors.grey,
                  ),
                  onPressed: canSave ? _handleSave : null,
                ),

              // 取消按钮
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: isSaving ? null : _handleCancel,
              ),
            ] else ...[
              // 编辑入口按钮
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _enterEditMode,
              ),
            ],
          ],

          child: _isEditing
              ? EditorContainer(
                  propertyKey: propertyKey,
                  specId: draftState.currentSpec,
                )
              : ReadContainer(
                  propertyKey: propertyKey,
                  builder: definition.readBuilder,
                ),
        );
      },
    );
  }
}
