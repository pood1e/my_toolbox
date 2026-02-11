import 'package:app_core/di.dart';
import 'package:flutter/material.dart';

import '../../../../domain/property.dart';
import '../../../property_draft/draft_controller.dart';
import '../components/edit_container.dart';
import '../components/property_card_shell.dart';
import '../components/property_error_card.dart';
import '../components/property_loading_card.dart';
import '../components/read_container.dart';
import '../node_editor_controller.dart';
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
  // [新增] 本地 UI 状态：是否处于编辑模式
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    final propertyKey = widget.propertyKey;
    final definition = widget.definition;

    // 监听 Draft 数据状态
    final draftStateAsync = ref.watch(
      propertyDraftControllerProvider(propertyKey),
    );

    return draftStateAsync.when(
      data: (draftState) {
        // 允许保存条件：数据脏了 且 无错误
        final canSave = draftState.isDirty && draftState.error == null;

        // 布局计算：传入当前的编辑模式状态
        final layout = definition.onSpecOrEditChanged(0, _isEditing);

        final notifier = ref.read(
          propertyDraftControllerProvider(propertyKey).notifier,
        );

        return PropertyCardShell(
          key: ValueKey('card_${propertyKey.defId}'),
          icon: definition.icon,
          name: definition.name,
          layout: layout,

          // 根据本地 _isEditing 状态切换视图
          content: _isEditing
              ? EditorContainer(
                  propertyKey: propertyKey,
                  specId: draftState.currentSpec,
                )
              : ReadContainer(
                  propertyKey: propertyKey,
                  builder: definition.readBuilder,
                ),

          actions: [
            // === 编辑模式 UI ===
            if (_isEditing) ...[
              // 1. 保存按钮
              if (canSave)
                IconButton(
                  icon: const Icon(Icons.check_circle, size: 20),
                  color: Colors.green,
                  tooltip: 'Save changes',
                  onPressed: () async {
                    // 执行保存
                    await notifier.performSave();
                    // 保存成功后，退出编辑模式
                    if (mounted) {
                      setState(() {
                        _isEditing = false;
                      });
                    }
                  },
                ),

              // 2. 退出/取消按钮
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                tooltip: 'Exit edit mode',
                onPressed: () {
                  // 仅改变 UI 状态退出编辑模式
                  setState(() {
                    _isEditing = false;
                  });
                  // 可以在这里选择是否回滚草稿: notifier.undo();
                },
              ),
            ]
            // === 只读模式 UI ===
            else ...[
              // 3. 进入编辑模式按钮
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                tooltip: 'Edit',
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
              ),
            ],
          ],

          // 只有在非编辑模式下才允许删除
          onDelete: _isEditing
              ? null
              : () async {
                  await ref
                      .read(
                        nodeEditorControllerProvider(
                          propertyKey.nodeId,
                        ).notifier,
                      )
                      .deleteProperty(propertyKey.defId);
                },
        );
      },
      loading: () => PropertyLoadingCard(name: definition.name),
      error: (e, s) =>
          PropertyErrorCard(name: definition.name, error: e.toString()),
    );
  }
}
