import 'package:app_core/di.dart';
import 'package:flutter/material.dart';

import '../../../../domain/property.dart';
import '../node_editor_controller.dart';
import '../property_editor_controller.dart';
import '../property_editor_descriptor.dart';
import 'property_tile_layout.dart';

class InlinePropertyTile extends ConsumerStatefulWidget {
  final PropertyKey propertyKey;
  final InlineEditorDescriptor descriptor;

  const InlinePropertyTile({
    super.key,
    required this.propertyKey,
    required this.descriptor,
  });

  @override
  ConsumerState<InlinePropertyTile> createState() => _InlinePropertyTileState();
}

class _InlinePropertyTileState extends ConsumerState<InlinePropertyTile> {
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(
      propertyEditorControllerProvider(widget.propertyKey),
    );
    final controller = ref.read(
      propertyEditorControllerProvider(widget.propertyKey).notifier,
    );

    return stateAsync.when(
      loading: () => PropertyTileLayout(
        descriptor: widget.descriptor,
        body: const Text('...'),
        trailing: const SizedBox(),
        isLoading: true,
      ),
      error: (err, _) => PropertyTileLayout(
        descriptor: widget.descriptor,
        body: const Text('Error'),
        trailing: const SizedBox(),
        error: err.toString(),
      ),
      data: (state) {
        // 1. 决定 Body 显示什么
        final body = _isEditing
            ? widget.descriptor.editorBuilder(widget.propertyKey)
            : widget.descriptor.viewerBuilder(widget.propertyKey);

        // 2. 决定 Buttons 显示什么 (完全自治)
        final actions = <Widget>[];

        // 插入自定义 Action
        if (widget.descriptor.actionsBuilder != null) {
          actions.addAll(
            widget.descriptor.actionsBuilder!(context, ref, widget.propertyKey),
          );
        }

        if (_isEditing) {
          // --- 编辑模式 ---

          // Save 按钮 (仅 Dirty 时显示)
          if (state.isDirty) {
            actions.add(
              EditorActionButtons.save(
                isValid: state.isValid,
                onPressed: state.canSave
                    ? () async {
                        await controller.save();
                        if (mounted && state.isValid)
                          setState(() => _isEditing = false);
                      }
                    : null,
              ),
            );
          }

          // Cancel 按钮 (始终显示，用于退出)
          actions.add(
            EditorActionButtons.cancel(
              onPressed: () {
                if (state.isDirty) controller.cancelChanges();
                setState(() => _isEditing = false);
              },
              tooltip: state.isDirty ? 'Discard changes' : 'Stop editing',
            ),
          );
        } else {
          // --- 查看模式 ---

          // Edit 按钮
          actions.add(
            EditorActionButtons.edit(
              onPressed: () => setState(() => _isEditing = true),
            ),
          );

          // Delete 按钮
          actions.add(
            EditorActionButtons.delete(
              onPressed: () {
                ref
                    .read(
                      nodeEditorControllerProvider(
                        widget.propertyKey.nodeId,
                      ).notifier,
                    )
                    .deleteProperty(widget.propertyKey.defId);
              },
            ),
          );
        }

        return PropertyTileLayout(
          descriptor: widget.descriptor,
          body: body,
          isLoading: state.isSaving, // 如果正在保存，Layout 会覆盖 trailing 显示 loading
          trailing: Wrap(children: actions),
        );
      },
    );
  }
}
