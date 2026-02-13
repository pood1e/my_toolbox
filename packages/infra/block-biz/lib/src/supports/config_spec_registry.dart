import 'package:app_core/di.dart';
import 'package:flutter/material.dart';
import 'package:nanoid/nanoid.dart';

import '../domain/config_spec.dart';
import '../domain/property_config.dart';
import 'component_registry.dart';
import 'value_types/role_rule_data_type.dart';

part 'config_spec_registry.g.dart';

@Riverpod(keepAlive: true)
List<ConfigSpecDefinition> configSpecDefinitions(Ref ref) => [
  ConfigSpecDefinition.singleStatic(
    id: 'simple_text_config',
    processSpecs: {'simple_text': ComponentSpec(createDefault: () => '')},
  ),
  ConfigSpecDefinition.singleStatic(
    id: 'paragraph_text_config',
    processSpecs: {'simple_text': ComponentSpec(createDefault: () => '')},
  ),
  ConfigSpecDefinition.singleStatic(
    id: 'icon_config',
    processSpecs: {
      'simple_icon': ComponentSpec(createDefault: () => Icons.question_mark),
    },
  ),
  ConfigSpecDefinition.singleRef(
    id: 'icon_ref_config',
    propertyIds: {'_icon'},
    transformerSpecs: {'icon_direct': ComponentSpec(createDefault: () => null)},
  ),
  ConfigSpecDefinition.multiStatic(
    id: 'role_rule_config',
    processorSpecs: {
      'role_rule': ComponentSpec(
        createDefault: () =>
            const RoleRule(propertyId: '_name', type: RoleRuleType.blueprint),
      ),
    },
    aggregatorSpecs: {
      'agg_role_rules': ComponentSpec(createDefault: () => null),
    },
    defaultProcessor: 'role_rule',
    defaultAggregator: 'agg_role_rules',
  ),
];

@Riverpod(keepAlive: true)
List<ConfigSpecDescriptor> configSpecDescriptors(Ref ref) {
  final definitions = ref.read(configSpecDefinitionsProvider);
  final processorMap = ref.read(processorRegistryProvider);
  final transformerMap = ref.read(transformerRegistryProvider);
  final aggregatorMap = ref.read(aggregatorRegistryProvider);
  return definitions.map((definition) {
    switch (definition) {
      case SingleStaticConfigSpecDefinition(:final processSpecs):
        final defaultProcessor = processSpecs.keys.first;
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
      case SingleRefConfigSpecDefinition(:final transformerSpecs):
        return SingleRefConfigSpecDescriptor(
          id: definition.id,
          propertyIds: definition.propertyIds,
          transformerMap: {
            for (final id in transformerSpecs.keys) id: transformerMap[id]!,
          },
          transformerSpecs: transformerSpecs,
        );
      case MultiStaticConfigSpecDefinition(
        :final processorSpecs,
        :final aggregatorSpecs,
        :final defaultProcessor,
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
          defaultProcessor: defaultProcessor,
          createDefault: () => PropertyConfigBody.multiStatic(
            aggregator: AggregateComponent(
              component: aggregatorMap[defaultAggregator]!,
              raw: aggregatorSpecs[defaultAggregator]!.createDefault(),
            ),
            processorMap: {
              nanoid(10): ProcessorComponent(
                component: processorMap[defaultProcessor]!,
                raw: processorSpecs[defaultProcessor]!.createDefault(),
              ),
            },
          ),
        );
      case MultiRefConfigSpecDefinition(
        :final transformerSpecs,
        :final aggregatorSpecs,
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
        );
      case HybridConfigSpecDefinition(
        :final transformerSpecs,
        :final aggregatorSpecs,
        :final processorSpecs,
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
