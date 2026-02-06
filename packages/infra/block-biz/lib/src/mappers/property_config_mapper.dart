import '../data/node_database.dart';
import '../domain/property.dart';
import '../domain/property_config.dart';
import '../domain/stored_config.dart';
import '../repository/property_config_repository.dart';

extension PropertyConfigEntityToDomain on List<PropertyAtomConfigEntity> {
  List<StoredConfig> toRecords() {
    return map((r) => r.toStoredConfig()).toList();
  }

  PropertyConfig toDomain(PropertyKey key) {
    return PropertyConfig(key: key, configs: toRecords());
  }
}

extension PropertyAtomConfigEntityToStoredConfig on PropertyAtomConfigEntity {
  StoredConfig toStoredConfig() {
    return StoredConfig(
      configKey: configKey,
      mapKey: mapKey,
      targetNodeId: targetNodeId,
      targetDefId: targetDefId,
      config: config,
      affectValue: affectValue,
    );
  }
}

extension PropertyConfigDiff on PropertyConfig {
  /// 对比旧记录，计算变更集
  List<ParticalConfigChange> diff(List<StoredConfig> oldConfigs) {
    final changes = <ParticalConfigChange>[];

    // 建立索引: (configKey, mapKey) -> Record
    final oldMap = {for (final r in oldConfigs) (r.configKey, r.mapKey): r};
    final newMap = {for (final r in configs) (r.configKey, r.mapKey): r};

    // 1. Insert & Update
    for (final entry in newMap.entries) {
      final id = entry.key;
      final newRecord = entry.value;
      final oldRecord = oldMap[id];

      final partialKey = ParticialUpdateConfigKey(
        nodeId: key.nodeId,
        refId: key.defId,
        configKey: id.$1,
        mapKey: id.$2,
      );

      final partialRecord = ParticalUpdateConfigRecord(
        targetNodeId: newRecord.targetNodeId,
        targetDefId: newRecord.targetDefId,
        config: newRecord.config,
        affectValue: newRecord.affectValue,
      );

      if (oldRecord == null) {
        changes.add(ParticalConfigChange.insert(partialKey, partialRecord));
      } else if (newRecord != oldRecord) {
        changes.add(ParticalConfigChange.update(partialKey, partialRecord));
      }
    }

    // 2. Delete
    for (final entry in oldMap.entries) {
      if (!newMap.containsKey(entry.key)) {
        changes.add(
          ParticalConfigChange.delete(
            ParticialUpdateConfigKey(
              nodeId: key.nodeId,
              refId: key.defId,
              configKey: entry.key.$1,
              mapKey: entry.key.$2,
            ),
          ),
        );
      }
    }
    return changes;
  }
}

/// 3. 业务逻辑: 判断是否脏 (Affect Value Logic)
extension PariticalConfigDirtyCheck on ParticalConfigChange {
  /// 根据数据库中的旧 affectValue 判断是否产生影响
  /// [oldAffectValue]:
  /// - Insert 时传 null
  /// - Update/Delete 时传 DB 中的旧值
  bool isDirty(bool? oldAffectValue) {
    return map(
      insert: (c) {
        // Insert: 只有新值为 true 时影响
        // old(null) -> new(true) : Dirty
        // old(null) -> new(false): Clean
        return c.record.affectValue;
      },
      update: (c) {
        // Update: 只要有一方为 true，就可能涉及值的改变或状态切换
        // old(true)  -> new(true)  : Dirty (值可能变)
        // old(false) -> new(true)  : Dirty (激活)
        // old(true)  -> new(false) : Dirty (失活)
        // old(false) -> new(false) : Clean
        final newAffect = c.record.affectValue;
        return (oldAffectValue == true) || newAffect;
      },
      delete: (c) {
        // Delete: 只有旧值为 true 时影响
        // old(true)  -> delete : Dirty
        // old(false) -> delete : Clean
        return oldAffectValue == true;
      },
    );
  }
}
