import 'package:app_core/di.dart';

import '../domain/property_definition.dart';
import 'config_spec_registry.dart';
import 'properties/icon_property.dart';
import 'properties/name_property.dart';
import 'value_types/data_type_registry.dart';

part 'property_descriptor_registry.g.dart';

@Riverpod(keepAlive: true)
List<PropertyDefinition> propertyDefinitions(Ref ref) => [
  NameProperty(),
  IconProperty(),
];

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

@riverpod
Map<String, PropertyDescriptor> propertyDescriptorRegistry(Ref ref) {
  final propertyDefs = ref.read(propertyDescriptorsProvider);
  return {for (final p in propertyDefs) p.propertyId: p};
}

@riverpod
PropertyDescriptor propertyDescriptor(Ref ref, String propertyId) =>
    ref.read(propertyDescriptorRegistryProvider)[propertyId]!;
