import 'package:app_core/di.dart';
import 'package:flutter/material.dart';

import '../../../domain/property.dart';
import 'property_editor_definition.dart';
import 'property_editor_registry.dart';
import 'strategies/actions_property_card.dart';
import 'strategies/direct_property_card.dart';
import 'strategies/inline_property_card.dart';
import 'strategies/modal_property_card.dart';

class PropertyCard extends ConsumerWidget {
  final PropertyKey _propertyKey;

  const PropertyCard({super.key, required PropertyKey propertyKey})
    : _propertyKey = propertyKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final def = ref.watch(propertyEditorDefinitionProvider(_propertyKey.defId));

    return switch (def) {
      InlineEditorDefinition d => InlinePropertyCard(
        key: ValueKey(_propertyKey),
        propertyKey: _propertyKey,
        definition: d,
      ),
      ModalEditorDefinition d => ModalPropertyCard(
        key: ValueKey(_propertyKey),
        propertyKey: _propertyKey,
        definition: d,
      ),
      DirectEditorDefinition d => DirectPropertyCard(
        key: ValueKey(_propertyKey),
        propertyKey: _propertyKey,
        definition: d,
      ),
      ActionsEditorDefinition d => ActionsPropertyCard(
        key: ValueKey(_propertyKey),
        propertyKey: _propertyKey,
        definition: d,
      )
    };
  }
}
