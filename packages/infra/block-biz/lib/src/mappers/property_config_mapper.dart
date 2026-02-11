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
  ) {
    // 1. 查找工具：根据类型和mapKey在数据库结果中查找
    StoredConfig? find(ConfigType type, [String? key]) {
      for (final c in configs) {
        if (c.configType == type && c.mapKey == key) return c;
      }
      return null;
    }

    // 2. 核心解析工具：解包 JSON -> 提取 raw -> 恢复对象
    // C 是配置对象的类型 (如 ProcessorConfig)
    dynamic decodeRaw(Configurable component, StoredConfig? row) {
      if (row?.config == null) return null;
      try {
        final wrapper = jsonDecode(row!.config);

        // 校验数据格式是否为 Map (新的包装格式)
        if (wrapper is! Map<String, dynamic>) return null;

        // 可选：校验 componentId 是否匹配，防止配置错乱
        // if (wrapper['componentId'] != (component as dynamic).id) return null;

        final rawData = wrapper['raw'];

        // 注意：Configurable.fromDb 签名通常接收 Map<String, dynamic>
        // 如果 rawData 是 Map，需要强转一下类型适配 dart 的类型系统
        if (rawData is Map) {
          return component.fromDb(Map<String, dynamic>.from(rawData));
        }
        // 如果 raw 是基本类型 (int/bool等)，根据 Configurable 定义调整
        // 这里假设 fromDb 接受 dynamic 或 map
        return component.fromDb(rawData);
      } catch (e) {
        // 解析失败或数据损坏，返回 null 此时界面通常显示默认值
        return null;
      }
    }

    // 3. 引用目标工具
    PropertyKey? target(StoredConfig? c) =>
        (c?.targetNodeId != null && c?.targetDefId != null)
        ? PropertyKey(nodeId: c!.targetNodeId!, defId: c.targetDefId!)
        : null;

    // 4. 批量构建工具 (Multi/Hybrid 模式用)
    Map<String, ProcessorComponent> makeProcs(Map<String, Processor> map) =>
        map.map(
          (k, v) => MapEntry(
            k,
            ProcessorComponent(
              component: v,
              raw: decodeRaw(v, find(ConfigType.processor, k)),
            ),
          ),
        );

    Map<String, TransformerComponent> makeTrans(Map<String, Transformer> map) =>
        map.map((k, v) {
          final row = find(ConfigType.ref, k);
          return MapEntry(
            k,
            TransformerComponent(
              component: v,
              target: target(row),
              raw: decodeRaw(v, row),
            ),
          );
        });

    AggregateComponent makeAgg(Map<String, Aggregator> map) {
      final agg = map.values.first; // 默认取第一个聚合器
      return AggregateComponent(
        component: agg,
        raw: decodeRaw(agg, find(ConfigType.aggregate)),
      );
    }

    // === 5. 模式匹配构建 ===
    return switch (descriptor) {
      SingleStaticConfigSpecDescriptor d => PropertyConfigBody.singleStatic(
        processor: ProcessorComponent(
          component: d.processorMap.values.first,
          raw: decodeRaw(
            d.processorMap.values.first,
            find(ConfigType.processor),
          ),
        ),
      ),

      SingleRefConfigSpecDescriptor d => () {
        final trans = d.transformerMap.values.first;
        final row = find(ConfigType.ref);
        return PropertyConfigBody.singleRef(
          transformer: TransformerComponent(
            component: trans,
            target: target(row),
            raw: decodeRaw(trans, row),
          ),
        );
      }(),

      MultiStaticConfigSpecDescriptor d => PropertyConfigBody.multiStatic(
        aggregator: makeAgg(d.aggregatorMap),
        processorMap: makeProcs(d.processorMap),
      ),

      MultiRefConfigSpecDescriptor d => PropertyConfigBody.multiRef(
        aggregator: makeAgg(d.aggregatorMap),
        transformerMap: makeTrans(d.transformerMap),
      ),

      HybridConfigSpecDescriptor d => PropertyConfigBody.hybrid(
        aggregator: makeAgg(d.aggregatorMap),
        processorMap: makeProcs(d.processorMap),
        transformerMap: makeTrans(d.transformerMap),
      ),
    };
  }
}
