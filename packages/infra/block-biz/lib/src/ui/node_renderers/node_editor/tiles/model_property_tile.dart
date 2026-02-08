import 'package:app_core/di.dart';
import 'package:flutter/material.dart';

import '../../../../domain/property.dart';
import '../node_editor_controller.dart';
import '../property_editor_controller.dart';
import '../property_editor_descriptor.dart';
import 'property_tile_layout.dart';

class ModalPropertyTile extends ConsumerWidget {
  final PropertyKey propertyKey;
  final ModalEditorDescriptor descriptor;

  const ModalPropertyTile({
    super.key,
    required this.propertyKey,
    required this.descriptor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(propertyEditorControllerProvider(propertyKey));
    final controller = ref.read(
      propertyEditorControllerProvider(propertyKey).notifier,
    );

    return stateAsync.when(
      loading: () => PropertyTileLayout(
        descriptor: descriptor,
        body: const SizedBox(),
        trailing: const SizedBox(),
        isLoading: true,
      ),
      error: (err, _) => PropertyTileLayout(
        descriptor: descriptor,
        body: const SizedBox(),
        trailing: const SizedBox(),
        error: err.toString(),
      ),
      data: (state) {
        final actions = <Widget>[];

        if (descriptor.actionsBuilder != null) {
          actions.addAll(descriptor.actionsBuilder!(context, ref, propertyKey));
        }

        // Modal 逻辑：永远显示 Edit 和 Delete (除非正在保存中，Layout 会处理)

        // Edit 按钮 -> 触发弹窗 -> 自动保存
        actions.add(
          EditorActionButtons.edit(
            onPressed: () async {
              final result = await descriptor.onEdit(context, ref);
              if (result != null) {
                controller.updateDraft(result);
                await controller.save(); // 选中即保存
              }
            },
          ),
        );

        // Delete 按钮
        actions.add(
          EditorActionButtons.delete(
            onPressed: () {
              ref
                  .read(
                    nodeEditorControllerProvider(propertyKey.nodeId).notifier,
                  )
                  .deleteProperty(propertyKey.defId);
            },
          ),
        );

        return PropertyTileLayout(
          descriptor: descriptor,
          body: descriptor.viewerBuilder(propertyKey),
          isLoading: state.isSaving, // 保存时显示转圈
          trailing: Wrap(children: actions),
        );
      },
    );
  }
}
