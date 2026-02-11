import 'package:app_core/di.dart';

import '../domain/config_spec.dart';
import '../domain/property_config.dart';
import 'compute_engines/compute_engine_registry.dart';
import 'properties/icon_property.dart';
import 'properties/name_property.dart';

part 'config_spec_registry.g.dart';

@Riverpod(keepAlive: true)
List<ConfigSpecDefinition> configSpecDefinitions(Ref ref) => [
  nameConfigSpec,
  iconConfigSpec,
];

@Riverpod(keepAlive: true)
List<ConfigSpecDescriptor> configSpecDescriptors(Ref ref) {
  final definitions = ref.read(configSpecDefinitionsProvider);
  final processorMap = ref.read(processorRegistryProvider);
  final transformerMap = ref.read(transformerRegistryProvider);
  final aggregatorMap = ref.read(aggregatorRegistryProvider);
  return definitions.map((definition) {
    switch (definition) {
      case SingleStaticConfigSpecDefinition(
        :final processSpecs,
        :final defaultProcessor,
      ):
        return SingleStaticConfigSpecDescriptor(
          id: definition.id,
          processorMap: {
            for (final id in processSpecs.keys) id: processorMap[id]!,
          },
          processorSpecs: processSpecs,
          createDefault: () => PropertyConfigBody.singleStatic(
            processor: ProcessorComponent(
              component: processorMap[defaultProcessor]!,
              raw: processSpecs[defaultProcessor]!.createDefault(),
            ),
          ),
        );
      case SingleRefConfigSpecDefinition(
        :final transformerSpecs,
        :final defaultTransformer,
      ):
        return SingleRefConfigSpecDescriptor(
          id: definition.id,
          propertyIds: definition.propertyIds,
          transformerMap: {
            for (final id in transformerSpecs.keys) id: transformerMap[id]!,
          },
          transformerSpecs: transformerSpecs,
          createDefault: () => PropertyConfigBody.singleRef(
            transformer: TransformerComponent(
              component: transformerMap[defaultTransformer]!,
              raw: transformerSpecs[defaultTransformer]!.createDefault(),
            ),
          ),
        );
      case MultiStaticConfigSpecDefinition(
        :final processorSpecs,
        :final aggregatorSpecs,
        :final defaultAggregator,
      ):
        return MultiStaticConfigSpecDescriptor(
          id: definition.id,
          processorMap: {
            for (final id in processorSpecs.keys) id: processorMap[id]!,
          },
          aggregatorMap: {
            for (final id in aggregatorSpecs.keys) id: aggregatorMap[id]!,
          },
          processorSpecs: processorSpecs,
          aggregatorSpecs: aggregatorSpecs,
          createDefault: () => PropertyConfigBody.multiStatic(
            aggregator: AggregateComponent(
              component: aggregatorMap[defaultAggregator]!,
              raw: aggregatorSpecs[defaultAggregator]!.createDefault(),
            ),
            processorMap: {},
          ),
        );
      case MultiRefConfigSpecDefinition(
        :final transformerSpecs,
        :final aggregatorSpecs,
        :final defaultAggregator,
      ):
        return MultiRefConfigSpecDescriptor(
          id: definition.id,
          transformerMap: {
            for (final id in transformerSpecs.keys) id: transformerMap[id]!,
          },
          aggregatorMap: {
            for (final id in aggregatorSpecs.keys) id: aggregatorMap[id]!,
          },
          propertyIds: definition.propertyIds,
          transformerSpecs: transformerSpecs,
          aggregatorSpecs: aggregatorSpecs,
          createDefault: () => PropertyConfigBody.multiRef(
            aggregator: AggregateComponent(
              component: aggregatorMap[defaultAggregator]!,
              raw: aggregatorSpecs[defaultAggregator]!.createDefault(),
            ),
            transformerMap: {},
          ),
        );
      case HybridConfigSpecDefinition(
        :final transformerSpecs,
        :final aggregatorSpecs,
        :final processorSpecs,
        :final defaultAggregator,
      ):
        return HybridConfigSpecDescriptor(
          id: definition.id,
          transformerMap: {
            for (final id in transformerSpecs.keys) id: transformerMap[id]!,
          },
          aggregatorMap: {
            for (final id in aggregatorSpecs.keys) id: aggregatorMap[id]!,
          },
          propertyIds: definition.propertyIds,
          processorMap: {
            for (final id in processorSpecs.keys) id: processorMap[id]!,
          },
          processorSpecs: processorSpecs,
          transformerSpecs: transformerSpecs,
          aggregatorSpecs: aggregatorSpecs,
          createDefault: () => PropertyConfigBody.hybrid(
            aggregator: AggregateComponent(
              component: aggregatorMap[defaultAggregator]!,
              raw: aggregatorSpecs[defaultAggregator]!.createDefault(),
            ),
            transformerMap: {},
            processorMap: {},
          ),
        );
    }
  }).toList();
}

@Riverpod(keepAlive: true)
Map<String, ConfigSpecDescriptor> configSpecDescriptorRegistry(Ref ref) {
  final configSpecs = ref.read(configSpecDescriptorsProvider);
  return {for (final spec in configSpecs) spec.id: spec};
}

@riverpod
ConfigSpecDescriptor? configSpecDescriptor(Ref ref, String id) {
  final configSpecRegistry = ref.read(configSpecDescriptorRegistryProvider);
  return configSpecRegistry[id];
}
