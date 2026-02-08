import 'package:flutter/material.dart';

import '../../../domain/property.dart';

import 'property_editor_descriptor.dart';
import 'tiles/direct_property_tile.dart';
import 'tiles/inline_property_tile.dart';
import 'tiles/model_property_tile.dart';

class PropertyEditTile extends StatelessWidget {
  final PropertyKey propertyKey;
  final PropertyEditorDescriptor descriptor;

  const PropertyEditTile({
    super.key,
    required this.propertyKey,
    required this.descriptor,
  });

  @override
  Widget build(BuildContext context) => switch (descriptor) {
    InlineEditorDescriptor d => InlinePropertyTile(
      key: ValueKey(propertyKey),
      propertyKey: propertyKey,
      descriptor: d,
    ),
    ModalEditorDescriptor d => ModalPropertyTile(
      key: ValueKey(propertyKey),
      propertyKey: propertyKey,
      descriptor: d,
    ),
    DirectEditorDescriptor d => DirectPropertyTile(
      key: ValueKey(propertyKey),
      propertyKey: propertyKey,
      descriptor: d,
    ),
  };
}
