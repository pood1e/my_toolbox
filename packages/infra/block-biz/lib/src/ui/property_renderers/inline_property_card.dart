import 'package:app_core/di.dart';
import 'package:common_ui/component.dart';
import 'package:flutter/material.dart';

import '../../domain/property.dart';
import '../node_renderers/node_editor/components/edit_container.dart';
import '../node_renderers/node_editor/components/read_container.dart';
import '../property_draft/draft_controller.dart';
import 'property_card_shell.dart';
import 'property_renderer.dart';

class InlinePropertyCard extends ConsumerStatefulWidget {
  final PropertyKey propertyKey;
  final InlinePropertyRenderer renderer;

  const InlinePropertyCard({
    super.key,
    required this.propertyKey,
    required this.renderer,
  });

  @override
  ConsumerState<InlinePropertyCard> createState() => _InlinePropertyCardState();
}

class _InlinePropertyCardState extends ConsumerState<InlinePropertyCard> {
  bool _isEditing = false;

  void _enterEditMode() {
    setState(() {
      _isEditing = true;
    });
  }

  void _exitEditMode() {
    if (mounted) {
      setState(() {
        _isEditing = false;
      });
    }
  }

  Future<void> _handleSave() async {
    final notifier = ref.read(
      propertyDraftControllerProvider(widget.propertyKey).notifier,
    );

    await notifier.performSave();
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
    final renderer = widget.renderer;

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
        final layout = renderer.whenSpecAndEdit == null
            ? PropertyViewLayout.horizontal
            : renderer.whenSpecAndEdit!(
                draftState.currentSpec,
                _isEditing,
              );

        return PropertyCardShell(
          layout: layout,
          propertyKey: propertyKey,
          renderer: renderer,
          showDelete: !_isEditing,
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
              // todo: add spec group segment

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
                  builder: renderer.readBuilder,
                ),
        );
      },
    );
  }
}
