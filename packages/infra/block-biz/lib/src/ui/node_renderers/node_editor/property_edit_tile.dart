import 'package:app_core/di.dart';
import 'package:flutter/material.dart';

import '../../../domain/property.dart';
import 'node_editor_controller.dart';
import 'property_edit_support.dart';

class PropertyEditTile extends ConsumerWidget {
  final PropertyKey _propertyKey;
  final EditorDescriptor _descriptor;

  const PropertyEditTile({
    super.key,
    required PropertyKey propertyKey,
    required EditorDescriptor descriptor,
  }) : _propertyKey = propertyKey,
       _descriptor = descriptor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // meta bar
    // icon | name | --  | [edit] | [remove] |
    Widget body;
    if (_descriptor.valueWidgetBuilder == null) {
      body = _descriptor.configWidgetBuilder(_propertyKey);
    } else {
      final mode = ref.watch(nodeEditorModeControllerProvider(_propertyKey));
      body = mode
          ? _descriptor.configWidgetBuilder(_propertyKey)
          : _descriptor.valueWidgetBuilder!(_propertyKey);
    }
    return Card(
      child: Column(
        spacing: 8,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PropertyMetaBar(propertyKey: _propertyKey, descriptor: _descriptor),
          body,
        ],
      ),
    );
  }
}

class _PropertyMetaBar extends ConsumerWidget {
  final PropertyKey _propertyKey;
  final EditorDescriptor _descriptor;

  const _PropertyMetaBar({
    required PropertyKey propertyKey,
    required EditorDescriptor descriptor,
  }) : _propertyKey = propertyKey,
       _descriptor = descriptor;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListTile(
    leading: Icon(_descriptor.icon),
    title: Text(_descriptor.name),
    trailing: Wrap(
      direction: Axis.horizontal,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (_descriptor.valueWidgetBuilder != null) ...[
          IconButton(
            onPressed: () {
              ref
                  .read(nodeEditorModeControllerProvider(_propertyKey).notifier)
                  .toggle();
            },
            icon: Icon(
              ref.read(nodeEditorModeControllerProvider(_propertyKey))
                  ? Icons.close
                  : Icons.edit,
            ),
          ),
        ],
        IconButton(
          onPressed: () {
            ref
                .read(
                  nodeEditorControllerProvider(_propertyKey.nodeId).notifier,
                )
                .deleteProperty(_propertyKey.defId);
          },
          icon: const Icon(Icons.delete),
        ),
      ],
    ),
  );
}
