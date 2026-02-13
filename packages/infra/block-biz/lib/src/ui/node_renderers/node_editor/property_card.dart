import 'package:app_core/di.dart';
import 'package:flutter/material.dart';

import '../../../domain/property.dart';
import '../../property_renderers/expansion_property_card.dart';
import '../../property_renderers/inline_property_card.dart';
import '../../property_renderers/modal_property_card.dart';
import '../../property_renderers/property_editor_registry.dart';
import '../../property_renderers/property_renderer.dart';

class PropertyCard extends ConsumerWidget {
  final PropertyKey _propertyKey;

  const PropertyCard({super.key, required PropertyKey propertyKey})
    : _propertyKey = propertyKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final def = ref.watch(propertyRendererProvider(_propertyKey.defId));

    return switch (def) {
      InlinePropertyRenderer d => InlinePropertyCard(
        key: ValueKey(_propertyKey),
        propertyKey: _propertyKey,
        renderer: d,
      ),
      ModalPropertyRenderer d => ModalPropertyCard(
        key: ValueKey(_propertyKey),
        propertyKey: _propertyKey,
        renderer: d,
      ),
      ExpansionPropertyRenderer d => ExpansionPropertyCard(
        key: ValueKey(_propertyKey),
        propertyKey: _propertyKey,
        renderer: d,
      ),
      // TODO: Handle this case.
      DirectPropertyRenderer() => throw UnimplementedError(),
    };
  }
}
