import 'package:app_core/di.dart';
import 'package:flutter/material.dart';

import '../../../../domain/property.dart';
import '../../../../supports/property_descriptor_registry.dart';
import '../components/edit_container.dart';
import '../components/property_card_shell.dart';
import '../components/read_container.dart';
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
      definition: definition,
      layout: PropertyViewLayout.horizontal,
      actions: descriptor.configSpecDescriptors
          .map(
            (desc) =>
                EditorContainer(propertyKey: propertyKey, specId: desc.id),
          )
          .toList(),
      propertyKey: propertyKey,
      child: ReadContainer(
        propertyKey: propertyKey,
        builder: definition.readBuilder,
      ),
    );
  }
}
