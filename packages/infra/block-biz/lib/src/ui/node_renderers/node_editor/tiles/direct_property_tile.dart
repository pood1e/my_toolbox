import 'package:app_core/di.dart';
import 'package:flutter/material.dart';

import '../../../../domain/property.dart';
import '../node_editor_controller.dart';
import '../property_editor_controller.dart';
import '../property_editor_descriptor.dart';
import 'property_tile_layout.dart';

class DirectPropertyTile extends ConsumerWidget {
  final PropertyKey propertyKey;
  final DirectEditorDescriptor descriptor;

  const DirectPropertyTile({
    super.key,
    required this.propertyKey,
    required this.descriptor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Direct 模式依然需要 watch 状态以处理 Delete 或 loading 状态
    final stateAsync = ref.watch(propertyEditorControllerProvider(propertyKey));

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

        // Direct 模式通常只需要 Delete，因为编辑是在 Body 组件内直接发生的
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
          body: descriptor.widgetBuilder(propertyKey),
          isLoading: state.isSaving,
          trailing: Wrap(children: actions),
        );
      },
    );
  }
}
