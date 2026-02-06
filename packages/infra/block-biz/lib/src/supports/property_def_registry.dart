import 'package:app_core/di.dart';

import '../domain/property_descriptor.dart';
import 'properties/name_property.dart';

part 'property_def_registry.g.dart';

@Riverpod(keepAlive: true)
List<PropertyDescriptor> availablePropertyDefs(Ref ref) {
  return <PropertyDescriptor>[NamePropertyDescriptor()];
}

@riverpod
List<PropertyDefaultConfig> defaultConfigPropertyDefs(Ref ref) {
  return [NamePropertyDescriptor()];
}

@riverpod
PropertyDefaultConfig defaultConfigPropertyDef(Ref ref, String defId) {
  return ref
      .read(defaultConfigPropertyDefsProvider)
      .where((def) => def.defId == defId)
      .first;
}

@riverpod
Map<String, PropertyDescriptor> propertyDefRegistry(Ref ref) {
  final propertyDefs = ref.read(availablePropertyDefsProvider);
  return {for (final p in propertyDefs) p.defId: p};
}

@riverpod
PropertyDescriptor propertyDescriptor(Ref ref, String defId) {
  return ref.read(propertyDefRegistryProvider)[defId]!;
}
