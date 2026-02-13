import 'package:app_core/di.dart';

import '../domain/property_definition.dart';
import '../supports/property_renderers/property_renderer.dart';
import '../supports/support_properties.dart';
import 'config_spec_registry.dart';
import 'data_type_registry.dart';

part 'property_descriptor_registry.g.dart';

@Riverpod(keepAlive: true)
Map<String, PropertyDefinition> propertyDefinitionRegistry(Ref ref) {
  final propertyDefs = ref.read(propertyDefinitionsProvider);
  return {for (final p in propertyDefs) p.propertyId: p};
}

@riverpod
PropertyDefinition? propertyDefinition(Ref ref, String propertyId) =>
    ref.read(propertyDefinitionRegistryProvider)[propertyId];

@Riverpod(keepAlive: true)
List<PropertyDescriptor> propertyDescriptors(Ref ref) {
  final definitions = ref.read(propertyDefinitionsProvider);
  final dataTypes = ref.read(dataTypesProvider);
  final configSpecDescriptorRegistry = ref.read(
    configSpecDescriptorRegistryProvider,
  );

  return definitions
      .map(
        (def) => PropertyDescriptor(
          propertyId: def.propertyId,
          dateType: dataTypes.where((type) => type.id == def.dateTypeId).first,
          configSpecDescriptors: def.conficSpecDefinitions
              .map((defId) => configSpecDescriptorRegistry[defId]!)
              .toList(),
        ),
      )
      .toList();
}

@Riverpod(keepAlive: true)
Map<String, PropertyDescriptor> propertyDescriptorRegistry(Ref ref) {
  final propertyDefs = ref.read(propertyDescriptorsProvider);
  return {for (final p in propertyDefs) p.propertyId: p};
}

@riverpod
PropertyDescriptor? propertyDescriptor(Ref ref, String propertyId) =>
    ref.read(propertyDescriptorRegistryProvider)[propertyId];

@riverpod
PropertyRenderer propertyRenderer(Ref ref, String propertyId) => ref
    .read(propertyRenderersProvider)
    .where((def) => def.propertyId == propertyId)
    .first;
