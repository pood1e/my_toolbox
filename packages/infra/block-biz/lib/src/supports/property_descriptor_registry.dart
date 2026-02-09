import 'package:app_core/di.dart';

import '../domain/property_definition.dart';
import '../domain/source_definition.dart';
import 'compute_engines/compute_engine_registry.dart';
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
  final processors = ref.read(processorsProvider);
  final transformers = ref.read(transformersProvider);
  final aggregators = ref.read(aggregatorsProvider);
  final dataTypes = ref.read(dataTypesProvider);
  return definitions
      .map(
        (def) => PropertyDescriptor(
          propertyId: def.propertyId,
          dateType: dataTypes.where((type) => type.id == def.dateTypeId).first,
          sourceDescriptors: def.sourceDefinitions
              .map(
                (src) => switch (src) {
                  SingleStaticSourceDefinition() =>
                    SourceDescriptor.singleStatic(
                      name: src.name,
                      processor: processors
                          .where((processor) => processor.id == src.processorId)
                          .first,
                    ),
                  SingleRefSourceDefinition() => SourceDescriptor.singleRef(
                    name: src.name,
                    propertyIds: src.propertyIds,
                    transformers: transformers
                        .where((trans) => src.transformerIds.contains(trans.id))
                        .toSet(),
                  ),
                  MultiStaticSourceDefinition() => SourceDescriptor.multiStatic(
                    name: src.name,
                    processor: processors
                        .where((processor) => processor.id == src.processorId)
                        .first,
                    aggregators: aggregators
                        .where((agg) => src.aggs.contains(agg.id))
                        .toSet(),
                  ),
                  MultiRefSourceDefinition() => SourceDescriptor.multiRef(
                    name: src.name,
                    propertyIds: src.propertyIds,
                    transformers: transformers
                        .where((trans) => src.transformerIds.contains(trans.id))
                        .toSet(),
                    aggregators: aggregators
                        .where((agg) => src.aggs.contains(agg.id))
                        .toSet(),
                  ),
                  HybridSourceDefinition() => SourceDescriptor.hybrid(
                    name: src.name,
                    propertyIds: src.propertyIds,
                    transformers: transformers
                        .where((trans) => src.transformerIds.contains(trans.id))
                        .toSet(),
                    aggregators: aggregators
                        .where((agg) => src.aggs.contains(agg.id))
                        .toSet(),
                    processor: processors
                        .where((processor) => processor.id == src.processorId)
                        .first,
                  ),
                },
              )
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
