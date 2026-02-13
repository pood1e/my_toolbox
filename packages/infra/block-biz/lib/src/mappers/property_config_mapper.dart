import 'dart:convert';

import '../data/node_database.dart';
import '../domain/compute_engine.dart';
import '../domain/config_spec.dart';
import '../domain/property.dart';
import '../domain/property_config.dart';
import '../domain/stored_config.dart';
import '../repository/property_config_repository.dart';

extension PropertyConfigEntityMapper on PropertyAtomConfigEntity {
  /// DB Entity -> Domain StoredConfig
  StoredConfig toStoredConfig() => StoredConfig(
    configType: configType,
    mapKey: mapKey,
    targetNodeId: targetNodeId,
    targetDefId: targetDefId,
    config: config ?? '',
    affectValue: affectValue,
  );
}

extension PropertyConfigEntitysMapper on List<PropertyAtomConfigEntity> {
  List<StoredConfig> toStoredList() =>
      map((entity) => entity.toStoredConfig()).toList();
}

extension PropertyConfigFlattening on PropertyConfig {
  /// 将多态的 Config 转换为扁平的存储记录列表
  /// 这是 Full Update 的核心：Domain -> DB Records
  List<StoredConfig> toStoredConfigs() {
    final records = <StoredConfig>[];
    // 1. 总是记录 spec
    records.add(StoredConfig(configType: ConfigType.spec, config: spec));

    body.map(
      singleStatic: (c) {
        records.add(
          StoredConfig(
            configType: ConfigType.processor,
            config: c.processor.toJsonString(),
            affectValue: true,
          ),
        );
      },
      singleRef: (c) {
        records.add(
          StoredConfig(
            configType: ConfigType.ref,
            targetNodeId: c.transformer.target?.nodeId,
            targetDefId: c.transformer.target?.defId,
            config: c.transformer.toJsonString(),
            affectValue: true,
          ),
        );
      },
      multiStatic: (c) {
        // Aggregate
        records.add(
          StoredConfig(
            configType: ConfigType.aggregate,
            config: c.aggregator.toJsonString(),
            affectValue: true,
          ),
        );
        // Processors
        c.processorMap.forEach((mapKey, comp) {
          records.add(
            StoredConfig(
              configType: ConfigType.processor,
              mapKey: mapKey,
              config: comp.toJsonString(),
              affectValue: true,
            ),
          );
        });
      },
      multiRef: (c) {
        // Aggregate
        records.add(
          StoredConfig(
            configType: ConfigType.aggregate,
            config: c.aggregator.toJsonString(),
            affectValue: true,
          ),
        );
        // Refs
        c.transformerMap.forEach((mapKey, comp) {
          records.add(
            StoredConfig(
              configType: ConfigType.ref,
              mapKey: mapKey,
              targetNodeId: comp.target?.nodeId,
              targetDefId: comp.target?.defId,
              config: comp.toJsonString(),
              affectValue: true,
            ),
          );
        });
      },
      hybrid: (c) {
        // Aggregate
        records.add(
          StoredConfig(
            configType: ConfigType.aggregate,
            config: c.aggregator.toJsonString(),
            affectValue: true,
          ),
        );
        // Processors
        c.processorMap.forEach((mapKey, comp) {
          records.add(
            StoredConfig(
              configType: ConfigType.processor,
              mapKey: mapKey,
              config: comp.toJsonString(),
              affectValue: true,
            ),
          );
        });
        // Refs
        c.transformerMap.forEach((mapKey, comp) {
          records.add(
            StoredConfig(
              configType: ConfigType.ref,
              mapKey: mapKey,
              targetNodeId: comp.target?.nodeId,
              targetDefId: comp.target?.defId,
              config: comp.toJsonString(),
              affectValue: true,
            ),
          );
        });
      },
    );

    return records;
  }
}

extension ConfigListDiff on List<StoredConfig> {
  /// Calculate changeset
  List<ParticalConfigChange> diffTo(
    PropertyKey key,
    List<StoredConfig> newConfigs,
  ) {
    final changes = <ParticalConfigChange>[];

    // Unique ID: ConfigType + MapKey (if exists)
    String id(StoredConfig c) => '${c.configType.name}#${c.mapKey ?? ""}';

    final oldMap = {for (final r in this) id(r): r};
    final newMap = {for (final r in newConfigs) id(r): r};

    // 1. Find Insert and Update
    for (final entry in newMap.entries) {
      final configId = entry.key;
      final newRec = entry.value;
      final oldRec = oldMap[configId];

      final updateKey = ParticialUpdateConfigKey(
        nodeId: key.nodeId,
        refId: key.defId,
        configType: newRec.configType,
        mapKey: newRec.mapKey,
      );

      final updateRecord = ParticalUpdateConfigRecord(
        targetNodeId: newRec.targetNodeId,
        targetDefId: newRec.targetDefId,
        config: newRec.config,
        affectValue: newRec.affectValue,
      );

      if (oldRec == null) {
        changes.add(ParticalConfigChange.insert(updateKey, updateRecord));
      } else if (oldRec != newRec) {
        changes.add(ParticalConfigChange.update(updateKey, updateRecord));
      }
    }

    // 2. Find Delete
    for (final entry in oldMap.entries) {
      if (!newMap.containsKey(entry.key)) {
        final oldRec = entry.value;
        changes.add(
          ParticalConfigChange.delete(
            ParticialUpdateConfigKey(
              nodeId: key.nodeId,
              refId: key.defId,
              configType: oldRec.configType,
              mapKey: oldRec.mapKey,
            ),
          ),
        );
      }
    }

    return changes;
  }
}

extension PropertyConfigParser on PropertyConfig {
  static PropertyConfig parse(
    PropertyKey key,
    List<StoredConfig> configs,
    Map<String, ConfigSpecDescriptor> descriptorMap,
  ) {
    final String spec = parseSpec(configs);
    return PropertyConfig(
      key: key,
      spec: spec,
      body: PropertyConfigParser.parseBody(configs, descriptorMap[spec]!),
    );
  }

  static String parseSpec(List<StoredConfig> configs) =>
      configs.firstWhere((c) => c.configType == ConfigType.spec).config;

  static PropertyConfigBody parseBody(
    List<StoredConfig> configs,
    ConfigSpecDescriptor descriptor,
  ) => descriptor.map(
    singleStatic: (desc) => _parseSingleStatic(configs, desc),
    singleRef: (desc) => _parseSingleRef(configs, desc),
    multiStatic: (desc) => _parseMultiStatic(configs, desc),
    multiRef: (desc) => _parseMultiRef(configs, desc),
    hybrid: (desc) => _parseHybrid(configs, desc),
  );

  // --- 1. Single Static (Processor) ---
  static PropertyConfigBody _parseSingleStatic(
    List<StoredConfig> configs,
    SingleStaticConfigSpecDescriptor desc,
  ) {
    // 查找类型为 processor 的配置
    final config = configs.firstWhere(
      (c) => c.configType == ConfigType.processor,
      orElse: () => throw Exception('Missing processor config for ${desc.id}'),
    );

    return PropertyConfigBody.singleStatic(
      processor: _parseProcessor(config, desc.processorMap),
    );
  }

  // --- 2. Single Ref (Transformer) ---
  static PropertyConfigBody _parseSingleRef(
    List<StoredConfig> configs,
    SingleRefConfigSpecDescriptor desc,
  ) {
    final config = configs.firstWhere(
      (c) => c.configType == ConfigType.ref,
      orElse: () => throw Exception('Missing ref config for ${desc.id}'),
    );

    return PropertyConfigBody.singleRef(
      transformer: _parseTransformer(config, desc.transformerMap),
    );
  }

  // --- 3. Multi Static (Aggregator + Map<String, Processor>) ---
  static PropertyConfigBody _parseMultiStatic(
    List<StoredConfig> configs,
    MultiStaticConfigSpecDescriptor desc,
  ) {
    // 1. 解析聚合器
    final aggConfig = configs.firstWhere(
      (c) => c.configType == ConfigType.aggregate,
      orElse: () => throw Exception('Missing aggregator config for ${desc.id}'),
    );
    final aggregator = _parseAggregator(aggConfig, desc.aggregatorMap);

    // 2. 解析 Processor Map
    final processorMap = <String, ProcessorComponent>{};
    for (final config in configs.where(
      (c) => c.configType == ConfigType.processor,
    )) {
      if (config.mapKey != null) {
        processorMap[config.mapKey!] = _parseProcessor(
          config,
          desc.processorMap,
        );
      }
    }

    return PropertyConfigBody.multiStatic(
      aggregator: aggregator,
      processorMap: processorMap,
    );
  }

  // --- 4. Multi Ref (Aggregator + Map<String, Transformer>) ---
  static PropertyConfigBody _parseMultiRef(
    List<StoredConfig> configs,
    MultiRefConfigSpecDescriptor desc,
  ) {
    final aggConfig = configs.firstWhere(
      (c) => c.configType == ConfigType.aggregate,
      orElse: () => throw Exception('Missing aggregator config for ${desc.id}'),
    );
    final aggregator = _parseAggregator(aggConfig, desc.aggregatorMap);

    final transformerMap = <String, TransformerComponent>{};
    for (final config in configs.where((c) => c.configType == ConfigType.ref)) {
      if (config.mapKey != null) {
        transformerMap[config.mapKey!] = _parseTransformer(
          config,
          desc.transformerMap,
        );
      }
    }

    return PropertyConfigBody.multiRef(
      aggregator: aggregator,
      transformerMap: transformerMap,
    );
  }

  // --- 5. Hybrid (Aggregator + Processor Map + Transformer Map) ---
  static PropertyConfigBody _parseHybrid(
    List<StoredConfig> configs,
    HybridConfigSpecDescriptor desc,
  ) {
    final aggConfig = configs.firstWhere(
      (c) => c.configType == ConfigType.aggregate,
      orElse: () => throw Exception('Missing aggregator config for ${desc.id}'),
    );
    final aggregator = _parseAggregator(aggConfig, desc.aggregatorMap);

    final processorMap = <String, ProcessorComponent>{};
    final transformerMap = <String, TransformerComponent>{};

    for (final config in configs) {
      if (config.mapKey == null) continue;

      if (config.configType == ConfigType.processor) {
        processorMap[config.mapKey!] = _parseProcessor(
          config,
          desc.processorMap,
        );
      } else if (config.configType == ConfigType.ref) {
        transformerMap[config.mapKey!] = _parseTransformer(
          config,
          desc.transformerMap,
        );
      }
    }

    return PropertyConfigBody.hybrid(
      aggregator: aggregator,
      processorMap: processorMap,
      transformerMap: transformerMap,
    );
  }

  // -------------------------------------------------------------------------
  // Helpers: 解析具体组件
  // -------------------------------------------------------------------------

  static ProcessorComponent _parseProcessor(
    StoredConfig config,
    Map<String, Processor> lookupMap,
  ) {
    final json = jsonDecode(config.config) as Map<String, dynamic>;
    final componentId = json['componentId'] as String;
    final rawJson = json['raw'];

    final component = lookupMap[componentId];
    if (component == null) {
      throw Exception('Processor "$componentId" not found in descriptor.');
    }
    // 假设 component.fromDb 存在，用于将 JSON 数据转回 Dart 对象
    // 如果没有 fromDb，且 raw 就是需要的对象，则直接使用 rawJson
    final rawData = component.fromDb(rawJson);

    return ProcessorComponent(component: component, raw: rawData);
  }

  static TransformerComponent _parseTransformer(
    StoredConfig config,
    Map<String, Transformer> lookupMap,
  ) {
    final json = jsonDecode(config.config) as Map<String, dynamic>;
    final componentId = json['componentId'] as String;
    final rawJson = json['raw'];

    final component = lookupMap[componentId];
    if (component == null) {
      throw Exception('Transformer "$componentId" not found in descriptor.');
    }

    final rawData = component.fromDb(rawJson);

    // 构建引用目标 Key
    PropertyKey? target;
    if (config.targetNodeId != null && config.targetDefId != null) {
      target = PropertyKey(
        nodeId: config.targetNodeId!,
        defId: config.targetDefId!, // 注意：PropertyKey 的参数名根据你的定义可能不同，这里假设是 id
      );
    }

    return TransformerComponent(
      component: component,
      target: target,
      raw: rawData,
    );
  }

  static AggregateComponent _parseAggregator(
    StoredConfig config,
    Map<String, Aggregator> lookupMap,
  ) {
    final json = jsonDecode(config.config) as Map<String, dynamic>;
    final componentId = json['componentId'] as String;
    final rawJson = json['raw'];

    final component = lookupMap[componentId];
    if (component == null) {
      throw Exception('Aggregator "$componentId" not found in descriptor.');
    }

    final rawData = component.fromDb(rawJson);

    return AggregateComponent(component: component, raw: rawData);
  }
}
