import 'package:app_core/di.dart';
import 'package:flutter/material.dart';

import '../../../../domain/property.dart';
import '../components/property_card_shell.dart';
import '../components/read_container.dart';
import '../property_editor_definition.dart';

class ModalPropertyCard extends ConsumerWidget {
  final PropertyKey propertyKey;
  final ModalEditorDefinition definition;

  const ModalPropertyCard({
    super.key,
    required this.propertyKey,
    required this.definition,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) => PropertyCardShell(
    layout: PropertyViewLayout.horizontal,
    actions: [
      IconButton(
        icon: const Icon(Icons.edit, size: 18),
        onPressed: () {},
        tooltip: 'Open',
      ),
    ],
    propertyKey: propertyKey,
    definition: definition,
    // Modal 通常只显示 ReadValue，默认水平即可
    child: ReadContainer(
      propertyKey: propertyKey,
      builder: definition.readBuilder,
    ),
  );
}
