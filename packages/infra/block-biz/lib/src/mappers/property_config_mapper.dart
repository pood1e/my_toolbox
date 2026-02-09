import 'dart:convert';

import '../data/node_database.dart';
import '../domain/property.dart';
import '../domain/property_config.dart';
import '../domain/stored_config.dart';
import '../repository/property_config_repository.dart';

extension PropertyConfigEntityMapper on PropertyAtomConfigEntity {
  /// DB Entity -> Domain StoredConfig
  StoredConfig toStoredConfig() => StoredConfig(
    configKey: ConfigKey.values.byName(configKey!),
    mapKey: mapKey,
    targetNodeId: targetNodeId,
    targetDefId: targetDefId,
    config: config ?? '',
    affectValue: affectValue,
  );
}

extension PropertyConfigFlattening on PropertyConfig {
  /// 将多态的 Config 转换为扁平的存储记录列表
  /// 这是 Full Update 的核心：Domain -> DB Records
  List<StoredConfig> toStoredConfigs() {
    final records = <StoredConfig>[];

    // 1. 总是记录 Mode
    records.add(
      StoredConfig(
        configKey: ConfigKey.mode,
        config: map(
          singleStatic: (_) => SourceMode.singleStatic.name,
          singleRef: (_) => SourceMode.singleRef.name,
          multiStatic: (_) => SourceMode.multiStatic.name,
          multiRef: (_) => SourceMode.multiRef.name,
          hybrid: (_) => SourceMode.hybrid.name,
        ),
      ),
    );

    // 2. 根据模式生成具体记录
    map(
      singleStatic: (c) {
        records.add(
          StoredConfig(
            configKey: ConfigKey.source,
            // 假设 StaticSourceConfig 有 toJson()
            config: jsonEncode(c.source.toJson()),
            affectValue: true,
          ),
        );
      },
      singleRef: (c) {
        records.add(
          StoredConfig(
            configKey: ConfigKey.source,
            targetNodeId: c.target?.nodeId,
            targetDefId: c.target?.defId,
            // 假设 TransformerConfig 有 toJson()
            config: jsonEncode(c.transformer.toJson()),
            affectValue: true,
          ),
        );
      },
      multiStatic: (c) {
        records.add(
          StoredConfig(
            configKey: ConfigKey.aggregate,
            config: jsonEncode(c.aggregator.toJson()),
          ),
        );
        c.sources.forEach((mapKey, source) {
          records.add(
            StoredConfig(
              configKey: ConfigKey.source,
              mapKey: mapKey,
              config: jsonEncode(source.toJson()),
            ),
          );
        });
      },
      multiRef: (c) {
        records.add(
          StoredConfig(
            configKey: ConfigKey.aggregate,
            config: jsonEncode(c.aggregator.toJson()),
          ),
        );
        c.sources.forEach((mapKey, val) {
          records.add(
            StoredConfig(
              configKey: ConfigKey.source,
              mapKey: mapKey,
              targetNodeId: val.target?.nodeId,
              targetDefId: val.target?.defId,
              config: jsonEncode(val.transformer.toJson()),
            ),
          );
        });
      },
      hybrid: (c) {
        // Hybrid 实现逻辑类似...
        records.add(
          StoredConfig(
            configKey: ConfigKey.aggregate,
            config: jsonEncode(c.aggregator.toJson()),
          ),
        );
        // ... 添加 staticSources 和 refSources
      },
    );

    return records;
  }
}

extension ConfigListDiff on List<StoredConfig> {
  /// 计算变更集
  /// [key]: 当前属性的 Key (用于构建 PartitionKey)
  /// [other]: 新的配置列表 (New State)
  /// 返回: 需要执行的 Insert/Update/Delete 操作列表
  List<ParticalConfigChange> diffTo(
    PropertyKey key,
    List<StoredConfig> newConfigs,
  ) {
    final changes = <ParticalConfigChange>[];

    // 建立索引: (configKey, mapKey) -> Record
    //以此作为唯一标识
    String id(StoredConfig c) => '${c.configKey.name}#${c.mapKey ?? ""}';

    final oldMap = {for (final r in this) id(r): r};
    final newMap = {for (final r in newConfigs) id(r): r};

    // 1. 找出 Insert 和 Update
    for (final entry in newMap.entries) {
      final configId = entry.key;
      final newRec = entry.value;
      final oldRec = oldMap[configId];

      final updateKey = ParticialUpdateConfigKey(
        nodeId: key.nodeId,
        refId: key.defId,
        configKey: newRec.configKey.name, // 枚举转字符串
        mapKey: newRec.mapKey,
      );

      final updateRecord = ParticalUpdateConfigRecord(
        targetNodeId: newRec.targetNodeId,
        targetDefId: newRec.targetDefId,
        config: newRec.config,
        affectValue: newRec.affectValue,
      );

      if (oldRec == null) {
        // 新增
        changes.add(ParticalConfigChange.insert(updateKey, updateRecord));
      } else if (oldRec != newRec) {
        // 变更 (利用 Freezed 的 == 重载进行深度比较)
        changes.add(ParticalConfigChange.update(updateKey, updateRecord));
      }
    }

    // 2. 找出 Delete
    for (final entry in oldMap.entries) {
      if (!newMap.containsKey(entry.key)) {
        final oldRec = entry.value;
        changes.add(
          ParticalConfigChange.delete(
            ParticialUpdateConfigKey(
              nodeId: key.nodeId,
              refId: key.defId,
              configKey: oldRec.configKey.name,
              mapKey: oldRec.mapKey,
            ),
          ),
        );
      }
    }

    return changes;
  }
}
