import 'package:app_core/di.dart';

import '../domain/property_descriptor.dart';
import 'properties/name_property.dart';

part 'property_def_registry.g.dart';

@Riverpod(keepAlive: true)
List<PropertyDescriptor> availablePropertyDefs(Ref ref) => <PropertyDescriptor>[
  NamePropertyDescriptor(),
];

@riverpod
List<PropertyDefaultConfig> defaultConfigPropertyDefs(Ref ref) => [
  NamePropertyDescriptor(),
];

@riverpod
PropertyDefaultConfig defaultConfigPropertyDef(Ref ref, String propertyId) =>
    ref
        .read(defaultConfigPropertyDefsProvider)
        .where((def) => def.propertyId == propertyId)
        .first;

@riverpod
Map<String, PropertyDescriptor> propertyDefRegistry(Ref ref) {
  final propertyDefs = ref.read(availablePropertyDefsProvider);
  return {for (final p in propertyDefs) p.propertyId: p};
}

@riverpod
PropertyDescriptor propertyDescriptor(Ref ref, String defId) =>
    ref.read(propertyDefRegistryProvider)[defId]!;
