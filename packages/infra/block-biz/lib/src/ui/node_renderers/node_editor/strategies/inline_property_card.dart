import 'package:app_core/di.dart';
import 'package:common_ui/component.dart';
import 'package:flutter/material.dart';

import '../../../../domain/property.dart';
import '../../../property_draft/draft_controller.dart';
import '../components/edit_container.dart';
import '../components/property_card_shell.dart';
import '../components/property_error_card.dart';
import '../components/property_loading_card.dart';
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

    return draftStateAsync.whenUI(
      data: (draftState) {
        // 允许保存条件：数据脏了 且 无错误
        final canSave = draftState.isDirty && draftState.error == null;

        // 布局计算：传入当前的编辑模式状态
        final layout = definition.onSpecOrEditChanged(0, _isEditing);

        final notifier = ref.read(
          propertyDraftControllerProvider(propertyKey).notifier,
        );

        final actions = <Widget>[];
        if (_isEditing) {
          if (canSave) {
            actions.add(
              IconButton(
                icon: const Icon(Icons.check_circle),
                color: Colors.green,
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
            );
          }
          actions.add(
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Exit edit mode',
              onPressed: () {
                // 仅改变 UI 状态退出编辑模式
                setState(() {
                  _isEditing = false;
                });
                // 可以在这里选择是否回滚草稿: notifier.undo();
              },
            ),
          );
        } else {
          actions.add(
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit',
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          );
        }

        return PropertyCardShell(
          layout: layout,
          propertyKey: propertyKey,
          definition: definition,
          showDelete: !_isEditing,
          actions: actions,

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
      }
    );
  }
}
