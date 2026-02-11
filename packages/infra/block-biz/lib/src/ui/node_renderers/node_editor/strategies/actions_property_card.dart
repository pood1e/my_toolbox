import 'package:app_core/di.dart';
import 'package:flutter/material.dart';

import '../../../../domain/property.dart';
import '../../../../supports/property_descriptor_registry.dart';
import '../components/edit_container.dart';
import '../components/property_card_shell.dart';
import '../components/read_container.dart';
import '../node_editor_controller.dart';
import '../property_editor_definition.dart';

class ActionsPropertyCard extends ConsumerWidget {
  final PropertyKey propertyKey;
  final ActionsEditorDefinition definition;

  const ActionsPropertyCard({
    super.key,
    required this.propertyKey,
    required this.definition,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final descriptor = ref.read(propertyDescriptorProvider(propertyKey.defId));
    return PropertyCardShell(
      icon: definition.icon,
      name: definition.name,
      layout: PropertyViewLayout.horizontal,
      // Modal 通常只显示 ReadValue，默认水平即可
      content: ReadContainer(
        propertyKey: propertyKey,
        builder: definition.readBuilder,
      ),

      actions: descriptor.configSpecDescriptors
          .map(
            (desc) =>
                EditorContainer(propertyKey: propertyKey, specId: desc.id),
          )
          .toList(),
      onDelete: () async {
        await ref
            .read(nodeEditorControllerProvider(propertyKey.nodeId).notifier)
            .deleteProperty(propertyKey.defId);
      },
    );
  }
}
