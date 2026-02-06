import 'package:app_core/di.dart';

import '../domain/property_descriptor.dart';
import 'properties/icon_property.dart';
import 'properties/name_property.dart';

part 'property_def_registry.g.dart';

@Riverpod(keepAlive: true)
List<PropertyDescriptor> availablePropertyDefs(Ref ref) => <PropertyDescriptor>[
  NameProperty(),
  IconProperty(),
];

@riverpod
Map<String, PropertyDescriptor> propertyDefRegistry(Ref ref) {
  final propertyDefs = ref.read(availablePropertyDefsProvider);
  return {for (final p in propertyDefs) p.propertyId: p};
}

@riverpod
PropertyDescriptor propertyDescriptor(Ref ref, String defId) =>
    ref.read(propertyDefRegistryProvider)[defId]!;
